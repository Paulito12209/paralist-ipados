// Zusammenhang: Backup/SafeUnzip.swift, Backup/ImportApplier.swift, Backup/Checksums.swift, Links/FileKind.swift, Store/EntryStore.swift, Flashcards/ReviewLog.swift, Chat/ChatStore.swift, Chat/ChatCodec.swift
import Foundation

public struct ImportPlan: Sendable {
    public let staging: URL
    public let entriesTotal: Int
    public let toWrite: [Entry]
    public let newEntries: Int
    public let updatedEntries: Int
    public let unchangedEntries: Int
    public let broken: [BrokenFile]
    public let attachmentsTotal: Int
    public let imagesTotal: Int
    public let attachmentsPresent: Int
    public let attachmentsRejected: Int
    public let attachmentsToAdd: [(String, URL)]
    public let reviewsToWrite: [(String, [ReviewEvent])]
    public let chatsToWrite: [ChatThread]
    public let chatsRejected: Int
    public let ignoredFiles: Int

    public var hasChanges: Bool { !toWrite.isEmpty || !attachmentsToAdd.isEmpty || !reviewsToWrite.isEmpty || !chatsToWrite.isEmpty }
}

public struct ImportPlanner {
    private let store: EntryStore
    private let reviews: ReviewLog
    private let sanitize: (Data, FileKind) -> Data?

    public init(store: EntryStore, reviews: ReviewLog, sanitize: @escaping (Data, FileKind) -> Data?) {
        self.store = store
        self.reviews = reviews
        self.sanitize = sanitize
    }

    public func plan(_ staged: Staged, now: Date) throws -> ImportPlan {
        let files = FileManager.default
        let checked = staged.dir.appendingPathComponent("geprueft", isDirectory: true)
        try files.createDirectory(at: checked, withIntermediateDirectories: true)
        var hashMap: [String: String] = [:]
        var toAdd: [(String, URL)] = []
        var present = 0, rejected = 0, images = 0
        let attachmentFiles = list(staged.dir.appendingPathComponent(BackupArea.attachments.rawValue))
        for file in attachmentFiles {
            guard let data = try? Data(contentsOf: file), data.count <= FileKind.maxBytes,
                  let kind = FileKind.detectSafe(Array(data.prefix(4096))) else {
                rejected += 1
                continue
            }
            if kind.isImage { images += 1 }
            let actual = SHA256.hex(data)
            if store.attachmentFile(actual) != nil {
                present += 1
                hashMap[file.lastPathComponent] = actual
                continue
            }
            guard let bytes = kind.isImage ? sanitize(data, kind) : data else {
                rejected += 1
                continue
            }
            let finalHash = kind.isImage ? SHA256.hex(bytes) : actual
            if store.attachmentFile(finalHash) != nil {
                present += 1
                hashMap[file.lastPathComponent] = finalHash
                continue
            }
            let out = checked.appendingPathComponent(finalHash)
            if !files.fileExists(atPath: out.path) { try bytes.write(to: out) }
            if !toAdd.contains(where: { $0.0 == finalHash }) { toAdd.append((finalHash, out)) }
            hashMap[file.lastPathComponent] = finalHash
        }
        var toWrite: [Entry] = []
        var broken: [BrokenFile] = []
        var fresh = 0, updated = 0, unchanged = 0
        let entryFiles = list(staged.dir.appendingPathComponent(BackupArea.entries.rawValue))
        for file in entryFiles {
            let imported: Entry
            do {
                let data = try Data(contentsOf: file)
                if data.count > Limits.maxFileBytes { throw EntryParseError("Datei zu groß") }
                imported = try EntryCodec.decode(String(decoding: data, as: UTF8.self), now: now)
                if "\(imported.id).md" != file.lastPathComponent { throw EntryParseError("id passt nicht zum Dateinamen") }
            } catch let error as EntryParseError {
                broken.append(BrokenFile(name: file.lastPathComponent, reason: error.message))
                continue
            } catch {
                broken.append(BrokenFile(name: file.lastPathComponent, reason: "unlesbar"))
                continue
            }
            var remapped = imported
            if let attachment = imported.attachment {
                if let hash = hashMap[attachment.hash] {
                    remapped.attachment = Attachment(hash: hash, name: attachment.name, mime: attachment.mime, size: attachment.size)
                } else {
                    remapped.attachment = nil
                }
            }
            if let local = store.load(imported.id) {
                if imported.updated > local.updated {
                    toWrite.append(remapped)
                    updated += 1
                } else {
                    unchanged += 1
                }
            } else {
                toWrite.append(remapped)
                fresh += 1
            }
        }
        var reviewsToWrite: [(String, [ReviewEvent])] = []
        for file in list(staged.dir.appendingPathComponent(BackupArea.reviews.rawValue)) {
            let id = file.deletingPathExtension().lastPathComponent
            guard let data = try? Data(contentsOf: file), data.count <= ReviewLog.maxBytes else { continue }
            let incoming = ReviewLog.parse(id, String(decoding: data, as: UTF8.self), now: now)
            let existing = reviews.read(id, now: now)
            var seen = Set<String>()
            let merged = (existing + incoming).filter { seen.insert("\($0.at.timeIntervalSince1970)-\($0.rating.rawValue)").inserted }
                .sorted { $0.at < $1.at }.prefix(ReviewLog.maxEvents)
            if merged.count > existing.count { reviewsToWrite.append((id, Array(merged))) }
        }
        let chats = ChatStore(root: store.root)
        var chatsToWrite: [ChatThread] = []
        var chatsRejected = 0
        for file in list(staged.dir.appendingPathComponent(BackupArea.chats.rawValue)) {
            guard let data = try? Data(contentsOf: file), var thread = try? ChatCodec.decode(data),
                  "\(thread.id).json" == file.lastPathComponent else {
                chatsRejected += 1
                continue
            }
            if let local = chats.load(thread.id), local.updated >= thread.updated { continue }
            thread.remapAttachments { hashMap[$0] ?? (store.attachmentFile($0) != nil ? $0 : nil) }
            chatsToWrite.append(thread)
        }
        return ImportPlan(staging: staged.dir, entriesTotal: entryFiles.count, toWrite: toWrite, newEntries: fresh, updatedEntries: updated,
                          unchangedEntries: unchanged, broken: broken, attachmentsTotal: attachmentFiles.count, imagesTotal: images,
                          attachmentsPresent: present, attachmentsRejected: rejected, attachmentsToAdd: toAdd,
                          reviewsToWrite: reviewsToWrite, chatsToWrite: chatsToWrite, chatsRejected: chatsRejected,
                          ignoredFiles: staged.ignored)
    }

    private func list(_ dir: URL) -> [URL] {
        ((try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []).sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
