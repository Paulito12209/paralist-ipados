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

    @Test func standardHasTwoBuiltInTabs() {
        let layout = OverviewLayout.standard()
        #expect(layout.style == .stacked)
        #expect(layout.tabs.map(\.id) == [marked, lists])
        #expect(layout.visibleTabs.map(\.id) == [lists])
        #expect(layout.tab(marked)?.sources == [.list(.pinned), .list(.favorites)])
        #expect(layout.tab(lists)?.active == .list(.inbox))
        #expect(layout.tab(lists)?.sources.count == ListKind.switchable.count)
        #expect(OverviewLayout.standard(marked: .favorites, lists: .tasks).tab(lists)?.active == .list(.tasks))
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
        #expect(layout.style == .stacked)
        #expect(layout.tabs.map(\.id) == [lists, marked])
        #expect(layout.tab(lists)?.sources == [.list(.tasks)])
        #expect(layout.tab(lists)?.active == .list(.tasks))
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
        var layout = OverviewLayout.standard()
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
        layout.rename("t", String(repeating: "a", count: 99))
        #expect(layout.tab("t")?.name.count == OverviewLayout.maxName)
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
        layout.rename("s", "Mein Eingang")
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
        #expect(layout.tabs.map(\.id) == ["t", marked, lists])
        layout.moveSources(in: marked, from: [1], to: 0)
        #expect(layout.tab(marked)?.sources == [.list(.favorites), .list(.pinned)])
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
