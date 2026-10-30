// Zusammenhang: Markdown/FrontMatter.swift, Markdown/EntryCodec.swift, Store/EntryStore.swift
import Foundation

public enum Limits {
    public static let maxFileBytes = 1_048_576
    public static let maxFrontMatterChars = 16_384
    public static let maxKeys = 64
    public static let maxListItems = 500
    public static let maxTitleChars = 500
    public static let maxInputTitleChars = 200
    public static let maxUrlChars = 2_048
    public static let maxIdChars = 64
    public static let maxNameChars = 255
    public static let minYear = 2000
    public static let maxYearAhead = 100
}
