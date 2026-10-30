// Zusammenhang: Chat/ChatThread.swift, Chat/ChatStore.swift (deleteAttachments), Paralist/Chat/ChatModel.swift, Paralist/App/AppModel.swift (attachmentsInUse), docs/chat.md
import Foundation

public enum ChatAttachments {
    public static func orphans(_ hashes: [String], threads: [ChatThread], inUse: Set<String>) -> [String] {
        let used = inUse.union(threads.flatMap(\.attachments))
        var seen = Set<String>()
        return hashes.filter { Attachment.isValidHash($0) && !used.contains($0) && seen.insert($0).inserted }
    }
}
