// Zusammenhang: App/AppModel.swift, Entry/EntryHero.swift, Entry/EntryPage.swift, Files/AttachmentImporter.swift, ParalistCore Model/Entry.swift
import Foundation
import ParalistCore
import UniformTypeIdentifiers

enum AttachmentPreview {
    static func url(for attachment: Attachment, source: URL) -> URL? {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("preview", isDirectory: true)
            .appendingPathComponent(attachment.hash, isDirectory: true)
        let target = folder.appendingPathComponent(fileName(attachment))
        do {
            if !FileManager.default.fileExists(atPath: target.path) {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: target)
            }
            return target
        } catch {
            return nil
        }
    }

    static func fileName(_ attachment: Attachment) -> String {
        let clean = attachment.name.replacingOccurrences(of: "/", with: "_")
        let base = clean.isEmpty ? attachment.hash : clean
        guard URL(fileURLWithPath: base).pathExtension.isEmpty else { return base }
        let ext = UTType(mimeType: attachment.mime)?.preferredFilenameExtension ?? ""
        return ext.isEmpty ? base : base + "." + ext
    }
}
