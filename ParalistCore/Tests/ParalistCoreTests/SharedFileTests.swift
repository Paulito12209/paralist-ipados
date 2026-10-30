// Zusammenhang: Links/SharedFile.swift, Links/FileKind.swift, Library/ComposerDraft.swift, Library/EntryLibrary.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct SharedFileTests {
    private let t0 = at("2026-10-18T10:00:00Z")
    private let hash = String(repeating: "b", count: 64)

    private func media(_ id: String, _ mime: String, age: Double = 0) -> Entry {
        Entry(id, .file, id, t0, t0.addingTimeInterval(-age)) { $0.attachment = Attachment(hash: String(repeating: "c", count: 64), name: "x", mime: mime, size: 1) }
    }

    @Test func kindFollowsMime() {
        #expect(MediaKind.of(mime: "image/jpeg") == .image)
        #expect(MediaKind.of(mime: "VIDEO/mp4") == .video)
        #expect(MediaKind.of(mime: "audio/mp4") == .audio)
        #expect(MediaKind.of(mime: "application/pdf") == .document)
        #expect(MediaKind.of(mime: "text/plain") == .document)
        #expect(MediaKind.image.entryType == .file)
        #expect(MediaKind.video.entryType == .file)
        #expect(MediaKind.audio.entryType == .file)
        #expect(MediaKind.document.entryType == .document)
    }

    @Test func kindOfEntry() {
        #expect(MediaKind.of(media("a", "image/png")) == .image)
        #expect(MediaKind.of(Entry("d", .document, "d", t0, t0)) == .document)
        #expect(MediaKind.of(Entry("n", .note, "n", t0, t0)) == nil)
        #expect(MediaKind.of(Entry("b", .bookmark, "b", t0, t0)) == nil)
    }

    @Test func titleFromFileName() {
        #expect(SharedFile.title("IMG_1234.HEIC") == "IMG_1234")
        #expect(SharedFile.title("Rechnung März.final.pdf") == "Rechnung März.final")
        #expect(SharedFile.title("/tmp/x/Notiz.txt") == "Notiz")
        #expect(SharedFile.title(".hidden") == ".hidden")
        #expect(SharedFile.title("  Bild\u{0}1 .jpg") == "Bild1")
        #expect(SharedFile.title(String(repeating: "a", count: 900) + ".pdf").count == Limits.maxTitleChars)
    }

    @Test func candidatesSkipSameKindAndArchived() {
        let all = [
            media("img", "image/jpeg", age: 10), media("vid", "video/mp4", age: 20), media("aud", "audio/mpeg", age: 30),
            media("pdf", "application/pdf", age: 40), Entry("doc", .document, "doc", t0, t0.addingTimeInterval(-50)),
            Entry("proj", .project, "proj", t0, t0.addingTimeInterval(-5)), Entry("note", .note, "note", t0, t0.addingTimeInterval(-60)),
            Entry("old", .note, "old", t0, t0) { $0.archived = true },
        ]
        #expect(SharedFile.linkCandidates(all, excluding: [.image]).map(\.id) == ["proj", "vid", "aud", "pdf", "doc", "note"])
        #expect(SharedFile.linkCandidates(all, excluding: [.video]).map(\.id) == ["proj", "img", "aud", "pdf", "doc", "note"])
        #expect(SharedFile.linkCandidates(all, excluding: [.audio]).map(\.id) == ["proj", "img", "vid", "pdf", "doc", "note"])
        #expect(SharedFile.linkCandidates(all, excluding: [.document]).map(\.id) == ["proj", "img", "vid", "aud", "note"])
        #expect(SharedFile.linkCandidates(all, excluding: [.image, .document]).map(\.id) == ["proj", "vid", "aud", "note"])
    }

    @Test func candidatesAreSearchable() {
        let all = [
            Entry("a", .project, "Umzug Berlin", t0, t0),
            Entry("b", .note, "Einkauf", t0, t0) { $0.body = "Kisten für den Umzug" },
            Entry("c", .area, "Gesundheit", t0, t0),
        ]
        #expect(Set(SharedFile.linkCandidates(all, excluding: [.image], query: "umz").map(\.id)) == ["a", "b"])
        #expect(SharedFile.linkCandidates(all, excluding: [.image], query: "gesund").map(\.id) == ["c"])
        #expect(SharedFile.linkCandidates(all, excluding: [.image], query: "xyz").isEmpty)
        #expect(SharedFile.linkCandidates(all, excluding: [.image], query: "  ").count == 3)
    }

    @Test func heifIsImageNotVideo() {
        let heic: [UInt8] = [0, 0, 0, 0x18] + Array("ftypheic".utf8) + [0, 0, 0, 0]
        let mif1: [UInt8] = [0, 0, 0, 0x18] + Array("ftypmif1".utf8)
        let mp4: [UInt8] = [0, 0, 0, 0x18] + Array("ftypisom".utf8)
        let mov: [UInt8] = [0, 0, 0, 0x14] + Array("ftypqt  ".utf8)
        #expect(FileKind.isHeif(heic))
        #expect(FileKind.isHeif(mif1))
        #expect(!FileKind.isHeif(mp4))
        #expect(!FileKind.isHeif(Array("ftyp".utf8)))
        #expect(FileKind.detect(heic) == nil)
        #expect(FileKind.detectImport(heic) == .jpeg)
        #expect(FileKind.detectImport(mp4) == .mp4)
        #expect(FileKind.detectImport(mov) == .mp4)
        #expect(FileKind.detectImport(Array("<html>".utf8)) == nil)
        #expect(FileKind.detectImport(Array("%PDF-1.4".utf8)) == .pdf)
    }

    @Test func documentKeepsAttachment() throws {
        let attachment = Attachment(hash: hash, name: "Vertrag.pdf", mime: "application/pdf", size: 2048)
        var draft = ComposerDraft(type: MediaKind.of(mime: attachment.mime).entryType)
        draft.title = SharedFile.title(attachment.name)
        draft.attachment = attachment
        let base = Entry("neu-1", .note, "", t0, t0)
        let result = draft.build(base, zone: berlin)
        let built = try #require(result)
        #expect(built.type == .document)
        #expect(built.attachment == attachment)
        #expect(built.title == "Vertrag")
        var note = ComposerDraft(type: .note)
        note.attachment = attachment
        #expect(note.build(base, zone: berlin)?.attachment == attachment)
    }

    @Test func sharedEntryIsLinkedBothWays() throws {
        let library = EntryLibrary(root: temporaryDirectory(), ids: CountingIds("teilen"), clock: StepClock(t0))
        let project = try library.save(library.newEntry(.project, title: "Reise"))
        let note = try library.save(library.newEntry(.note, title: "Packliste"))
        var draft = ComposerDraft(type: .file)
        draft.title = "Strand"
        draft.places = [project.id]
        draft.pinned = true
        draft.attachment = Attachment(hash: hash, name: "Strand.jpg", mime: "image/jpeg", size: 10)
        let built = draft.build(library.newEntry(.file, title: ""), zone: berlin)
        let saved = try library.save(try #require(built))
        library.enforcePinLimit(for: saved, limit: 1)
        for id in [project.id, note.id] { try library.setLinked(saved.id, id, linked: true) }
        library.rebuild()
        let stored = try #require(library.entry(saved.id))
        #expect(stored.links == [project.id, note.id])
        #expect(stored.places == [project.id])
        #expect(stored.pinned)
        #expect(stored.attachment?.mime == "image/jpeg")
        #expect(library.entry(project.id)?.links == [saved.id])
        #expect(library.entry(note.id)?.links == [saved.id])
    }
}
