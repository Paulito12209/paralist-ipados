// Zusammenhang: Paralist/App/AppPaths.swift, Store/EntryStore.swift, Tests/StoreTests.swift
import Foundation

public enum StorageMove {
    @discardableResult
    public static func moveIfNeeded(from old: URL, to new: URL, fm: FileManager = .default) -> Bool {
        guard fm.fileExists(atPath: old.path), !fm.fileExists(atPath: new.path) else { return false }
        do {
            try fm.createDirectory(at: new.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fm.moveItem(at: old, to: new)
            return true
        } catch {
            return false
        }
    }

}
