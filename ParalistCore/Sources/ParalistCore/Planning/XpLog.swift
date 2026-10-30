// Zusammenhang: Model/Entry.swift, Flashcards/ReviewLog.swift, Paralist/Pages/ProgressPage.swift, Paralist/Components/LevelRing.swift
import Foundation

public enum XpKind: CaseIterable, Sendable { case created, done, reviewed }

public struct XpEvent: Hashable, Sendable {
    public let at: Date
    public let kind: XpKind
    public let title: String
    public let amount: Int
    public let type: EntryType?
}

public struct LevelInfo: Hashable, Sendable {
    public let level: Int
    public let from: Int
    public let to: Int?
    public let progress: Double
}

public enum XpLog {
    public static let pointsByType: [EntryType: Int] = [
        .project: 5, .area: 5, .deck: 3, .bookmark: 2, .document: 2, .file: 2,
        .note: 1, .task: 1, .event: 1, .flashcard: 1, .tag: 1,
    ]
    public static let donePoints = 2
    public static let reviewPoints = 1
    public static let levels = [0, 20, 50, 100, 180, 300, 450, 650, 900, 1200, 1600, 2100, 2700, 3400, 4200, 5100, 6100, 7200, 8400, 10_000]

    public static func build(_ entries: [Entry], reviews: [[ReviewEvent]]) -> [XpEvent] {
        var log: [XpEvent] = []
        let byId = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        for entry in entries {
            log.append(XpEvent(at: entry.created, kind: .created, title: entry.title, amount: pointsByType[entry.type] ?? 1, type: entry.type))
            if entry.isDone {
                log.append(XpEvent(at: entry.doneAt ?? entry.updated, kind: .done, title: entry.title, amount: donePoints, type: entry.type))
            }
        }
        for list in reviews {
            for event in list {
                log.append(XpEvent(at: event.at, kind: .reviewed, title: cardTitle(byId[event.cardId]), amount: reviewPoints, type: .flashcard))
            }
        }
        return log.sorted { $0.at > $1.at }
    }

    public static func cardTitle(_ card: Entry?) -> String {
        guard let card else { return "" }
        let back = card.body.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n").first ?? ""
        return back.isEmpty ? card.title : "\(card.title) ⇄ \(back)"
    }

    public static func total(_ log: [XpEvent]) -> Int { log.reduce(0) { $0 + $1.amount } }

    public static func totalsByKind(_ log: [XpEvent]) -> [XpKind: Int] {
        Dictionary(uniqueKeysWithValues: XpKind.allCases.map { kind in (kind, log.filter { $0.kind == kind }.reduce(0) { $0 + $1.amount }) })
    }

    public static func level(_ xp: Int) -> LevelInfo {
        var index = 0
        while index + 1 < levels.count && xp >= levels[index + 1] { index += 1 }
        let from = levels[index]
        let to = index + 1 < levels.count ? levels[index + 1] : nil
        let progress = to.map { min(max(Double(xp - from) / Double($0 - from), 0), 1) } ?? 1
        return LevelInfo(level: index + 1, from: from, to: to, progress: progress)
    }

    public static func perDay(_ log: [XpEvent], days: Int, today: Day, zone: TimeZone) -> [Int] {
        let start = today.adding(days: -(days - 1))
        var values = Array(repeating: 0, count: days)
        for event in log {
            let day = Day.of(event.at, in: zone)
            if day >= start && day <= today { values[day.epochDay - start.epochDay] += event.amount }
        }
        return values
    }

    public static func streak(_ log: [XpEvent], today: Day, zone: TimeZone) -> Int {
        let active = Set(log.map { Day.of($0.at, in: zone) })
        var day = active.contains(today) ? today : today.adding(days: -1)
        var count = 0
        while active.contains(day) {
            count += 1
            day = day.adding(days: -1)
        }
        return count
    }
}
