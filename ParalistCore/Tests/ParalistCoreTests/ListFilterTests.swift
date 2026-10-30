// Zusammenhang: Sources/ParalistCore/Library/ListFilter.swift, Sources/ParalistCore/Library/ListKind.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct ListFilterTests {
    private func file(_ id: String, _ mime: String) -> Entry {
        Entry(id, .file, id, epoch, epoch) { $0.attachment = Attachment(hash: String(repeating: "a", count: 64), name: id, mime: mime, size: 1) }
    }

    @Test func resourcesIncludeNotesButNotTasks() {
        #expect(ListKind.resources.includes(Entry("n", .note, "Notiz", epoch, epoch)))
        #expect(ListKind.resources.includes(Entry("d", .document, "Dok", epoch, epoch)))
        #expect(!ListKind.resources.includes(Entry("t", .task, "Aufgabe", epoch, epoch)))
        #expect(!ListKind.resources.includes(Entry("a", .note, "Alt", epoch, epoch) { $0.archived = true }))
    }

    @Test func filesSplitByMediaKind() {
        #expect(ListFilter.images.matches(file("i", "image/png")))
        #expect(ListFilter.videos.matches(file("v", "video/mp4")))
        #expect(ListFilter.audios.matches(file("a", "audio/m4a")))
        #expect(ListFilter.files.matches(file("p", "application/pdf")))
        #expect(!ListFilter.files.matches(file("i", "image/png")))
        #expect(!ListFilter.documents.matches(file("p", "application/pdf")))
    }

    @Test func visibleTabsHideEmptyOnesButKeepAll() {
        let rows = [Entry("n", .note, "Notiz", epoch, epoch), file("i", "image/png")]
        #expect(ListFilter.visible(for: .resources, in: rows) == [.all, .notes, .images])
        #expect(ListFilter.visible(for: .archive, in: []) == [.all])
        #expect(ListFilter.tabs(for: .tasks).isEmpty)
        #expect(ListFilter.tabs(for: .archive).prefix(5) == [.all, .areas, .projects, .tasks, .events])
    }
}
