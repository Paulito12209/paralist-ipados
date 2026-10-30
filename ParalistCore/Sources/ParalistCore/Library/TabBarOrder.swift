// Zusammenhang: Paralist/Shell/AppTabBar.swift, Paralist/Shell/TabSlotMenu.swift, Paralist/Pages/MenuNavRow.swift, Paralist/App/AppPrefs.swift (tabOrder), Tests TabBarOrderTests.swift
import Foundation

public enum TabSlot: Hashable, Sendable {
    case tab(String)
    case create
    case menu

    public var key: String {
        switch self {
        case .tab(let key): return key
        case .create: return "create"
        case .menu: return "menu"
        }
    }

    public var tab: String? {
        if case .tab(let key) = self { return key }
        return nil
    }
}

public struct TabBarOrder: Equatable, Sendable {
    public private(set) var slots: [TabSlot]

    public init(slots: [TabSlot]) { self.slots = slots }

    public static func standard(first tab: String) -> TabBarOrder { TabBarOrder(slots: [.tab(tab), .create, .menu]) }

    public var tabs: [String] { slots.compactMap(\.tab) }

    public static let maxTabs = 3

    public var canHide: Bool { tabs.count > 1 }

    public var canShow: Bool { tabs.count < Self.maxTabs }

    public func shows(_ tab: String) -> Bool { slots.contains(.tab(tab)) }

    public func index(of slot: TabSlot) -> Int? { slots.firstIndex(of: slot) }

    public mutating func show(_ tab: String) {
        guard canShow, !shows(tab), let create = index(of: .create) else { return }
        slots.insert(.tab(tab), at: create == 0 ? 1 : create)
    }

    @discardableResult
    public mutating func hide(_ tab: String) -> Bool {
        guard canHide, let at = index(of: .tab(tab)) else { return false }
        slots.remove(at: at)
        return true
    }

    public mutating func move(_ slot: TabSlot, to position: Int) {
        guard let from = index(of: slot), slots.indices.contains(position), from != position else { return }
        slots.swapAt(from, position)
    }

    public var encoded: String { slots.map(\.key).joined(separator: ",") }

    public static func decode(_ raw: String?, known: [String], standard: TabBarOrder) -> TabBarOrder {
        guard let raw else { return standard }
        var slots: [TabSlot] = []
        for key in raw.split(separator: ",").map(String.init) {
            switch key {
            case TabSlot.create.key: slots.append(.create)
            case TabSlot.menu.key: slots.append(.menu)
            default:
                guard known.contains(key) else { return standard }
                slots.append(.tab(key))
            }
        }
        let order = TabBarOrder(slots: slots)
        guard slots.filter({ $0 == .create }).count == 1, slots.filter({ $0 == .menu }).count == 1,
              !order.tabs.isEmpty, order.tabs.count <= maxTabs, Set(order.tabs).count == order.tabs.count else { return standard }
        return order
    }
}
