// Zusammenhang: Resources/Localizable.xcstrings, App/AppPrefs.swift (language), App/ParalistApp.swift, alle Views, ParalistShare/*, ParalistWidgets/*
import Foundation
import ParalistCore

enum L {
    nonisolated(unsafe) private(set) static var bundle: Bundle = .main
    nonisolated(unsafe) private(set) static var locale: Locale = .current

    static func apply(_ language: AppLanguage) {
        let folder = language == .chinese ? "zh-Hans" : language.tag
        bundle = lproj(folder) ?? .main
        locale = Locale(identifier: folder)
    }

    private static func lproj(_ folder: String) -> Bundle? {
        Bundle.main.path(forResource: folder, ofType: "lproj").flatMap(Bundle.init(path:))
    }

    static func s(_ key: String) -> String {
        let value = bundle.localizedString(forKey: key, value: nil, table: nil)
        guard value == key, let source = Bundle.main.developmentLocalization.flatMap(lproj) else { return value }
        return source.localizedString(forKey: key, value: nil, table: nil)
    }

    static func f(_ key: String, _ args: CVarArg...) -> String {
        String(format: s(key), locale: locale, arguments: args)
    }

    static func date(_ day: Day, _ style: Date.FormatStyle.DateStyle = .abbreviated) -> String {
        day.at(hour: 12, in: .current).formatted(Date.FormatStyle(date: style, time: .omitted, locale: locale))
    }

    static func dateOnly(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale))
    }

    static func dateTime(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: locale))
    }

    static func time(_ date: Date) -> String { WeekGrid.timeLabel(date, zone: .current) }

    static var systemLanguage: AppLanguage {
        AppLanguage.fromTag(Locale.current.language.languageCode?.identifier) ?? .english
    }
}
