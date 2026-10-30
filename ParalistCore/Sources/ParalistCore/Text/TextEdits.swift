// Zusammenhang: Paralist/Entry/EntryBodyEditor.swift, Paralist/Entry/TitleKeyboardBar.swift (BodyKeyboardBar), Tests/ParalistCoreTests/TextEditsTests.swift
import Foundation

public enum TextEdits {
    public static func deleteWord(_ text: String, before offset: Int) -> (text: String, offset: Int) {
        let chars = Array(text)
        var end = min(max(offset, 0), chars.count)
        var start = end
        while start > 0, chars[start - 1].isWhitespace { start -= 1 }
        while start > 0, !chars[start - 1].isWhitespace { start -= 1 }
        if start == end { return (text, end) }
        end = min(end, chars.count)
        return (String(chars[..<start]) + String(chars[end...]), start)
    }
}

public struct EditHistory: Sendable {
    public static let limit = 100

    private var snapshots: [String] = []
    private var typing = false

    public init() {}

    public var canUndo: Bool { !snapshots.isEmpty }

    public mutating func record(from before: String, to after: String) {
        guard before != after else { return }
        let typed = after.count == before.count + 1 && after.hasPrefix(before) && after.last.map { !$0.isWhitespace } == true
        if !(typed && typing) {
            snapshots.append(before)
            if snapshots.count > Self.limit { snapshots.removeFirst() }
        }
        typing = typed
    }

    public mutating func undo() -> String? {
        typing = false
        return snapshots.popLast()
    }
}
