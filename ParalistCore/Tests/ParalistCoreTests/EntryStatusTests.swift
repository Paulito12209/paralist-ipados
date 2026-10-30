// Zusammenhang: ParalistCore Model/EntryStatus.swift, Library/Usage.swift
import Foundation
import Testing
@testable import ParalistCore

struct EntryStatusTests {
    private func entry(_ type: EntryType, url: String? = nil, mime: String? = nil) -> Entry {
        var e = Entry(id: "test-0001", type: type, title: "t", created: Date(), updated: Date())
        e.url = url
        if let mime { e.attachment = Attachment(hash: "h", name: "n", mime: mime, size: 1) }
        return e
    }

    @Test func everyTypeExceptTagHasOptions() {
        for type in EntryType.allCases {
            let options = EntryStatus.options(for: entry(type))
            #expect(options.isEmpty == (type == .tag))
            #expect(type == .tag || options.first == .open)
        }
    }

    @Test func bookmarkConsumedDependsOnLink() {
        #expect(EntryStatus.options(for: entry(.bookmark, url: "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT")).contains(.listened))
        #expect(EntryStatus.options(for: entry(.bookmark, url: "https://youtu.be/dQw4w9WgXcQ")).contains(.viewed))
        #expect(EntryStatus.options(for: entry(.bookmark, url: "https://www.instagram.com/p/x")).contains(.read))
    }

    @Test func fileConsumedDependsOnMime() {
        #expect(EntryStatus.options(for: entry(.file, mime: "image/jpeg")) == [.open, .viewed, .shared])
        #expect(EntryStatus.options(for: entry(.file, mime: "video/mp4")) == [.open, .played, .shared])
        #expect(EntryStatus.options(for: entry(.file, mime: "audio/m4a")) == [.open, .listened, .shared])
        #expect(EntryStatus.options(for: entry(.file, mime: "application/pdf")) == [.open, .read, .shared])
    }

    @Test func labelsDifferByType() {
        #expect(EntryStatus.label(.done, for: .project) == "status_closed_project")
        #expect(EntryStatus.label(.done, for: .task) == "status_done")
        #expect(EntryStatus.label(.open, for: .note) == "status_unfinished")
        #expect(EntryStatus.label(.cancelled, for: .event) == "status_cancelled")
    }

    @Test func invalidStatusFallsBackToOpen() {
        #expect(EntryStatus.valid(.learned, for: entry(.task)) == .open)
        #expect(EntryStatus.valid(.learned, for: entry(.deck)) == .learned)
        #expect(EntryStatus.valid(.open, for: entry(.tag)) == nil)
    }

    @Test func changingTypeKeepsOnlyValidStatus() {
        var e = entry(.deck)
        e.status = .learned
        #expect(EntryChanges.withType(e, .task).status == .open)
        #expect(EntryChanges.withType(e, .tag).status == nil)
    }

    @Test func ratingMapsToStatus() {
        #expect(EntryStatus.rated(.again) == .hard)
        #expect(EntryStatus.rated(.easy) == .easy)
    }

    @Test func libraryRejectsForeignStatus() throws {
        let lib = EntryLibrary(root: temporaryDirectory(), clock: FixedClock(Date()))
        let task = lib.newEntry(.task, title: "a")
        _ = try lib.save(task)
        _ = try lib.setStatus(task.id, .learned)
        #expect(lib.entries[task.id]?.status == .open)
        _ = try lib.setStatus(task.id, .inProgress)
        #expect(lib.entries[task.id]?.status == .inProgress)
    }

    @Test func eventHistoryCountsMovesAndCancel() {
        var usage = UsageData()
        let now = Date()
        usage.recordMoved("e", from: now, to: now, at: now)
        #expect(usage.moves("e") == 0)
        usage.recordMoved("e", from: now, to: now.addingTimeInterval(3600), at: now)
        usage.recordCancelled("e", at: now)
        #expect(usage.moves("e") == 1)
        #expect(usage.changes("e").count == 2)
        usage.forget("e")
        #expect(usage.changes("e").isEmpty)
    }
}
