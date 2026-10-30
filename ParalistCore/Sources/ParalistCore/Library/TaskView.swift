// Zusammenhang: Library/ViewSetting.swift, Library/ListKind.swift (Ordering.tasks), Model/Day.swift, Paralist/App/AppPrefs.swift, Paralist/App/AppModel.swift (Archiv), Paralist/Pages/TasksPage.swift, Paralist/Pages/TaskViewSheet.swift
import Foundation

public enum TaskSort: String, CaseIterable, Sendable {
    case created = "erstellt", updated = "geaendert", due = "faellig", title = "titel"

    public static func fromKey(_ key: String?) -> TaskSort { key.flatMap(TaskSort.init(rawValue:)) ?? .created }

    public var naturalAscending: Bool { self == .title || self == .due }
}

public enum DoneVisibility: String, CaseIterable, Sendable {
    case always = "immer", sameDay = "tag", week = "woche", never = "nie"

    public static func fromKey(_ key: String?) -> DoneVisibility { key.flatMap(DoneVisibility.init(rawValue:)) ?? .sameDay }

    public func shows(doneAt: Date?, today: Day, zone: TimeZone) -> Bool {
        switch self {
        case .always: return true
        case .never: return false
        case .sameDay, .week:
            guard let doneAt else { return false }
            let age = today.epochDay - Day.of(doneAt, in: zone).epochDay
            return age >= 0 && age < (self == .sameDay ? 1 : 7)
        }
    }
}

public enum TaskGrouping: String, CaseIterable, Sendable {
    case none = "keine", status = "status"

    public static func fromKey(_ key: String?) -> TaskGrouping { key.flatMap(TaskGrouping.init(rawValue:)) ?? .none }
}

public struct TaskViewSetting: Hashable, Sendable {
    public static let statuses: [TaskStatus] = [.open, .inProgress, .done]

    public var sort: TaskSort
    public var ascending: Bool
    public var grouping: TaskGrouping
    public var groupOrder: [TaskStatus]
    public var done: DoneVisibility

    public init(sort: TaskSort = .created, ascending: Bool? = nil, grouping: TaskGrouping = .none, groupOrder: [TaskStatus] = statuses, done: DoneVisibility = .sameDay) {
        self.sort = sort
        self.ascending = ascending ?? sort.naturalAscending
        self.grouping = grouping
        self.groupOrder = Self.completed(groupOrder)
        self.done = done
    }

    public static func completed(_ order: [TaskStatus]) -> [TaskStatus] {
        var seen: [TaskStatus] = []
        for status in order where statuses.contains(status) && !seen.contains(status) { seen.append(status) }
        return seen + statuses.filter { !seen.contains($0) }
    }

    public func moveGroup(from: Int, to: Int) -> TaskViewSetting {
        var order = groupOrder
        guard order.indices.contains(from), (0...order.count).contains(to) else { return self }
        let moved = order.remove(at: from)
        order.insert(moved, at: to > from ? to - 1 : to)
        var copy = self
        copy.groupOrder = order
        return copy
    }

    public func adoptingDefaultDone(unlessCustomized customized: Bool) -> TaskViewSetting {
        guard !customized else { return self }
        var copy = self
        copy.done = TaskViewSetting().done
        return copy
    }

    public static func active(_ tasks: [Entry]) -> [Entry] { tasks.filter { !$0.archived && !$0.isDone } }

    public func archived(_ tasks: [Entry], today: Day, zone: TimeZone) -> [Entry] {
        tasks.filter { $0.archived || ($0.isDone && !done.shows(doneAt: $0.doneAt, today: today, zone: zone)) }
    }

    public func archive(_ entries: [Entry], today: Day, zone: TimeZone) -> [Entry] {
        entries.filter { $0.archived || ($0.type == .task && $0.isDone && !done.shows(doneAt: $0.doneAt, today: today, zone: zone)) }
            .sorted { $0.updated > $1.updated }
    }

    public static func pinned(_ tasks: [Entry]) -> [Entry] {
        tasks.filter { $0.pinned && !$0.archived }.sorted { $0.updated > $1.updated }
    }

    public func visible(_ tasks: [Entry], archive: Bool, today: Day, zone: TimeZone) -> [Entry] {
        if archive { return archived(tasks, today: today, zone: zone) }
        return tasks.filter { !$0.archived && (!$0.isDone || done.shows(doneAt: $0.doneAt, today: today, zone: zone)) }
    }

    public func sorted(_ tasks: [Entry]) -> [Entry] {
        tasks.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            if grouping == .none, a.isDone != b.isDone { return !a.isDone }
            return less(a, b)
        }
    }

    private func less(_ a: Entry, _ b: Entry) -> Bool {
        switch sort {
        case .created: return ascending ? a.created < b.created : a.created > b.created
        case .updated: return ascending ? a.updated < b.updated : a.updated > b.updated
        case .due:
            if a.due == nil || b.due == nil {
                if a.due == nil && b.due == nil { return a.created > b.created }
                return a.due != nil
            }
            return ascending ? a.due! < b.due! : a.due! > b.due!
        case .title:
            let order = a.title.localizedCaseInsensitiveCompare(b.title)
            return ascending ? order == .orderedAscending : order == .orderedDescending
        }
    }

    public func arrange(_ tasks: [Entry], archive: Bool, today: Day, zone: TimeZone) -> [(TaskStatus?, [Entry])] {
        let rows = sorted(visible(tasks, archive: archive, today: today, zone: zone))
        if grouping == .none { return [(nil, rows)] }
        return groupOrder.compactMap { status in
            let group = rows.filter { ($0.status ?? .open) == status }
            return group.isEmpty ? nil : (status, group)
        }
    }

    public var encoded: String {
        [sort.rawValue, ascending ? "auf" : "ab", grouping.rawValue, groupOrder.map(\.key).joined(separator: ","), done.rawValue].joined(separator: ";")
    }

    public static func decode(_ text: String?) -> TaskViewSetting {
        guard let text else { return TaskViewSetting() }
        let parts = text.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 5 else { return TaskViewSetting() }
        let sort = TaskSort.fromKey(parts[0])
        let order = parts[3].split(separator: ",").compactMap { TaskStatus.fromKey(String($0)) }
        return TaskViewSetting(sort: sort, ascending: parts[1] == "auf", grouping: TaskGrouping.fromKey(parts[2]), groupOrder: order, done: DoneVisibility.fromKey(parts[4]))
    }
}
