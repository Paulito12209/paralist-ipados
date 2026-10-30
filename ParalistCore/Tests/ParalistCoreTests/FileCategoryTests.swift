// Zusammenhang: Model/FileCategory.swift, Links/FileKind.swift, Model/Entry.swift (Attachment)
import Foundation
import Testing
@testable import ParalistCore

struct FileCategoryTests {
    private func category(_ name: String, _ mime: String) -> FileCategory {
        FileCategory.of(Attachment(hash: String(repeating: "a", count: 64), name: name, mime: mime, size: 1))
    }

    @Test func mediaByMime() {
        #expect(category("foto.jpg", "image/jpeg") == .photo)
        #expect(category("clip.mp4", "video/mp4") == .video)
        #expect(category("ton.m4a", "audio/mp4") == .audio)
    }

    @Test func documentsByMimeAndExtension() {
        #expect(category("bericht.pdf", "application/pdf") == .pdf)
        #expect(category("notizen.md", "text/plain") == .markdown)
        #expect(category("NOTIZEN.MARKDOWN", "text/plain") == .markdown)
        #expect(category("liste.txt", "text/plain") == .text)
        #expect(category("daten.bin", "application/octet-stream") == .other)
    }

    @Test func markdownExtensionSurvivesImportNaming() {
        #expect(FileKind.sanitizeName("../Notizen.MD", kind: .text) == "Notizen.md")
        #expect(FileKind.sanitizeName("Liste.docx", kind: .text) == "Liste.txt")
        #expect(FileKind.sanitizeName("Foto.md", kind: .jpeg) == "Foto.jpg")
    }
}
