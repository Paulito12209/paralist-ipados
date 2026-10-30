// Zusammenhang: Sources/ParalistCore/Library/AttachmentEntry.swift, Sources/ParalistCore/Library/ComposerDraft.swift, Sources/ParalistCore/Library/EntryLibrary.swift
import Foundation
import Testing
@testable import ParalistCore

struct AttachmentEntryTests {
    private let photo = Attachment(hash: String(repeating: "b", count: 64), name: "Urlaub.Strand.jpg", mime: "image/jpeg", size: 10)
    private let other = Attachment(hash: String(repeating: "c", count: 64), name: "x.pdf", mime: "application/pdf", size: 10)

    private func task(_ configure: (inout Entry) -> Void = { _ in }) -> Entry {
        Entry("task-1", .task, "Fliesen kaufen", epoch, epoch) {
            $0.attachment = photo
            $0.places = ["area-1"]
            $0.status = .open
            configure(&$0)
        }
    }

    @Test func taskWithAttachmentGetsFileEntryPlacedInIt() {
        let entry = task()
        #expect(AttachmentEntry.plan(photo, for: entry, in: [entry]) == .create)
        let base = Entry("file-1", .note, "", epoch, epoch)
        let file = AttachmentEntry.make(base, photo, for: entry)
        #expect(file.id == "file-1")
        #expect(file.type == .file)
        #expect(file.title == "Urlaub.Strand")
        #expect(file.attachment == photo)
        #expect(file.places == ["task-1"])
        #expect(file.links.isEmpty)
        #expect(file.status == nil)
    }

    @Test func documentGetsFileEntryAndKeepsNoAttachment() {
        var draft = ComposerDraft(type: .document)
        draft.title = "Testdokument mit Anhang"
        draft.attach(photo)
        #expect(draft.type == .document)
        let built = draft.build(Entry("doc-1", .document, "", epoch, epoch), zone: berlin)!
        #expect(built.attachment == photo)
        let doc = AttachmentEntry.owner(built)
        #expect(doc.attachment == nil)
        #expect(AttachmentEntry.owner(task()).attachment == photo)
        #expect(AttachmentEntry.plan(draft.attachment, for: doc, in: [doc]) == .create)
        let file = AttachmentEntry.make(Entry("file-1", .note, "", epoch, epoch), photo, for: doc)
        #expect(file.places == ["doc-1"])
        #expect(AttachmentEntry.keeps(.task))
        #expect(!AttachmentEntry.keeps(.document))
    }

    @Test func fileNeedsNoCompanion() {
        let file = task { $0.type = .file }
        #expect(AttachmentEntry.plan(photo, for: file, in: []) == .none)
        #expect(AttachmentEntry.plan(nil, for: task(), in: []) == .none)
    }

    @Test func existingFileEntryWithSameHashIsLinked() {
        let older = Entry("file-old", .file, "Alt", epoch, epoch) { $0.attachment = photo }
        let newer = Entry("file-new", .file, "Neu", Date(timeIntervalSince1970: 50), epoch) { $0.attachment = photo }
        let archived = Entry("file-arch", .file, "Archiv", Date(timeIntervalSince1970: -50), epoch) {
            $0.attachment = photo
            $0.archived = true
        }
        let unrelated = Entry("file-x", .file, "X", epoch, epoch) { $0.attachment = other }
        let note = Entry("note-1", .note, "Mit Bild", Date(timeIntervalSince1970: -99), epoch) { $0.attachment = photo }
        let doc = Entry("doc-old", .document, "Alt", Date(timeIntervalSince1970: -99), epoch) { $0.attachment = photo }
        let entry = task()
        let all = [entry, newer, archived, unrelated, note, older, doc]
        #expect(AttachmentEntry.plan(photo, for: entry, in: all) == .link("file-old"))
        #expect(AttachmentEntry.existing(photo.hash, in: [archived, note]) == archived)
        #expect(AttachmentEntry.plan(photo, for: task { $0.links = ["file-old"] }, in: all) == .none)
        let placed = older.with { $0.places = ["task-1"] }
        #expect(AttachmentEntry.plan(photo, for: entry, in: [entry, placed]) == .none)
        #expect(AttachmentEntry.plan(photo, for: entry, in: [entry, doc]) == .create)
    }

    @Test func draftKeepsChosenTypeWhenAttaching() {
        var draft = ComposerDraft(type: .task)
        draft.title = "Fliesen kaufen"
        draft.attach(photo)
        #expect(draft.type == .task)
        #expect(draft.title == "Fliesen kaufen")
        let base = Entry("task-1", .task, "", epoch, epoch)
        #expect(draft.build(base, zone: berlin)?.attachment == photo)

        var empty = ComposerDraft(type: .task)
        empty.attach(photo)
        #expect(empty.type == .task)
        #expect(empty.title.isEmpty)
    }

    @Test func plainNoteBecomesFileWhenAttaching() {
        var draft = ComposerDraft(type: .note)
        draft.attach(photo)
        #expect(draft.type == .file)
        #expect(draft.title == "Urlaub.Strand")

        var written = ComposerDraft(type: .note)
        written.title = "Idee"
        written.attach(photo)
        #expect(written.type == .note)
        #expect(written.title == "Idee")
    }

    @Test func libraryFindsFileEntryByHash() throws {
        let library = EntryLibrary(root: temporaryDirectory())
        let file = try library.save(library.newEntry(.file, title: "Alt").with { $0.attachment = photo })
        #expect(library.fileEntry(photo.hash)?.id == file.id)
        #expect(library.fileEntry(photo.hash, excluding: file.id) == nil)
        #expect(library.fileEntry(other.hash) == nil)
    }
}
