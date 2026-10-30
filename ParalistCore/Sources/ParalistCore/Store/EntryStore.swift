// Zusammenhang: Markdown/EntryCodec.swift, Store/TrashRules.swift, Store/Ids.swift, Library/EntryLibrary.swift
import Foundation

public struct BrokenFile: Hashable, Sendable {
    public let name: String
    public let reason: String
}

public struct StoreScan: Sendable {
    public let entries: [Entry]
    public let broken: [BrokenFile]
}

public final class EntryStore: @unchecked Sendable {
    public let root: URL
    public let entriesDir: URL
    public let attachmentsDir: URL
    public let trashDir: URL
    private let clock: Clock
    private let files = FileManager.default

    public init(root: URL, clock: Clock = SystemClock()) {
        self.root = root
        self.clock = clock
        entriesDir = root.appendingPathComponent("eintraege", isDirectory: true)
        attachmentsDir = root.appendingPathComponent("anhaenge", isDirectory: true)
        trashDir = root.appendingPathComponent("papierkorb", isDirectory: true)
        for dir in [entriesDir, attachmentsDir, trashDir] {
            try? files.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    public func fileFor(_ id: String) throws -> URL {
        guard EntryCodec.isValidId(id) else { throw EntryParseError("id ungültig") }
        return entriesDir.appendingPathComponent("\(id).md")
    }

    public func attachmentFile(_ hash: String) -> URL? {
        guard Attachment.isValidHash(hash) else { return nil }
        let url = attachmentsDir.appendingPathComponent(hash)
        return files.fileExists(atPath: url.path) ? url : nil
    }

    @discardableResult
    public func save(_ entry: Entry) throws -> Entry {
        var e = entry
        e.updated = clock.now()
        return try write(e)
    }

    @discardableResult
    public func write(_ entry: Entry) throws -> Entry {
        let data = Data(EntryCodec.encode(entry).utf8)
        try data.write(to: fileFor(entry.id), options: .atomic)
        return entry
    }

    public func load(_ id: String) -> Entry? {
        guard EntryCodec.isValidId(id) else { return nil }
        return try? read(fileFor(id))
    }

    public func exists(_ id: String) -> Bool { (try? fileFor(id)).map { files.fileExists(atPath: $0.path) } ?? false }

    @discardableResult
    public func moveToTrash(_ id: String) -> Bool {
        guard exists(id) else { return false }
        let target = trashDir.appendingPathComponent(TrashRules.fileName(clock.now(), id: id))
        try? files.removeItem(at: target)
        return (try? files.moveItem(at: fileFor(id), to: target)) != nil
    }

    public func restoreFromTrash(_ id: String) -> Entry? {
        guard EntryCodec.isValidId(id) else { return nil }
        let candidates = trashFiles(id).sorted { $0.lastPathComponent < $1.lastPathComponent }
        guard let newest = candidates.last else { return nil }
        try? files.removeItem(at: fileFor(id))
        guard (try? files.moveItem(at: newest, to: fileFor(id))) != nil else { return nil }
        trashFiles(id).forEach { try? files.removeItem(at: $0) }
        return load(id)
    }

    public func listTrash() -> [TrashedEntry] {
        var newest: [String: TrashedEntry] = [:]
        for file in list(trashDir) {
            guard let (deletedAt, id) = TrashRules.parseFileName(file.lastPathComponent),
                  let entry = try? read(file), entry.id == id else { continue }
            if let existing = newest[id], existing.deletedAt >= deletedAt { continue }
            newest[id] = TrashedEntry(entry: entry, deletedAt: deletedAt)
        }
        return newest.values.sorted { $0.deletedAt > $1.deletedAt }
    }

    @discardableResult
    public func deleteFromTrash(_ id: String) -> Bool {
        guard EntryCodec.isValidId(id) else { return false }
        let found = trashFiles(id)
        found.forEach { try? files.removeItem(at: $0) }
        return !found.isEmpty
    }

    public func purgeTrash(now: Date? = nil) -> [String] {
        let at = now ?? clock.now()
        var gone: [String] = []
        for file in list(trashDir) {
            guard let (deletedAt, id) = TrashRules.parseFileName(file.lastPathComponent),
                  TrashRules.isExpired(deletedAt, now: at) else { continue }
            try? files.removeItem(at: file)
            if !gone.contains(id) { gone.append(id) }
        }
        return gone
    }

    public func scan() -> StoreScan {
        var entries: [Entry] = []
        var broken: [BrokenFile] = []
        let candidates = list(entriesDir).filter { $0.pathExtension == "md" && !$0.lastPathComponent.hasPrefix(".") }
        for file in candidates.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            do {
                let entry = try read(file)
                if "\(entry.id).md" != file.lastPathComponent { throw EntryParseError("id passt nicht zum Dateinamen") }
                entries.append(entry)
            } catch let error as EntryParseError {
                broken.append(BrokenFile(name: file.lastPathComponent, reason: error.message))
            } catch {
                broken.append(BrokenFile(name: file.lastPathComponent, reason: "unlesbar"))
            }
        }
        return StoreScan(entries: entries, broken: broken)
    }

    private func trashFiles(_ id: String) -> [URL] {
        list(trashDir).filter { TrashRules.parseFileName($0.lastPathComponent)?.1 == id }
    }

    private func list(_ dir: URL) -> [URL] {
        let items = (try? files.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isRegularFileKey])) ?? []
        return items.filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
    }

    private func read(_ file: URL) throws -> Entry {
        let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        if size > Limits.maxFileBytes { throw EntryParseError("Datei zu groß") }
        guard let data = try? Data(contentsOf: file), let text = String(data: data, encoding: .utf8) else {
            throw EntryParseError("unlesbar")
        }
        return try EntryCodec.decode(text, now: clock.now())
    }
}
