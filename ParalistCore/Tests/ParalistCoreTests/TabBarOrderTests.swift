// Zusammenhang: Library/TabBarOrder.swift
import Testing
@testable import ParalistCore

struct TabBarOrderTests {
    private let known = ["overview", "calendar", "tasks"]
    private var standard: TabBarOrder { .standard(first: "overview") }

    @Test func standardShowsOnlyTheFirstTabAroundCreateAndMenu() {
        #expect(standard.slots == [.tab("overview"), .create, .menu])
        #expect(standard.tabs == ["overview"])
        #expect(!standard.canHide)
    }

    @Test func showInsertsDirectlyBeforeCreate() {
        var order = standard
        order.show("tasks")
        #expect(order.slots == [.tab("overview"), .tab("tasks"), .create, .menu])
        order.show("tasks")
        #expect(order.tabs == ["overview", "tasks"])
        order.show("calendar")
        #expect(order.slots == [.tab("overview"), .tab("tasks"), .tab("calendar"), .create, .menu])
    }

    @Test func atMostThreeTabsCanBeShown() {
        var order = standard
        order.show("calendar")
        order.show("tasks")
        #expect(!order.canShow)
        order.show("media")
        #expect(order.tabs == ["overview", "calendar", "tasks"])
        order.hide("tasks")
        #expect(order.canShow)
        order.show("media")
        #expect(order.tabs == ["overview", "calendar", "media"])
    }

    @Test func showAfterCreateWhenCreateLeadsTheBar() {
        var order = TabBarOrder(slots: [.create, .tab("overview"), .menu])
        order.show("tasks")
        #expect(order.slots == [.create, .tab("tasks"), .tab("overview"), .menu])
    }

    @Test func theLastTabCannotBeHidden() {
        var order = standard
        let hidLast = order.hide("overview")
        #expect(!hidLast)
        #expect(order == standard)
        order.show("calendar")
        #expect(order.canHide)
        let hidFirst = order.hide("overview")
        #expect(hidFirst)
        #expect(order.slots == [.tab("calendar"), .create, .menu])
        let hidUnknown = order.hide("tasks")
        #expect(!hidUnknown)
    }

    @Test func moveSwapsTwoSlots() {
        var order = standard
        order.show("tasks")
        order.move(.tab("tasks"), to: 3)
        #expect(order.slots == [.tab("overview"), .menu, .create, .tab("tasks")])
        order.move(.create, to: 0)
        #expect(order.slots == [.create, .menu, .tab("overview"), .tab("tasks")])
        order.move(.create, to: 0)
        order.move(.create, to: 9)
        #expect(order.slots == [.create, .menu, .tab("overview"), .tab("tasks")])
    }

    @Test func encodingRoundTrips() {
        var order = standard
        order.show("calendar")
        order.move(.menu, to: 0)
        #expect(order.encoded == "menu,calendar,create,overview")
        #expect(TabBarOrder.decode(order.encoded, known: known, standard: standard) == order)
    }

    @Test func brokenValuesFallBackToTheStandard() {
        #expect(TabBarOrder.decode(nil, known: known, standard: standard) == standard)
        #expect(TabBarOrder.decode("", known: known, standard: standard) == standard)
        #expect(TabBarOrder.decode("overview,create", known: known, standard: standard) == standard)
        #expect(TabBarOrder.decode("create,menu", known: known, standard: standard) == standard)
        #expect(TabBarOrder.decode("overview,overview,create,menu", known: known, standard: standard) == standard)
        #expect(TabBarOrder.decode("overview,create,create,menu", known: known, standard: standard) == standard)
        #expect(TabBarOrder.decode("overview,media,create,menu", known: known, standard: standard) == standard)
        #expect(TabBarOrder.decode("overview,calendar,tasks,media,create,menu", known: known + ["media"], standard: standard) == standard)
    }
}
