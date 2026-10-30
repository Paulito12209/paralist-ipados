// Zusammenhang: Library/ComposerDraft.swift, Library/EntryLibrary.swift (fileEntry), Links/SharedFile.swift (title), Model/Entry.swift (Attachment), Paralist/Entry/EntryBlocks.swift (saveAttachmentEntry), Paralist/Composer/ComposerSheet.swift, Tests/ParalistCoreTests/AttachmentEntryTests.swift
import Foundation

public enum AttachmentEntry {
    public enum Plan: Equatable, Sendable {
        case none
        case link(String)
        case create
    }

    public static func holds(_ type: EntryType) -> Bool { type == .file || type == .document }

    public static func keeps(_ type: EntryType) -> Bool { type != .document }

    public static func owner(_ entry: Entry) -> Entry {
        guard !keeps(entry.type) else { return entry }
        var e = entry
        e.attachment = nil
        return e
    }

    public static func existing(_ hash: String, in entries: [Entry], excluding id: String? = nil) -> Entry? {
        entries
            .filter { $0.id != id && holds($0.type) && $0.attachment?.hash == hash }
            .min { ($0.archived ? 1 : 0, $0.created, $0.id) < ($1.archived ? 1 : 0, $1.created, $1.id) }
    }

    public static func plan(_ attachment: Attachment?, for entry: Entry, in entries: [Entry]) -> Plan {
        guard let attachment, entry.type != .file else { return .none }
        if let found = existing(attachment.hash, in: entries.filter { $0.type == .file }, excluding: entry.id) {
            return entry.links.contains(found.id) || found.places.contains(entry.id) ? .none : .link(found.id)
        }
        return .create
    }

    public static func make(_ base: Entry, _ attachment: Attachment, for entry: Entry) -> Entry {
        var e = base
        e.type = .file
        e.status = nil
        e.title = SharedFile.title(attachment.name)
        e.attachment = attachment
        e.places = [entry.id]
        e.links = []
        return e
    }
}
