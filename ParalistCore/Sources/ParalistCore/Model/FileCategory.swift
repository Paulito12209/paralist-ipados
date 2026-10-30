// Zusammenhang: Model/Entry.swift (Attachment), Links/FileKind.swift, Paralist/Entries/TypeLook.swift
import Foundation

public enum FileCategory: Sendable {
    case photo, video, audio, pdf, markdown, text, other

    private static let markdownExtensions = ["md", "markdown"]

    public static func of(_ attachment: Attachment) -> FileCategory {
        let mime = attachment.mime.lowercased()
        if mime.hasPrefix("image/") { return .photo }
        if mime.hasPrefix("video/") { return .video }
        if mime.hasPrefix("audio/") { return .audio }
        if mime == "application/pdf" { return .pdf }
        let ext = URL(fileURLWithPath: attachment.name).pathExtension.lowercased()
        if markdownExtensions.contains(ext) { return .markdown }
        if mime.hasPrefix("text/") { return .text }
        return .other
    }
}
