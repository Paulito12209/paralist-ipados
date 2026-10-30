// Zusammenhang: Flashcards/Fsrs.swift, Flashcards/StudyQueue.swift, Store/EntryStore.swift (Ordner lernverlauf/), Library/EntryLibrary.swift
import Foundation

public struct ReviewEvent: Hashable, Sendable {
    public let cardId: String
    public let at: Date
    public let rating: Rating

    public init(cardId: String, at: Date, rating: Rating) {
        self.cardId = cardId
        self.at = at
        self.rating = rating
    }
}

public final class ReviewLog: @unchecked Sendable {
    public static let maxBytes = 512 * 1024
    public static let maxEvents = 10_000
    public let dir: URL
    private let files = FileManager.default

    public init(root: URL) {
        dir = root.appendingPathComponent("lernverlauf", isDirectory: true)
        try? files.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    public func append(_ event: ReviewEvent) throws {
        precondition(EntryCodec.isValidId(event.cardId), "id ungültig")
        let file = dir.appendingPathComponent("\(event.cardId).log")
        let line = Data("\(Instants.format(event.at)) \(event.rating.rawValue)\n".utf8)
        if let handle = try? FileHandle(forWritingTo: file) {
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
        } else {
            try line.write(to: file, options: .atomic)
        }
    }

    public func read(_ cardId: String, now: Date = Date()) -> [ReviewEvent] {
        guard EntryCodec.isValidId(cardId) else { return [] }
        return readFile(dir.appendingPathComponent("\(cardId).log"), cardId, now)
    }

    public func readAll(now: Date = Date()) -> [String: [ReviewEvent]] {
        let items = (try? files.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        var out: [String: [ReviewEvent]] = [:]
        for file in items where file.pathExtension == "log" {
            let id = file.deletingPathExtension().lastPathComponent
            out[id] = EntryCodec.isValidId(id) ? readFile(file, id, now) : []
        }
        return out
    }

    public func fileFor(_ cardId: String) throws -> URL {
        guard EntryCodec.isValidId(cardId) else { throw EntryParseError("id ungültig") }
        return dir.appendingPathComponent("\(cardId).log")
    }

    public func replace(_ cardId: String, _ events: [ReviewEvent]) throws {
        let text = events.sorted { $0.at < $1.at }.map { "\(Instants.format($0.at)) \($0.rating.rawValue)\n" }.joined()
        try Data(text.utf8).write(to: try fileFor(cardId), options: .atomic)
    }

    public func delete(_ cardId: String) {
        if EntryCodec.isValidId(cardId) { try? files.removeItem(at: dir.appendingPathComponent("\(cardId).log")) }
    }

    private func readFile(_ file: URL, _ cardId: String, _ now: Date) -> [ReviewEvent] {
        guard let data = try? Data(contentsOf: file), data.count <= Self.maxBytes,
              let text = String(data: data, encoding: .utf8) else { return [] }
        return Self.parse(cardId, text, now: now)
    }

    public static func parse(_ cardId: String, _ text: String, now: Date) -> [ReviewEvent] {
        var events: [ReviewEvent] = []
        for line in text.split(separator: "\n") {
            if events.count >= maxEvents { break }
            let parts = line.trimmingCharacters(in: .whitespaces).split(separator: " ")
            guard parts.count == 2, let at = Instants.parse(String(parts[0])),
                  let value = Int(parts[1]), let rating = Rating(rawValue: value) else { continue }
            if at > now.addingTimeInterval(3600) { continue }
            events.append(ReviewEvent(cardId: cardId, at: at, rating: rating))
        }
        return events.sorted { $0.at < $1.at }
    }

    public static func replay(_ events: [ReviewEvent]) -> CardState {
        events.sorted { $0.at < $1.at }.reduce(CardState()) { Fsrs.review($0, $1.rating, now: $1.at) }
    }
}
