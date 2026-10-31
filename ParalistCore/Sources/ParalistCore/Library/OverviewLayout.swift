// Zusammenhang: Library/OverviewScope.swift, Library/OverviewOptions.swift, Library/ListKind.swift, Paralist/App/AppPrefs.swift (overviewLayout), Paralist/Pages/OverviewPage.swift, Paralist/Pages/OverviewSections.swift, Paralist/Pages/OverviewEdge.swift, Paralist/Pages/OverviewSwitchSheet.swift, Paralist/Pages/OverviewTabsPage.swift, Tests OverviewLayoutTests.swift
import Foundation

public enum OverviewStyle: String, CaseIterable, Sendable {
    case tabs = "reiter"
    case stacked = "untereinander"

    public var toggled: OverviewStyle { self == .tabs ? .stacked : .tabs }
}

public enum OverviewSource: Hashable, Sendable, Identifiable {
    case list(ListKind)
    case entry(String)

    static let listPrefix = "liste:"
    static let entryPrefix = "eintrag:"

    public static let listChoices: [ListKind] = ListKind.collections + ListKind.lists

    public var id: String { key }

    public var key: String {
        switch self {
        case .list(let kind): return Self.listPrefix + kind.key
        case .entry(let id): return Self.entryPrefix + id
        }
    }

    public var kind: ListKind? {
        if case .list(let kind) = self { return kind }
        return nil
    }

    public var entryId: String? {
        if case .entry(let id) = self { return id }
        return nil
    }

    public var category: OverviewSourceCategory {
        switch self {
        case .list(let kind): return kind.isCollection ? .collection : .list
        case .entry: return .entry
        }
    }

    public static func fromKey(_ key: String) -> OverviewSource? {
        if key.hasPrefix(listPrefix) {
            return ListKind.fromKey(String(key.dropFirst(listPrefix.count))).flatMap { listChoices.contains($0) ? .list($0) : nil }
        }
        guard key.hasPrefix(entryPrefix) else { return nil }
        let id = String(key.dropFirst(entryPrefix.count))
        guard !id.isEmpty, id.count <= 64 else { return nil }
        return .entry(id)
    }
}

public struct OverviewTab: Hashable, Sendable, Identifiable {
    public static let markedId = "markiert"
    public static let listsId = "listen"

    public let id: String
    public internal(set) var name: String
    public internal(set) var sources: [OverviewSource]
    public internal(set) var active: OverviewSource?
    public internal(set) var hidden: Bool

    public init(id: String, name: String = "", sources: [OverviewSource], active: OverviewSource? = nil, hidden: Bool = false) {
        self.id = id
        self.name = name
        self.sources = sources
        self.active = active
        self.hidden = hidden
    }

    public var isBuiltIn: Bool { id == Self.markedId || id == Self.listsId }

    public var namedBySource: Bool { !isBuiltIn && name.isEmpty }

    public var canRename: Bool { !isBuiltIn && active?.category == .entry }

    public var customName: String? { canRename && !name.isEmpty ? name : nil }

    public func shown(existing: (String) -> Bool) -> [OverviewSource] {
        sources.filter { source in source.entryId.map(existing) ?? true }
    }

    public func current(existing: (String) -> Bool) -> OverviewSource? {
        let shown = shown(existing: existing)
        if let active, shown.contains(active) { return active }
        return shown.first
    }
}

public struct OverviewLayout: Equatable, Sendable {
    public static let maxTabs = 10
    public static let maxSources = 30
    public static let maxName = 40

    public static func standard(marked: ListKind = .pinned, lists: ListKind = .inbox, style: OverviewStyle = .tabs) -> OverviewLayout {
        OverviewLayout(style: style, tabs: builtInTabs(marked: marked, lists: lists))
    }

    static var catalog: [OverviewSource] { OverviewSource.listChoices.map(OverviewSource.list) }

    static func builtInTabs(marked: ListKind = .pinned, lists: ListKind = .inbox) -> [OverviewTab] {
        [
            OverviewTab(id: OverviewTab.listsId, sources: catalog, active: .list(lists)),
            OverviewTab(id: OverviewTab.markedId, sources: catalog, active: .list(marked), hidden: true),
        ]
    }

    public var style: OverviewStyle
    public private(set) var tabs: [OverviewTab]
    public var tabDisplay: OverviewTabDisplay
    public var sectionLimit: Int? { didSet { sectionLimit = sectionLimit.map(OverviewSectionLimit.clamp) } }

    public init(style: OverviewStyle, tabs: [OverviewTab], tabDisplay: OverviewTabDisplay = .both, sectionLimit: Int? = nil) {
        self.style = style
        self.tabs = tabs
        self.tabDisplay = tabDisplay
        self.sectionLimit = sectionLimit.map(OverviewSectionLimit.clamp)
        settle()
    }

    public var visibleTabs: [OverviewTab] { tabs.filter { !$0.hidden } }

    public func tab(_ id: String) -> OverviewTab? { tabs.first { $0.id == id } }

    public var canAddTab: Bool { tabs.count < Self.maxTabs }

    public func canHide(_ id: String) -> Bool {
        tab(id).map { !$0.hidden } == true && visibleTabs.count > 1
    }

    public mutating func setHidden(_ id: String, _ off: Bool) {
        guard let i = index(id), !off || canHide(id) else { return }
        tabs[i].hidden = off
    }

    @discardableResult
    public mutating func addTab(id: String, name: String) -> Bool {
        let clean = Self.clean(name)
        guard canAddTab, !clean.isEmpty, index(id) == nil, !id.isEmpty else { return false }
        tabs.append(OverviewTab(id: id, name: clean, sources: []))
        return true
    }

    @discardableResult
    public mutating func addTab(id: String, source: OverviewSource) -> Bool {
        guard canAddTab, index(id) == nil, !id.isEmpty else { return false }
        tabs.append(OverviewTab(id: id, sources: [source], active: source))
        return true
    }

    public mutating func rename(_ id: String, _ name: String) {
        let clean = Self.clean(name)
        guard let i = index(id), tabs[i].canRename, !clean.isEmpty else { return }
        tabs[i].name = clean
    }

    public mutating func removeTab(_ id: String) {
        guard let i = index(id), !tabs[i].isBuiltIn else { return }
        tabs.remove(at: i)
        settle()
    }

    public mutating func moveTabs(from source: [Int], to destination: Int) {
        tabs = Self.moved(tabs, from: source, to: destination)
    }

    public func contains(_ source: OverviewSource, in id: String) -> Bool {
        tab(id)?.sources.contains(source) == true
    }

    public func canRemove(_ source: OverviewSource, from id: String) -> Bool {
        guard let tab = tab(id), tab.sources.contains(source) else { return false }
        return !tab.isBuiltIn || tab.sources.count > 1
    }

    public mutating func toggle(_ source: OverviewSource, in id: String) {
        guard let i = index(id) else { return }
        if tabs[i].sources.contains(source) {
            guard canRemove(source, from: id) else { return }
            tabs[i].sources.removeAll { $0 == source }
            if tabs[i].active == source { tabs[i].active = tabs[i].sources.first }
        } else {
            guard tabs[i].sources.count < Self.maxSources else { return }
            tabs[i].sources.append(source)
            if tabs[i].active == nil { tabs[i].active = source }
        }
    }

    public mutating func moveSources(in id: String, from source: [Int], to destination: Int) {
        guard let i = index(id) else { return }
        tabs[i].sources = Self.moved(tabs[i].sources, from: source, to: destination)
    }

    public mutating func setActive(_ source: OverviewSource, in id: String) {
        guard let i = index(id), tabs[i].sources.contains(source) else { return }
        tabs[i].active = source
    }

    private func index(_ id: String) -> Int? { tabs.firstIndex { $0.id == id } }

    private mutating func settle() {
        var seen: Set<String> = []
        var kept: [OverviewTab] = []
        for var tab in tabs where seen.insert(tab.id).inserted && kept.count < Self.maxTabs {
            var unique: Set<OverviewSource> = []
            tab.sources = Array(tab.sources.filter { unique.insert($0).inserted }.prefix(Self.maxSources))
            tab.name = tab.isBuiltIn ? "" : Self.clean(tab.name)
            if !tab.isBuiltIn, tab.name.isEmpty, tab.sources.isEmpty { continue }
            if let active = tab.active, !tab.sources.contains(active) { tab.active = nil }
            if tab.active == nil { tab.active = tab.sources.first }
            kept.append(tab)
        }
        let fallback = Self.builtInTabs()
        for builtIn in fallback where !seen.contains(builtIn.id) { kept.append(builtIn) }
        for i in kept.indices where kept[i].isBuiltIn && kept[i].sources.isEmpty {
            kept[i].sources = fallback.first { $0.id == kept[i].id }?.sources ?? []
            kept[i].active = kept[i].sources.first
        }
        if kept.allSatisfy(\.hidden), let i = kept.firstIndex(where: { $0.id == OverviewTab.listsId }) { kept[i].hidden = false }
        tabs = kept
    }

    static func clean(_ name: String) -> String {
        String(name.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces).prefix(maxName))
    }

    static func moved<T>(_ list: [T], from source: [Int], to destination: Int) -> [T] {
        let picked = source.filter(list.indices.contains).sorted()
        guard !picked.isEmpty else { return list }
        let moving = picked.map { list[$0] }
        var rest = list
        for index in picked.reversed() { rest.remove(at: index) }
        let before = picked.filter { $0 < destination }.count
        rest.insert(contentsOf: moving, at: min(max(destination - before, 0), rest.count))
        return rest
    }
}

extension OverviewLayout {
    private struct Stored: Codable {
        struct Tab: Codable {
            var id: String
            var name: String?
            var quellen: [String]
            var aktiv: String?
            var aus: Bool?
        }

        var stil: String
        var tabs: [Tab]
        var v: Int?
        var zeigen: String?
        var je: Int?
    }

    static let version = 3

    public var encoded: String {
        let stored = Stored(stil: style.rawValue, tabs: tabs.map {
            Stored.Tab(id: $0.id, name: $0.isBuiltIn ? nil : $0.name, quellen: $0.sources.map(\.key), aktiv: $0.active?.key, aus: $0.hidden ? true : nil)
        }, v: Self.version, zeigen: tabDisplay.rawValue, je: sectionLimit)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return (try? encoder.encode(stored)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    public static func decode(_ raw: String?, fallback: OverviewLayout = .standard()) -> OverviewLayout {
        guard let raw, raw.utf8.count <= 64_000, let data = raw.data(using: .utf8),
              let stored = try? JSONDecoder().decode(Stored.self, from: data) else { return fallback }
        let legacy = (stored.v ?? 1) < 2
        let tabs = stored.tabs.compactMap { tab -> OverviewTab? in
            guard !tab.id.isEmpty, tab.id.count <= 64 else { return nil }
            var sources = tab.quellen.compactMap(OverviewSource.fromKey)
            if legacy, tab.id == OverviewTab.listsId || tab.id == OverviewTab.markedId {
                sources += catalog.filter { !sources.contains($0) }
            }
            return OverviewTab(id: tab.id, name: tab.name ?? "", sources: sources,
                               active: tab.aktiv.flatMap(OverviewSource.fromKey), hidden: tab.aus ?? false)
        }
        return OverviewLayout(style: OverviewStyle(rawValue: stored.stil) ?? fallback.style, tabs: tabs,
                              tabDisplay: stored.zeigen.flatMap(OverviewTabDisplay.init(rawValue:)) ?? .both,
                              sectionLimit: (stored.v ?? 1) < version ? nil : stored.je)
    }

    public static func legacyStyle(_ raw: String?) -> OverviewStyle? {
        raw.flatMap { $0.split(separator: "|").first }.flatMap { OverviewStyle(rawValue: String($0)) }
    }
}
