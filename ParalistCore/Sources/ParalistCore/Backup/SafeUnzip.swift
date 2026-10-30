// Zusammenhang: Backup/Zip.swift, Backup/BackupFormat.swift, Backup/ImportPlanner.swift, Paralist/Backup/BackupActions.swift
import Foundation

public struct Staged: Sendable {
    public let dir: URL
    public let ignored: Int
}

public enum SafeUnzip {
    public static func extract(_ zip: URL, to staging: URL, limits: BackupLimits = BackupLimits()) throws -> Staged {
        let reader = try ZipReader(url: zip, limits: limits)
        let files = FileManager.default
        if files.fileExists(atPath: staging.path), let items = try? files.contentsOfDirectory(atPath: staging.path), !items.isEmpty {
            throw BackupRejected(.unsafePath)
        }
        do {
            try files.createDirectory(at: staging, withIntermediateDirectories: true)
            for area in BackupArea.allCases where !area.rawValue.isEmpty {
                try files.createDirectory(at: staging.appendingPathComponent(area.rawValue), withIntermediateDirectories: true)
            }
            var ignored = 0
            var total: Int64 = 0
            for entry in reader.entries where !entry.isDirectory {
                guard let target = BackupFormat.classify(entry.name) else {
                    ignored += 1
                    continue
                }
                let dir = target.area == .manifest ? staging : staging.appendingPathComponent(target.area.rawValue)
                let out = dir.appendingPathComponent(target.fileName)
                if files.fileExists(atPath: out.path) { throw BackupRejected(.unsafePath) }
                let data = try reader.read(entry, maxBytes: limits.maxFileBytes)
                total += Int64(data.count)
                if total > limits.maxTotalBytes { throw BackupRejected(.tooLarge) }
                try data.write(to: out)
            }
            return Staged(dir: staging, ignored: ignored)
        } catch let error as BackupRejected {
            try? files.removeItem(at: staging)
            throw error
        } catch {
            try? files.removeItem(at: staging)
            throw BackupRejected(.unreadable)
        }
    }
}
