// Zusammenhang: Composer/DictationSheet.swift, Composer/ComposerDictation.swift, Capture/AudioRecorderSheet.swift, App/L.swift
import AVFoundation
import Foundation
import Observation
import Speech

@MainActor
@Observable
final class SpeechDictation {
    enum Phase: Equatable {
        case idle, preparing, loading(Double), listening
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var settled = ""
    private(set) var pending = ""
    private var analyzer: SpeechAnalyzer?
    private var input: AsyncStream<AnalyzerInput>.Continuation?
    private var reader: Task<Void, Never>?
    private let engine = AVAudioEngine()

    var text: String { [settled, pending].filter { !$0.isEmpty }.joined(separator: " ") }

    static var language: Locale {
        let app = L.locale.language.languageCode
        return Locale.current.language.languageCode == app ? Locale.current : L.locale
    }

    func start() async {
        phase = .preparing
        guard await AVAudioApplication.requestRecordPermission() else { return fail("capture_mic_denied") }
        guard SpeechTranscriber.isAvailable, let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Self.language) else {
            return fail("dictation_unsupported")
        }
        let transcriber = SpeechTranscriber(locale: locale, transcriptionOptions: [], reportingOptions: [.volatileResults], attributeOptions: [])
        do {
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                phase = .loading(0)
                let progress = request.progress
                let watcher = Task { @MainActor [weak self] in
                    while !Task.isCancelled {
                        self?.phase = .loading(progress.fractionCompleted)
                        try? await Task.sleep(for: .milliseconds(250))
                    }
                }
                defer { watcher.cancel() }
                try await request.downloadAndInstall()
            }
            guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else { return fail("dictation_failed") }
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let (stream, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
            input = continuation
            let analyzer = SpeechAnalyzer(modules: [transcriber])
            self.analyzer = analyzer
            reader = Task { [weak self] in
                do {
                    for try await result in transcriber.results {
                        let piece = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
                        guard let self else { return }
                        if result.isFinal {
                            if !piece.isEmpty { self.settled = self.settled.isEmpty ? piece : self.settled + " " + piece }
                            self.pending = ""
                        } else {
                            self.pending = piece
                        }
                    }
                } catch {}
            }
            try await analyzer.start(inputSequence: stream)
            try Self.tap(engine.inputNode, into: format, continuation: continuation)
            engine.prepare()
            try engine.start()
            phase = .listening
        } catch {
            stopAudio()
            fail("dictation_failed")
        }
    }

    func finish() async -> String {
        stopAudio()
        input?.finish()
        input = nil
        if let analyzer { try? await analyzer.finalizeAndFinishThroughEndOfInput() }
        await reader?.value
        analyzer = nil
        reader = nil
        phase = .idle
        return text
    }

    func cancel() {
        stopAudio()
        input?.finish()
        input = nil
        reader?.cancel()
        reader = nil
        if let analyzer { Task { await analyzer.cancelAndFinishNow() } }
        analyzer = nil
        phase = .idle
    }

    private func stopAudio() {
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func fail(_ key: String) { phase = .failed(L.s(key)) }

    nonisolated private static func tap(_ node: AVAudioInputNode, into format: AVAudioFormat, continuation: AsyncStream<AnalyzerInput>.Continuation) throws {
        let natural = node.outputFormat(forBus: 0)
        guard natural.sampleRate > 0 else { throw CocoaError(.featureUnsupported) }
        let converter = BufferConverter(from: natural, to: format)
        node.removeTap(onBus: 0)
        node.installTap(onBus: 0, bufferSize: 4096, format: natural) { buffer, _ in
            if let converted = converter.convert(buffer) { continuation.yield(AnalyzerInput(buffer: converted)) }
        }
    }
}

final class BufferConverter: @unchecked Sendable {
    private let converter: AVAudioConverter?
    private let target: AVAudioFormat

    init(from source: AVAudioFormat, to target: AVAudioFormat) {
        self.target = target
        converter = source == target ? nil : AVAudioConverter(from: source, to: target)
    }

    func convert(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let converter else { return buffer }
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * target.sampleRate / buffer.format.sampleRate) + 1
        guard let out = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return nil }
        var fed = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if fed {
                status.pointee = .noDataNow
                return nil
            }
            fed = true
            status.pointee = .haveData
            return buffer
        }
        return error == nil && out.frameLength > 0 ? out : nil
    }
}
