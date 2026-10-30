// Zusammenhang: ParalistCore Backup/*.swift, Backup/BackupImportSheet.swift, Pages/SettingsPage.swift, Files/AttachmentImporter.swift
import Foundation
import ParalistCore

enum BackupService {
    static func export(_ library: EntryLibrary) async throws -> (URL, ExportStats) {
        let store = library.store
        let reviews = library.reviews
        return try await Task.detached(priority: .userInitiated) {
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent("exporte", isDirectory: true)
            try? FileManager.default.removeItem(at: dir)
            let name = "Paralist-\(Day.of(Date(), in: .current)).\(BackupFormat.fileExtension)"
            let target = dir.appendingPathComponent(name)
            let stats = try BackupWriter.write(store: store, reviews: reviews, to: target)
            return (target, stats)
        }.value
    }

    static func prepare(_ source: URL, _ library: EntryLibrary) async throws -> ImportPlan {
        let store = library.store
        let reviews = library.reviews
        return try await Task.detached(priority: .userInitiated) {
            let work = FileManager.default.temporaryDirectory.appendingPathComponent("importe/\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
            let copy = work.appendingPathComponent("sicherung.zip")
            let scoped = source.startAccessingSecurityScopedResource()
            defer { if scoped { source.stopAccessingSecurityScopedResource() } }
            let size = (try? source.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
            if size > BackupLimits().maxTotalBytes { throw BackupRejected(.tooLarge) }
            do {
                try FileManager.default.copyItem(at: source, to: copy)
            } catch {
                throw BackupRejected(.unreadable)
            }
            let staged = try SafeUnzip.extract(copy, to: work.appendingPathComponent("inhalt"))
            return try ImportPlanner(store: store, reviews: reviews, sanitize: AttachmentImporter.sanitize).plan(staged, now: Date())
        }.value
    }

    static func apply(_ plan: ImportPlan, _ library: EntryLibrary) async throws -> ImportResult {
        let store = library.store
        let reviews = library.reviews
        let safety = store.root.appendingPathComponent("sicherungen", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: plan.staging.deletingLastPathComponent()) }
        return try await Task.detached(priority: .userInitiated) {
            try ImportApplier(store: store, reviews: reviews, safetyDir: safety).apply(plan)
        }.value
    }

    static func discard(_ plan: ImportPlan) {
        try? FileManager.default.removeItem(at: plan.staging.deletingLastPathComponent())
    }
}
