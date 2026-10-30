// Zusammenhang: Chat/ChatThread.swift (pinned, links), Chat/ChatList.swift (filter, newestFirst), Library/ViewSetting.swift (SortOrder), Paralist/Chat/ChatListPage.swift, Paralist/Chat/ChatViewSheet.swift, Paralist/App/AppPrefs.swift (chatView)
import Foundation

public enum ChatFilter: String, CaseIterable, Sendable {
    case all = "alle", pinned = "angepinnt", linked = "verknuepft"

    public func matches(_ thread: ChatThread) -> Bool {
        switch self {
        case .all: return true
        case .pinned: return thread.pinned
        case .linked: return !thread.links.isEmpty
        }
    }

    public static func visible(in threads: [ChatThread]) -> [ChatFilter] {
        allCases.filter { $0 == .all || threads.contains(where: $0.matches) }
    }
}

public struct ChatViewSetting: Hashable, Sendable {
    public var sort: SortOrder
    public var ascending: Bool

    public init(sort: SortOrder = .updated, ascending: Bool? = nil) {
        self.sort = sort
        self.ascending = ascending ?? sort.naturalAscending
    }

    public var encoded: String { "\(sort.rawValue),\(ascending ? "auf" : "ab")" }

    public static func decode(_ raw: String?) -> ChatViewSetting {
        let parts = (raw ?? "").split(separator: ",").map(String.init)
        guard let first = parts.first, let sort = SortOrder(rawValue: first) else { return ChatViewSetting() }
        let ascending = parts.count > 1 ? parts[1] == "auf" : nil
        return ChatViewSetting(sort: sort, ascending: ascending)
    }

    public func arrange(_ threads: [ChatThread], filter: ChatFilter = .all, query: String = "") -> [ChatThread] {
        ChatList.filter(threads, query: query).filter(filter.matches).sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            switch sort {
            case .updated: return a.updated == b.updated ? a.id < b.id : (ascending ? a.updated < b.updated : a.updated > b.updated)
            case .created: return a.created == b.created ? a.id < b.id : (ascending ? a.created < b.created : a.created > b.created)
            case .title:
                let order = a.title.localizedCaseInsensitiveCompare(b.title)
                if order == .orderedSame { return a.id < b.id }
                return ascending ? order == .orderedAscending : order == .orderedDescending
            }
        }
    }

    public static func pinned(_ threads: [ChatThread]) -> ChatThread? {
        threads.filter(\.pinned).sorted(by: ChatList.newestFirst).first
    }
}
