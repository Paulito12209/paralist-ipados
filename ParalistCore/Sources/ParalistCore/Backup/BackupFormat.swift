// Zusammenhang: Backup/Zip.swift, Backup/BackupWriter.swift, Backup/SafeUnzip.swift, Backup/ImportPlanner.swift, Chat/ChatStore.swift
import Foundation

public struct BackupLimits: Sendable {
    public var maxTotalBytes: Int64 = 2 * 1024 * 1024 * 1024
    public var maxEntries = 50_000
    public var maxFileBytes: Int64 = 200 * 1024 * 1024
    public var maxRatio: Int64 = 100
    public var ratioFloorBytes: Int64 = 1024 * 1024

    public init() {}
}

public enum BackupArea: String, CaseIterable, Sendable {
    case entries = "eintraege", attachments = "anhaenge", reviews = "lernverlauf", chats = "chats", manifest = ""
}

public struct BackupTarget: Equatable, Sendable {
    public let area: BackupArea
    public let fileName: String
}

public struct BackupRejected: Error, Equatable {
    public enum Reason: Sendable { case notAZip, unsafePath, symlink, tooManyEntries, tooLarge, suspiciousRatio, unreadable }
    public let reason: Reason
    public init(_ reason: Reason) { self.reason = reason }
}

public enum BackupFormat {
    public static let fileExtension = "paralist"
    public static let manifest = "paralist.json"
    public static let formatVersion = 1
    private static let drive = Pattern("^[A-Za-z]:")

    public static func isSafeName(_ name: String) -> Bool {
        if name.isEmpty || name.count > 512 { return false }
        if name.hasPrefix("/") || name.contains("\\") || name.contains("\u{0}") { return false }
        if drive.contains(name) { return false }
        return !name.split(separator: "/", omittingEmptySubsequences: false).contains { $0 == ".." || $0 == "." }
    }

    public static func classify(_ name: String) -> BackupTarget? {
        if name == manifest { return BackupTarget(area: .manifest, fileName: manifest) }
        let parts = name.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 2 else { return nil }
        let (dir, file) = (parts[0], parts[1])
        switch dir {
        case BackupArea.entries.rawValue:
            guard file.hasSuffix(".md"), EntryCodec.isValidId(String(file.dropLast(3))) else { return nil }
            return BackupTarget(area: .entries, fileName: file)
        case BackupArea.attachments.rawValue:
            return Attachment.isValidHash(file) ? BackupTarget(area: .attachments, fileName: file) : nil
        case BackupArea.reviews.rawValue:
            guard file.hasSuffix(".log"), EntryCodec.isValidId(String(file.dropLast(4))) else { return nil }
            return BackupTarget(area: .reviews, fileName: file)
        case BackupArea.chats.rawValue:
            guard file.hasSuffix(".json"), EntryCodec.isValidId(String(file.dropLast(5))) else { return nil }
            return BackupTarget(area: .chats, fileName: file)
        default:
            return nil
        }
    }
}
