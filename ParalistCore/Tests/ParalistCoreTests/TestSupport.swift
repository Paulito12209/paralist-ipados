// Zusammenhang: Model/Entry.swift, Markdown/Instants.swift, Store/Ids.swift, alle Dateien in Tests/ParalistCoreTests
import Foundation
@testable import ParalistCore

let berlin = TimeZone(identifier: "Europe/Berlin")!

func at(_ text: String) -> Date { Instants.parse(text)! }

let epoch = Date(timeIntervalSince1970: 0)

extension Entry {
    init(_ id: String, _ type: EntryType, _ title: String, _ created: Date, _ updated: Date, _ configure: (inout Entry) -> Void = { _ in }) {
        self.init(id: id, type: type, title: title, created: created, updated: updated)
        configure(&self)
    }

    func with(_ change: (inout Entry) -> Void) -> Entry {
        var copy = self
        change(&copy)
        return copy
    }
}

func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("paralist-tests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

final class StepClock: Clock, @unchecked Sendable {
    private let lock = NSLock()
    private let base: Date
    private var ticks = 0

    init(_ base: Date) { self.base = base }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        ticks += 1
        return base.addingTimeInterval(Double(ticks))
    }
}

final class CountingIds: IdGenerator, @unchecked Sendable {
    private let lock = NSLock()
    private let prefix: String
    private var counter = 0

    init(_ prefix: String = "id") { self.prefix = prefix }

    func next() -> String {
        lock.lock()
        defer { lock.unlock() }
        counter += 1
        return "\(prefix)-\(counter)"
    }
}
