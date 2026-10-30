// Zusammenhang: Backup/Zip.swift, Backup/BackupFormat.swift, Store/EntryStore.swift, Flashcards/ReviewLog.swift, Chat/ChatStore.swift, Paralist/Backup/BackupActions.swift
import Foundation

public struct ExportStats: Equatable, Sendable {
    public let entries: Int
    public let attachments: Int
    public let reviewLogs: Int
    public let chats: Int
}

public enum BackupWriter {
    @discardableResult
    public static func write(store: EntryStore, reviews: ReviewLog, to target: URL, now: Date = Date()) throws -> ExportStats {
        let files = FileManager.default
        try files.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        let temp = target.deletingLastPathComponent().appendingPathComponent(".\(target.lastPathComponent).tmp")
        try? files.removeItem(at: temp)
        let zip = try ZipWriter(url: temp)
        try zip.add(BackupFormat.manifest, Data("{\"format\":\(BackupFormat.formatVersion),\"erstellt\":\"\(Instants.format(now))\"}\n".utf8), modified: now)
        let entries = try addDir(zip, store.entriesDir, .entries)
        let attachments = try addDir(zip, store.attachmentsDir, .attachments)
        let logs = try addDir(zip, reviews.dir, .reviews)
        let chats = try addDir(zip, ChatStore.directory(root: store.root), .chats)
        try zip.finish()
        try? files.removeItem(at: target)
        try files.moveItem(at: temp, to: target)
        return ExportStats(entries: entries, attachments: attachments, reviewLogs: logs, chats: chats)
    }

    private static func addDir(_ zip: ZipWriter, _ dir: URL, _ area: BackupArea) throws -> Int {
        let items = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey])) ?? []
        var count = 0
        for file in items.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey])
            guard values?.isRegularFile == true, !file.lastPathComponent.hasPrefix(".") else { continue }
            let name = "\(area.rawValue)/\(file.lastPathComponent)"
            guard BackupFormat.classify(name) != nil else { continue }
            try zip.add(name, try Data(contentsOf: file, options: .alwaysMapped), modified: values?.contentModificationDate ?? Date())
            count += 1
        }
        return count
    }
}
