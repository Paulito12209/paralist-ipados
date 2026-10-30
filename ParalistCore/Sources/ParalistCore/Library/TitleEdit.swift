// Zusammenhang: Paralist/Entry/EntryTitle.swift, Paralist/Entry/EntryPage.swift, Tests/ParalistCoreTests/TitleEditTests.swift
import Foundation

public enum TitleEdit {
    public static func forEditing(_ title: String) -> String {
        title.isEmpty || title.last?.isWhitespace == true ? title : title + " "
    }

    public static func clean(_ raw: String) -> String {
        String(raw.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces).prefix(Limits.maxTitleChars))
    }
}
