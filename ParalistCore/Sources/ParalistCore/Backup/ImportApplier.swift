// Zusammenhang: Backup/ImportPlanner.swift, Backup/BackupWriter.swift, Store/EntryStore.swift, Flashcards/ReviewLog.swift, Chat/ChatStore.swift
import Foundation

public struct ImportResult: Sendable {
    public let written: Int
    public let attachments: Int
    public let reviewLogs: Int
    public let chats: Int
    public let safetyCopy: URL
}

public struct ImportApplier {
    private let store: EntryStore
    private let reviews: ReviewLog
    private let safetyDir: URL
    private let keepSafetyCopies: Int
    private let beforeEachWrite: () throws -> Void

    public init(store: EntryStore, reviews: ReviewLog, safetyDir: URL, keepSafetyCopies: Int = 3, beforeEachWrite: @escaping () throws -> Void = {}) {
        self.store = store
        self.reviews = reviews
        self.safetyDir = safetyDir
        self.keepSafetyCopies = keepSafetyCopies
        self.beforeEachWrite = beforeEachWrite
    }

    public func apply(_ plan: ImportPlan, now: Date = Date()) throws -> ImportResult {
        let files = FileManager.default
        try files.createDirectory(at: safetyDir, withIntermediateDirectories: true)
        let millis = Int64((now.timeIntervalSince1970 * 1000).rounded())
        let safety = safetyDir.appendingPathComponent("vor-import-\(millis).\(BackupFormat.fileExtension)")
        try BackupWriter.write(store: store, reviews: reviews, to: safety, now: now)
        prune()
        let rollback = plan.staging.appendingPathComponent("zurueck", isDirectory: true)
        try files.createDirectory(at: rollback, withIntermediateDirectories: true)
        defer { try? files.removeItem(at: rollback) }
        var created: [URL] = []
        var replaced: [(URL, URL)] = []
        func remember(_ target: URL) throws {
            if files.fileExists(atPath: target.path) {
                let copy = rollback.appendingPathComponent("\(replaced.count)-\(target.lastPathComponent)")
                try files.copyItem(at: target, to: copy)
                replaced.append((target, copy))
            } else {
                created.append(target)
            }
        }
        do {
            for (hash, source) in plan.attachmentsToAdd {
                let target = store.attachmentsDir.appendingPathComponent(hash)
                if files.fileExists(atPath: target.path) { continue }
                try beforeEachWrite()
                created.append(target)
                try Data(contentsOf: source).write(to: target, options: .atomic)
            }
            for entry in plan.toWrite {
                try beforeEachWrite()
                try remember(try store.fileFor(entry.id))
                try store.write(entry)
            }
            for (id, events) in plan.reviewsToWrite {
                try beforeEachWrite()
                try remember(try reviews.fileFor(id))
                try reviews.replace(id, events)
            }
            let chats = ChatStore(root: store.root)
            for thread in plan.chatsToWrite {
                try beforeEachWrite()
                try remember(try chats.fileFor(thread.id))
                try chats.write(thread)
            }
        } catch {
            for (target, copy) in replaced {
                try? files.removeItem(at: target)
                try? files.copyItem(at: copy, to: target)
            }
            created.forEach { try? files.removeItem(at: $0) }
            throw error
        }
        return ImportResult(written: plan.toWrite.count, attachments: plan.attachmentsToAdd.count, reviewLogs: plan.reviewsToWrite.count, chats: plan.chatsToWrite.count, safetyCopy: safety)
    }

    private func prune() {
        let items = (try? FileManager.default.contentsOfDirectory(at: safetyDir, includingPropertiesForKeys: nil)) ?? []
        items.filter { $0.lastPathComponent.hasPrefix("vor-import-") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .dropFirst(keepSafetyCopies)
            .forEach { try? FileManager.default.removeItem(at: $0) }
    }
}
