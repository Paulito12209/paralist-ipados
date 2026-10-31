// Zusammenhang: Sources/ParalistCore/Model/EntryType.swift (TagKind), Sources/ParalistCore/Markdown/EntryCodec.swift, Sources/ParalistCore/Model/EntryChanges.swift, Sources/ParalistCore/Library/ListKind.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct TagTests {
    private let day = Date(timeIntervalSince1970: 1_704_067_200)

    @Test func tagKindSurvivesRoundTrip() throws {
        let tag = Entry("tag-0001", .tag, "Anna", day, day) { $0.tagKind = .person }
        let text = EntryCodec.encode(tag)
        #expect(text.contains("typ: tag"))
        #expect(text.contains("tagart: person"))
        let back = try EntryCodec.decode(text, now: day)
        #expect(back.type == .tag)
        #expect(back.tagKind == .person)
    }

    @Test func plainTagWritesNoKind() throws {
        let text = EntryCodec.encode(Entry("tag-0002", .tag, "Ideen", day, day))
        #expect(!text.contains("tagart"))
        #expect(try EntryCodec.decode(text, now: day).tagKind == nil)
    }

    @Test func unknownKindIsRejected() {
        let text = "---\nid: tag-0003\ntyp: tag\ntitel: X\nerstellt: 2024-01-01T00:00:00Z\ntagart: tier\n---\n"
        #expect(throws: EntryParseError.self) { try EntryCodec.decode(text, now: day) }
    }

    @Test func kindIsDroppedWhenTypeChanges() {
        let tag = Entry("tag-0004", .tag, "Berlin", epoch, epoch) { $0.tagKind = .place }
        #expect(EntryChanges.withType(tag, .note).tagKind == nil)
    }

    @Test func tagsListShowsOnlyTags() {
        #expect(ListKind.lists.contains(.tags))
        #expect(ListKind.tags.includes(Entry("t", .tag, "Anna", epoch, epoch)))
        #expect(!ListKind.tags.includes(Entry("n", .note, "Notiz", epoch, epoch)))
    }

    @Test func tagsCanHoldTagsWithoutCycles() {
        let area = Entry("area-1", .area, "Arbeit", epoch, epoch)
        let ki = Entry("tag-ki", .tag, "KI", epoch, epoch)
        let llm = Entry("tag-llm", .tag, "LLMs", epoch, epoch) { $0.places = ["tag-ki"] }
        let claude = Entry("tag-cl", .tag, "Claude", epoch, epoch) { $0.places = ["tag-llm"] }
        let note = Entry("note-1", .note, "Notiz", epoch, epoch)
        let all = [area, ki, llm, claude, note]
        #expect(EntryParent.candidates(for: claude, in: all).map(\.id) == ["area-1", "tag-ki", "tag-llm"])
        #expect(EntryParent.candidates(for: ki, in: all).map(\.id) == ["area-1"])
        #expect(EntryParent.candidates(for: note, in: all).map(\.id) == ["area-1"])
    }

    @Test func tagsLinkToTags() {
        let a = Entry("tag-a", .tag, "Claude", epoch, epoch)
        let b = Entry("tag-b", .tag, "Unternehmen", epoch, epoch)
        let n = Entry("note-1", .note, "Notiz", epoch, epoch)
        #expect(LinkPicker.tabs(for: .tag).contains(.tags))
        #expect(LinkPicker.entries(.tags, for: a, in: [a, b, n]).map(\.id) == ["tag-b"])
        #expect(LinkPicker.entries(.tags, for: n, in: [a, b, n]).count == 2)
        var sub = ComposerDraft(type: .tag)
        sub.linkTo(b)
        #expect(sub.places == ["tag-b"])
        #expect(LinkPlace.linkable(for: a, in: [a, b, n]).count == 3)
    }
}
