// Zusammenhang: Sources/ParalistCore/Library/OverviewLayout.swift, Sources/ParalistCore/Library/OverviewScope.swift
import Foundation
import Testing
@testable import ParalistCore

struct OverviewLayoutTests {
    private let at = Date(timeIntervalSince1970: 1_790_000_000)
    private let marked = OverviewTab.markedId
    private let lists = OverviewTab.listsId

    private func entry(_ id: String, _ type: EntryType, in places: [String] = [], minutes: Double = 0) -> Entry {
        var e = Entry(id: id, type: type, title: id, created: at, updated: at.addingTimeInterval(minutes * 60))
        e.places = places
        return e
    }

    @Test func standardShowsInboxThenPinned() {
        let layout = OverviewLayout.standard()
        #expect(layout.style == .tabs)
        #expect(layout.tabs.map(\.id) == [lists, marked])
        #expect(layout.visibleTabs.map(\.id) == [lists])
        #expect(layout.tab(marked)?.hidden == true)
        #expect(layout.tab(lists)?.active == .list(.inbox))
        #expect(layout.tab(marked)?.active == .list(.pinned))
        #expect(layout.tab(lists)?.sources.count == OverviewSource.listChoices.count)
        #expect(layout.tabDisplay == .both)
        #expect(layout.sectionLimit == nil)
        #expect(OverviewLayout.standard(marked: .favorites, lists: .tasks).tab(lists)?.active == .list(.tasks))
    }

    @Test func sourcesSplitIntoListsAndCollections() {
        #expect(ListKind.collections == [.inbox, .pinned, .favorites, .resources, .archive, .all])
        #expect(ListKind.lists.contains(.projects) && ListKind.lists.contains(.areas))
        #expect(Set(ListKind.collections).isDisjoint(with: ListKind.lists))
        #expect(OverviewSource.list(.inbox).category == .collection)
        #expect(OverviewSource.list(.projects).category == .list)
        #expect(OverviewSource.entry("x").category == .entry)
        #expect(OverviewSource.fromKey("liste:projekte") == .list(.projects))
        #expect(OverviewSource.fromKey("liste:markiert") == nil)
    }

    @Test func legacyBuiltInsGainNewSources() {
        let raw = #"{"stil":"reiter","tabs":[{"id":"markiert","quellen":["liste:angepinnt","liste:favoriten"],"aktiv":"liste:favoriten","aus":true},{"id":"listen","quellen":["liste:eingang","liste:aufgaben"],"aktiv":"liste:aufgaben"},{"id":"t","quellen":["liste:notizen"]}]}"#
        let layout = OverviewLayout.decode(raw)
        #expect(layout.tabs.map(\.id) == [marked, lists, "t"])
        #expect(layout.tab(marked)?.hidden == true)
        #expect(layout.tab(marked)?.active == .list(.favorites))
        #expect(Array(layout.tab(lists)?.sources.prefix(2) ?? []) == [.list(.inbox), .list(.tasks)])
        #expect(layout.tab(lists)?.sources.count == OverviewSource.listChoices.count)
        #expect(layout.tab("t")?.sources == [.list(.notes)])
        let again = OverviewLayout.decode(layout.encoded)
        #expect(again == layout)
        var trimmed = again
        trimmed.toggle(.list(.archive), in: lists)
        #expect(OverviewLayout.decode(trimmed.encoded).contains(.list(.archive), in: lists) == false)
    }

    @Test func displayAndLimitRoundTrip() {
        var layout = OverviewLayout.standard()
        layout.tabDisplay = .icon
        layout.sectionLimit = 23
        #expect(layout.sectionLimit == 25)
        layout.sectionLimit = 1
        #expect(layout.sectionLimit == 5)
        layout.sectionLimit = 70
        #expect(layout.sectionLimit == 50)
        layout.sectionLimit = 500
        #expect(layout.sectionLimit == 100)
        #expect(OverviewSectionLimit.index(100) == OverviewSectionLimit.steps.count - 1)
        layout.sectionLimit = 15
        let decoded = OverviewLayout.decode(layout.encoded)
        #expect(decoded.tabDisplay == .icon && decoded.sectionLimit == 15)
        layout.sectionLimit = nil
        #expect(OverviewLayout.decode(layout.encoded).sectionLimit == nil)
        let older = #"{"stil":"reiter","v":2,"je":10,"tabs":[]}"#
        #expect(OverviewLayout.decode(older).sectionLimit == nil)
        #expect(OverviewSectionLimit.cut(groups: [("a", Array(0..<12))], limit: nil).more == 0)
        let grouped = OverviewSectionLimit.cut(groups: [("a", Array(0..<4)), ("b", Array(0..<4)), ("c", [9])], limit: 5)
        #expect(grouped.groups.map(\.0) == ["a", "b"] && grouped.groups.map(\.1.count) == [4, 1] && grouped.more == 4)
        #expect(OverviewTabDisplay.name.showsIcon == false && OverviewTabDisplay.icon.showsName == false)
    }

    @Test func onlyEntryTabsCanBeRenamed() {
        var layout = OverviewLayout.standard()
        layout.addTab(id: "e", source: .entry("uni"))
        layout.addTab(id: "l", source: .list(.inbox))
        layout.rename("e", "Studium")
        layout.rename("l", "Mein Eingang")
        #expect(layout.tab("e")?.customName == "Studium")
        #expect(layout.tab("l")?.name == "")
        #expect(layout.tab("l")?.canRename == false)
        #expect(layout.tab(lists)?.canRename == false)
    }

    @Test func roundTrips() {
        var layout = OverviewLayout.standard(style: .tabs)
        layout.addTab(id: "t1", name: "  Privat ")
        layout.toggle(.list(.projects), in: "t1")
        layout.toggle(.entry("uni"), in: "t1")
        layout.setActive(.entry("uni"), in: "t1")
        layout.setHidden(marked, false)
        layout.setHidden(lists, true)
        let decoded = OverviewLayout.decode(layout.encoded)
        #expect(decoded == layout)
        #expect(decoded.tab("t1")?.name == "Privat")
        #expect(decoded.tab("t1")?.active == .entry("uni"))
        #expect(decoded.visibleTabs.map(\.id) == [marked, "t1"])
    }

    @Test func decodeIsTolerant() {
        #expect(OverviewLayout.decode(nil) == .standard())
        #expect(OverviewLayout.decode("kaputt") == .standard())
        let raw = #"{"stil":"quer","tabs":[{"id":"listen","quellen":["liste:aufgaben","liste:quatsch","eintrag:","liste:aufgaben"],"aktiv":"liste:termine"},{"id":"x","quellen":[]},{"id":"listen","quellen":[]}]}"#
        let layout = OverviewLayout.decode(raw)
        #expect(layout.style == .tabs)
        #expect(layout.tabs.map(\.id) == [lists, marked])
        #expect(layout.tab(lists)?.sources.first == .list(.tasks))
        #expect(layout.tab(lists)?.active == .list(.events))
        #expect(OverviewLayout.legacyStyle("untereinander|listen,markiert") == .stacked)
    }

    @Test func builtInsStayButCanHide() {
        var layout = OverviewLayout.standard()
        layout.removeTab(marked)
        layout.rename(lists, "Projekt A")
        #expect(layout.tabs.count == 2)
        #expect(layout.tab(lists)?.name == "")
        #expect(layout.tab(marked)?.hidden == true)
        #expect(!layout.canHide(lists))
        layout.setHidden(lists, true)
        #expect(layout.visibleTabs.map(\.id) == [lists])
        layout.addTab(id: "t", name: "Uni")
        layout.setHidden(lists, true)
        #expect(layout.visibleTabs.map(\.id) == ["t"])
        layout.removeTab("t")
        #expect(layout.visibleTabs.map(\.id) == [lists])
    }

    @Test func builtInKeepsOneSource() {
        let raw = #"{"stil":"reiter","v":2,"tabs":[{"id":"markiert","quellen":["liste:angepinnt","liste:favoriten"]}]}"#
        var layout = OverviewLayout.decode(raw)
        layout.toggle(.list(.pinned), in: marked)
        #expect(layout.tab(marked)?.active == .list(.favorites))
        #expect(!layout.canRemove(.list(.favorites), from: marked))
        layout.toggle(.list(.favorites), in: marked)
        #expect(layout.tab(marked)?.sources == [.list(.favorites)])
        layout.toggle(.list(.inbox), in: marked)
        #expect(layout.tab(marked)?.sources == [.list(.favorites), .list(.inbox)])
    }

    @Test func customTabsCanBeEmptyAndRenamed() {
        var layout = OverviewLayout.standard()
        let blank = layout.addTab(id: "t", name: "   ")
        let added = layout.addTab(id: "t", name: "Privat")
        let twice = layout.addTab(id: "t", name: "Doppelt")
        #expect(!blank && added && !twice)
        #expect(layout.tab("t")?.sources.isEmpty == true)
        #expect(layout.tab("t")?.current(existing: { _ in true }) == nil)
        layout.toggle(.entry("uni"), in: "t")
        layout.rename("t", String(repeating: "a", count: 99))
        #expect(layout.tab("t")?.name.count == OverviewLayout.maxName)
        layout.toggle(.entry("uni"), in: "t")
        layout.toggle(.list(.areas), in: "t")
        layout.toggle(.list(.areas), in: "t")
        #expect(layout.tab("t")?.sources.isEmpty == true)
    }

    @Test func singleSourceTabTakesSourceName() {
        var layout = OverviewLayout.standard()
        let added = layout.addTab(id: "s", source: .list(.inbox))
        #expect(added)
        #expect(layout.tab("s")?.namedBySource == true)
        #expect(layout.tab("s")?.active == .list(.inbox))
        let decoded = OverviewLayout.decode(layout.encoded)
        #expect(decoded.tab("s")?.sources == [.list(.inbox)])
        layout.toggle(.list(.inbox), in: "s")
        #expect(OverviewLayout.decode(layout.encoded).tab("s") == nil)
        #expect(OverviewLayout.standard().tab(OverviewTab.listsId)?.namedBySource == false)
    }

    @Test func capsTabsAndSources() {
        var layout = OverviewLayout.standard()
        for i in 0..<20 { layout.addTab(id: "t\(i)", name: "T\(i)") }
        #expect(layout.tabs.count == OverviewLayout.maxTabs)
        #expect(!layout.canAddTab)
        for i in 0..<40 { layout.toggle(.entry("e\(i)"), in: "t0") }
        #expect(layout.tab("t0")?.sources.count == OverviewLayout.maxSources)
    }

    @Test func movesTabsAndSources() {
        var layout = OverviewLayout.standard()
        layout.addTab(id: "t", name: "Uni")
        layout.moveTabs(from: [2], to: 0)
        #expect(layout.tabs.map(\.id) == ["t", lists, marked])
        layout.moveSources(in: marked, from: [2], to: 0)
        #expect(Array(layout.tab(marked)?.sources.prefix(2) ?? []) == [.list(.favorites), .list(.inbox)])
    }

    @Test func currentSkipsMissingEntries() {
        var layout = OverviewLayout.standard()
        layout.addTab(id: "t", name: "Uni")
        layout.toggle(.entry("gone"), in: "t")
        layout.toggle(.entry("here"), in: "t")
        let tab = layout.tab("t")
        #expect(tab?.current(existing: { $0 == "here" }) == .entry("here"))
        #expect(tab?.shown(existing: { $0 == "here" }) == [.entry("here")])
    }

    @Test func scopeCollectsNestedAndLinked() {
        var uni = entry("uni", .tag)
        uni.links = ["mail"]
        var archived = entry("old", .note, in: ["bio"])
        archived.archived = true
        let all = [
            uni,
            entry("bio", .area, in: ["uni"], minutes: 1),
            entry("mathe", .area, in: ["uni"], minutes: 2),
            entry("zelle", .note, in: ["bio"], minutes: 5),
            entry("analysis", .task, in: ["mathe"], minutes: 3),
            entry("mail", .bookmark, minutes: 4),
            entry("fremd", .note, in: ["privat"]),
            archived,
        ]
        #expect(OverviewScope.contents(of: "uni", in: all).map(\.id) == ["zelle", "mail", "analysis", "mathe", "bio"])
        #expect(OverviewScope.contents(of: "nichts", in: all).isEmpty)
    }

    @Test func scopeSurvivesCycles() {
        let all = [entry("a", .tag, in: ["b"]), entry("b", .tag, in: ["a"]), entry("c", .note, in: ["b"])]
        #expect(Set(OverviewScope.contents(of: "a", in: all).map(\.id)) == ["b", "c"])
    }

    @Test func choicesPutFavoritesAndPlacesFirst() {
        var star = entry("star", .note)
        star.favorite = true
        let all = [entry("note", .note, minutes: 9), entry("area", .area), star, entry("tag", .tag, minutes: 1)]
        #expect(OverviewScope.choices(in: all).map(\.id) == ["star", "tag", "area", "note"])
        #expect(OverviewScope.choices(in: all, query: "AR").map(\.id) == ["star", "area"])
    }
}
