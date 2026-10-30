// Zusammenhang: Sources/ParalistCore/Library/SearchHome.swift, Sources/ParalistCore/Library/Usage.swift
import Foundation
import Testing
@testable import ParalistCore

struct SearchHomeTests {
    private func entry(_ id: String, _ created: String, archived: Bool = false) -> Entry {
        var e = Entry(id: id, type: .note, title: id, created: at(created), updated: at(created))
        e.archived = archived
        return e
    }

    @Test func recentlyCreatedIsNewestFirstWithoutArchive() {
        let list = [entry("a", "2026-10-01T10:00:00Z"), entry("b", "2026-10-03T10:00:00Z"), entry("c", "2026-10-05T10:00:00Z", archived: true)]
        #expect(SearchHome.recentlyCreated(list).map(\.id) == ["b", "a"])
        #expect(SearchHome.recentlyCreated(list, limit: 1).map(\.id) == ["b"])
    }

    @Test func createdWinsWhenNewerThanLastOpen() {
        var usage = UsageData()
        usage.recordOpened("a", at: at("2026-10-02T10:00:00Z"))
        let list = [entry("a", "2026-10-01T10:00:00Z"), entry("b", "2026-10-03T10:00:00Z")]
        #expect(SearchHome.start(entries: list, usage: usage) == .created)
    }

    @Test func openedWinsWhenNewerThanLastCreate() {
        var usage = UsageData()
        usage.recordOpened("a", at: at("2026-10-04T10:00:00Z"))
        let list = [entry("a", "2026-10-01T10:00:00Z"), entry("b", "2026-10-03T10:00:00Z")]
        #expect(SearchHome.start(entries: list, usage: usage) == .opened)
    }

    @Test func openingTheNewestEntryKeepsCreated() {
        var usage = UsageData()
        usage.recordOpened("b", at: at("2026-10-04T10:00:00Z"))
        let list = [entry("a", "2026-10-01T10:00:00Z"), entry("b", "2026-10-03T10:00:00Z")]
        #expect(SearchHome.start(entries: list, usage: usage) == .created)
    }

    @Test func emptyLibraryFallsBack() {
        var usage = UsageData()
        #expect(SearchHome.start(entries: [], usage: usage) == .opened)
        usage.recordSearch("x", at: at("2026-10-04T10:00:00Z"))
        #expect(SearchHome.start(entries: [], usage: usage) == .searched)
    }

    @Test func stepsWrapAround() {
        #expect(SearchHome.opened.step(false) == .searched)
        #expect(SearchHome.searched.step(true) == .opened)
        #expect(SearchHome.opened.step(true) == .created)
    }
}
