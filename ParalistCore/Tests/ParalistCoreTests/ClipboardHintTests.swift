// Zusammenhang: Library/ClipboardHint.swift
import Foundation
import Testing
@testable import ParalistCore

struct ClipboardHintTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let base = ClipboardHint(install: "a")

    @Test func newLinkShowsUntilTwelveHoursPassed() {
        let hint = base.observing(7, install: "a", at: now)
        #expect(hint.shows(7, hasLink: true, remote: false, at: now))
        #expect(hint.shows(7, hasLink: true, remote: false, at: now.addingTimeInterval(11 * 3600)))
        #expect(!hint.shows(7, hasLink: true, remote: false, at: now.addingTimeInterval(12 * 3600)))
    }

    @Test func seeingTheSameChangeAgainKeepsTheFirstTime() {
        let hint = base.observing(7, install: "a", at: now)
        let later = hint.observing(7, install: "a", at: now.addingTimeInterval(13 * 3600))
        #expect(later.seen == now)
        #expect(!later.shows(7, hasLink: true, remote: false, at: now.addingTimeInterval(13 * 3600)))
    }

    @Test func aNewCopyRestartsTheClock() {
        let hint = base.observing(7, install: "a", at: now)
        let fresh = hint.observing(8, install: "a", at: now.addingTimeInterval(20 * 3600))
        #expect(fresh.shows(8, hasLink: true, remote: false, at: now.addingTimeInterval(20 * 3600)))
    }

    @Test func handledStaysHiddenAcrossLaterVisits() {
        let hint = base.observing(7, install: "a", at: now).handling(7, install: "a", at: now)
        #expect(!hint.observing(7, install: "a", at: now.addingTimeInterval(60)).shows(7, hasLink: true, remote: false, at: now.addingTimeInterval(60)))
        #expect(hint.observing(8, install: "a", at: now).shows(8, hasLink: true, remote: false, at: now))
    }

    @Test func handlingAnUnseenChangeHidesIt() {
        let hint = base.handling(9, install: "a", at: now)
        #expect(!hint.shows(9, hasLink: true, remote: false, at: now))
    }

    @Test func noLinkOrForeignChangeHides() {
        let hint = base.observing(7, install: "a", at: now)
        #expect(!hint.shows(7, hasLink: false, remote: false, at: now))
        #expect(!hint.shows(8, hasLink: true, remote: false, at: now))
        #expect(!hint.shows(7, hasLink: true, remote: false, at: now.addingTimeInterval(-60)))
    }

    @Test func reinstallTreatsTheCurrentClipboardAsHandled() {
        let hint = base.observing(7, install: "a", at: now)
        let updated = hint.observing(0, install: "b", at: now.addingTimeInterval(60))
        #expect(!updated.shows(0, hasLink: true, remote: false, at: now.addingTimeInterval(60)))
        #expect(updated.install == "b")
        let copied = updated.observing(1, install: "b", at: now.addingTimeInterval(120))
        #expect(copied.shows(1, hasLink: true, remote: false, at: now.addingTimeInterval(120)))
    }

    @Test func firstLaunchEverShowsNothing() {
        let hint = ClipboardHint().observing(5, install: "a", at: now)
        #expect(!hint.shows(5, hasLink: true, remote: false, at: now))
    }

    @Test func storedHintWithoutInstallStillDecodes() throws {
        let data = Data("{\"change\":12,\"seen\":814359007,\"handled\":true}".utf8)
        let hint = try JSONDecoder().decode(ClipboardHint.self, from: data)
        #expect(hint.change == 12)
        #expect(hint.handled)
        #expect(hint.install == "")
        let roundTrip = try JSONDecoder().decode(ClipboardHint.self, from: JSONEncoder().encode(hint.observing(12, install: "a", at: now)))
        #expect(roundTrip.install == "a")
    }

    @Test func installComesFromTheFolderAboveTheAppBundle() {
        let app = ["/", "private", "var", "containers", "Bundle", "Application", "1234-ABCD", "Paralist.app"]
        #expect(ClipboardHint.install(fromPath: app) == "1234-ABCD")
        let appex = app + ["PlugIns", "ParalistShare.appex"]
        #expect(ClipboardHint.install(fromPath: appex) == "1234-ABCD")
        #expect(ClipboardHint.install(fromPath: ["Paralist.app"]) == "")
        #expect(ClipboardHint.install(fromPath: []) == "")
    }

    @Test func remoteClipboardNeverShows() {
        let hint = base.observing(7, install: "a", at: now)
        #expect(!hint.shows(7, hasLink: true, remote: true, at: now))
        #expect(hint.shows(7, hasLink: true, remote: false, at: now))
    }

    @Test func remoteMarkerIsRecognizedAmongTypes() {
        #expect(ClipboardHint.isRemote(["public.url", "com.apple.is-remote-clipboard", "public.utf8-plain-text"]))
        #expect(!ClipboardHint.isRemote(["public.url", "public.utf8-plain-text"]))
        #expect(!ClipboardHint.isRemote([]))
    }

    @Test func aRestartedCounterCountsAsHandled() {
        let hint = base.observing(57, install: "a", at: now)
        let rebooted = hint.observing(3, install: "a", at: now.addingTimeInterval(60))
        #expect(!rebooted.shows(3, hasLink: true, remote: false, at: now.addingTimeInterval(60)))
        let copied = rebooted.observing(4, install: "a", at: now.addingTimeInterval(120))
        #expect(copied.shows(4, hasLink: true, remote: false, at: now.addingTimeInterval(120)))
    }
}
