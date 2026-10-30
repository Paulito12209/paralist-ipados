// Zusammenhang: Sources/ParalistCore/Library/PlacePicker.swift, Sources/ParalistCore/Library/EntryParent.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct PlacePickerTests {
    private let all = [
        Entry("a", .area, "Biologie", epoch, epoch),
        Entry("p", .project, "Referat", epoch, epoch),
        Entry("p2", .project, "Klausur", epoch, epoch),
        Entry("t", .tag, "Schule", epoch, epoch),
        Entry("k", .task, "Lernen", epoch, epoch),
        Entry("b", .bookmark, "Video", epoch, epoch),
    ]

    @Test func tabsFollowCategory() {
        #expect(PlacePicker.tabs(for: .area) == [.tags])
        #expect(PlacePicker.tabs(for: .tag) == [.tags])
        #expect(PlacePicker.tabs(for: .project) == [.areas, .tags])
        #expect(PlacePicker.tabs(for: .bookmark) == LinkPicker.tabs(for: .bookmark))
    }

    @Test func areaBelongsToOneTag() {
        let area = all[0]
        #expect(PlacePicker.pool(for: area, in: all).map(\.id) == ["t"])
        #expect(PlacePicker.places(for: area, picking: all[3]) == ["t"])
        #expect(PlacePicker.places(for: area, picking: all[1]).isEmpty)
    }

    @Test func projectBelongsToAreaOrTag() {
        let project = all[1]
        #expect(PlacePicker.pool(for: project, in: all).map(\.id) == ["a", "t"])
        #expect(PlacePicker.places(for: project, picking: all[0]) == ["a"])
        #expect(PlacePicker.places(for: project, picking: all[3]) == ["t"])
        #expect(PlacePicker.places(for: project, picking: nil).isEmpty)
    }

    @Test func onlyOneOwnerAtATime() {
        var bookmark = all[5]
        #expect(Set(PlacePicker.pool(for: bookmark, in: all).map(\.id)) == ["a", "p", "p2", "t", "k"])
        bookmark.places = PlacePicker.places(for: bookmark, picking: all[1])
        #expect(bookmark.places == ["p"])
        bookmark.places = PlacePicker.places(for: bookmark, picking: all[3])
        #expect(bookmark.places == ["t"])
        #expect(PlacePicker.isPicked("t", by: bookmark))
        #expect(!PlacePicker.isPicked("p", by: bookmark))
        bookmark.places = PlacePicker.places(for: bookmark, picking: all[4])
        #expect(bookmark.places == ["k"])
        #expect(PlacePicker.places(for: bookmark, picking: all[4]).isEmpty)
    }

    @Test func tagNestsInTagsButNotInItsChildren() {
        let school = Entry("s", .tag, "Schule", epoch, epoch)
        var gym = Entry("g", .tag, "Gymnasium", epoch, epoch)
        gym.places = ["s"]
        let uni = Entry("u", .tag, "Uni", epoch, epoch)
        let tags = [school, gym, uni, all[0]]
        #expect(PlacePicker.pool(for: school, in: tags).map(\.id) == ["u"])
        #expect(PlacePicker.places(for: uni, picking: school) == ["s"])
        #expect(PlacePicker.places(for: gym, picking: school).isEmpty)
    }
}
