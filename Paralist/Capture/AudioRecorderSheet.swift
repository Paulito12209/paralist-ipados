// Zusammenhang: Shell/AppSheets.swift, Shell/Router.swift, Capture/CaptureFlow.swift, Files/AttachmentImporter.swift
import AVFoundation
import SwiftUI

@MainActor
final class AudioRecorder {
    private var recorder: AVAudioRecorder?
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")

    var seconds: TimeInterval { recorder?.currentTime ?? 0 }

    func start() async -> Bool {
        guard await AVAudioApplication.requestRecordPermission() else { return false }
        let session = AVAudioSession.sharedInstance()
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 64000,
        ]
        guard (try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])) != nil,
              (try? session.setActive(true)) != nil,
              let made = try? AVAudioRecorder(url: url, settings: settings), made.record() else { return false }
        recorder = made
        return true
    }

    func finish() {
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func discard() {
        finish()
        try? FileManager.default.removeItem(at: url)
    }
}

struct AudioRecorderSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var recorder = AudioRecorder()
    @State private var running = false

    var body: some View {
        VStack(spacing: 20) {
            Text(L.s("record_title")).font(Typo.titleMedium).foregroundStyle(Palette.onSurfaceVariant)
            TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                Text(Self.clock(recorder.seconds))
                    .font(Typo.displaySmall.monospacedDigit())
                    .foregroundStyle(Palette.onSurface)
            }
            HStack(spacing: 28) {
                Button { cancel() } label: {
                    Image(systemName: AppIcons.close).font(.system(size: 20, weight: .medium)).foregroundStyle(Palette.onSurface)
                        .frame(width: 56, height: 56)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel(L.s("dialog_cancel"))
                Button { save() } label: {
                    Image(systemName: AppIcons.stop).font(.system(size: 22)).foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(Palette.error).interactive(), in: Circle())
                .disabled(!running)
                .accessibilityLabel(L.s("composer_save"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .task {
            running = await recorder.start()
            if !running {
                model.say(L.s("capture_mic_denied"))
                router.recording = false
            }
        }
        .onDisappear { if running { recorder.discard() } }
    }

    private func cancel() {
        running = false
        recorder.discard()
        router.recording = false
    }

    private func save() {
        running = false
        recorder.finish()
        let result = AttachmentImporter.importFile(at: recorder.url, into: model.library.store)
        try? FileManager.default.removeItem(at: recorder.url)
        CaptureFlow.save(result, kind: .audio, link: router.createLink, model: model)
        router.recording = false
    }

    private static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
