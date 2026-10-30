// Zusammenhang: Sources/ParalistCore/Library/ViewSetting.swift, Sources/ParalistCore/Library/ListKind.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct ViewSettingTests {
    private let rows = [
        Entry("b", .note, "Beta", Date(timeIntervalSince1970: 100), Date(timeIntervalSince1970: 300)),
        Entry("a", .task, "alpha", Date(timeIntervalSince1970: 200), Date(timeIntervalSince1970: 100)),
        Entry("c", .tag, "Clara", Date(timeIntervalSince1970: 300), Date(timeIntervalSince1970: 200)),
    ]

    private func ids(_ s: ViewSetting) -> [String] { s.arrange(rows).flatMap(\.1).map(\.id) }

    @Test func sortsInBothDirections() {
        #expect(ids(ViewSetting(sort: .updated)) == ["b", "c", "a"])
        #expect(ids(ViewSetting(sort: .updated, ascending: true)) == ["a", "c", "b"])
        #expect(ids(ViewSetting(sort: .created)) == ["c", "a", "b"])
        #expect(ids(ViewSetting(sort: .created, ascending: true)) == ["b", "a", "c"])
        #expect(ids(ViewSetting(sort: .title)) == ["a", "b", "c"])
        #expect(ids(ViewSetting(sort: .title, ascending: false)) == ["c", "b", "a"])
    }

    @Test func hiddenTypesAreFilteredOut() {
        #expect(ids(ViewSetting(hidden: [.tag, .task])) == ["b"])
    }

    @Test func inboxHidesTagsByDefault() {
        #expect(ViewSetting.standard(for: .inbox).hidden == [.tag])
        #expect(ViewSetting.standard(for: .all).hidden.isEmpty)
        #expect(ListKind.inbox.filterChoices.contains(.tag))
        #expect(!ListKind.inbox.filterChoices.contains(.project))
        #expect(ListKind.tasks.filterChoices.isEmpty)
    }

    @Test func hiddenChoicesComeFirst() {
        let order = ViewSetting(hidden: [.flashcard, .note]).choices(for: .inbox)
        #expect(Array(order.prefix(2)) == [.note, .flashcard])
        #expect(order.count == ListKind.inbox.filterChoices.count)
        #expect(ViewSetting().choices(for: .inbox) == ListKind.inbox.filterChoices)
    }

    @Test func groupsFollowTypeOrder() {
        let groups = ViewSetting(grouping: .type).arrange(rows)
        #expect(groups.map(\.0) == [.note, .task, .tag])
    }

    @Test func hiddenKeyRoundTrips() {
        let key = ViewSetting.hiddenKey([.tag, .note])
        #expect(key == "notiz,tag")
        #expect(ViewSetting.hidden(fromKey: key) == [.tag, .note])
        #expect(ViewSetting.hidden(fromKey: "").isEmpty)
    }
}
