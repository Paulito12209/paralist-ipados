// Zusammenhang: Capture/CameraPicker.swift, Files/AttachmentImporter.swift
import AVFoundation

enum VideoShrinker {
    static func shrink(_ source: URL) async -> URL? {
        guard let session = AVAssetExportSession(asset: AVURLAsset(url: source), presetName: AVAssetExportPreset960x540) else { return nil }
        let target = FileManager.default.temporaryDirectory.appendingPathComponent("video-\(UUID().uuidString).mp4")
        do {
            try await session.export(to: target, as: .mp4)
            return target
        } catch {
            return nil
        }
    }
}
