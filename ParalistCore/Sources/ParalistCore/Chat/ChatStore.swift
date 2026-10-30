// Zusammenhang: Chat/ChatThread.swift, Chat/ChatCodec.swift, Backup/BackupWriter.swift, Backup/ImportApplier.swift, Store/Ids.swift, Paralist/Chat/ChatModel.swift
import Foundation

public final class ChatStore: @unchecked Sendable {
    public static let folder = "chats"
    public let dir: URL
    public let attachmentsDir: URL
    private let ids: IdGenerator
    private let clock: Clock
    private let files = FileManager.default

    public init(root: URL, ids: IdGenerator = SecureIds(), clock: Clock = SystemClock()) {
        dir = Self.directory(root: root)
        attachmentsDir = root.appendingPathComponent("anhaenge", isDirectory: true)
        self.ids = ids
        self.clock = clock
    }

    public static func directory(root: URL) -> URL { root.appendingPathComponent(folder, isDirectory: true) }

    public func newId() -> String { ids.next() }

    public func now() -> Date { clock.now() }

    public func draft(_ id: String) -> ChatThread { ChatThread(id: id, created: clock.now()) }

    public func message(_ role: ChatRole, _ text: String, attachment: String? = nil) -> ChatMessage {
        ChatMessage(id: ids.next(), role: role, text: text, at: clock.now(), attachment: attachment)
    }

    public func attachmentFile(_ hash: String) -> URL? {
        guard Attachment.isValidHash(hash) else { return nil }
        let url = attachmentsDir.appendingPathComponent(hash)
        return files.fileExists(atPath: url.path) ? url : nil
    }

    @discardableResult
    public func deleteAttachments(_ hashes: [String]) -> Int {
        hashes.compactMap(attachmentFile).filter { (try? files.removeItem(at: $0)) != nil }.count
    }

    public func fileFor(_ id: String) throws -> URL {
        guard EntryCodec.isValidId(id) else { throw EntryParseError("id ungültig") }
        return dir.appendingPathComponent("\(id).json")
    }

    public func all() -> [ChatThread] {
        let items = (try? files.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isRegularFileKey])) ?? []
        return items
            .filter { $0.pathExtension == "json" && !$0.lastPathComponent.hasPrefix(".") }
            .compactMap { file in
                guard let thread = try? read(file), "\(thread.id).json" == file.lastPathComponent else { return nil }
                return thread
            }
            .sorted(by: ChatList.newestFirst)
    }

    public func load(_ id: String) -> ChatThread? {
        guard let file = try? fileFor(id) else { return nil }
        return try? read(file)
    }

    @discardableResult
    public func write(_ thread: ChatThread) throws -> ChatThread {
        try files.createDirectory(at: dir, withIntermediateDirectories: true)
        try ChatCodec.encode(thread).write(to: fileFor(thread.id), options: .atomic)
        return thread
    }

    @discardableResult
    public func rename(_ id: String, _ title: String) throws -> ChatThread? {
        guard var thread = load(id) else { return nil }
        thread.rename(title)
        thread.updated = clock.now()
        return try write(thread)
    }

    @discardableResult
    public func delete(_ id: String) -> Bool {
        guard let file = try? fileFor(id), files.fileExists(atPath: file.path) else { return false }
        return (try? files.removeItem(at: file)) != nil
    }

    private func read(_ file: URL) throws -> ChatThread {
        let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        if size > ChatCodec.maxFileBytes { throw EntryParseError("Datei zu groß") }
        return try ChatCodec.decode(try Data(contentsOf: file))
    }
}
