// Zusammenhang: Theme/Palette.swift, Resources/Fonts/DMSans.ttf, Info.plist (UIAppFonts), ParalistShare/*, ParalistWidgets/*
import SwiftUI

enum Typo {
    private static let family = "DMSans-9ptRegular"

    static func uiFont(_ size: CGFloat) -> UIFont {
        UIFont(name: family, size: size) ?? .systemFont(ofSize: size)
    }

    static func dm(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        Font.custom(family, size: size, relativeTo: style).weight(weight)
    }

    static let displaySmall = dm(36, .regular, relativeTo: .largeTitle)
    static let headlineLarge = dm(32, .semibold, relativeTo: .largeTitle)
    static let pageTitle = dm(24, .medium, relativeTo: .largeTitle)
    static let headlineMedium = dm(28, .semibold, relativeTo: .largeTitle)
    static let headlineSmall = dm(24, .semibold, relativeTo: .title)
    static let entryTitle = dm(20, .semibold, relativeTo: .title3)
    static let entryMeta = dm(13, .regular, relativeTo: .footnote)
    static let entryMetaMore = dm(13, .semibold, relativeTo: .footnote)
    static let infoValue = dm(20, .semibold, relativeTo: .title3)
    static let titleLarge = dm(22, .medium, relativeTo: .title2)
    static let titleMedium = dm(16, .medium, relativeTo: .headline)
    static let titleSmall = dm(14, .medium, relativeTo: .subheadline)
    static let bodyLarge = dm(16, .regular, relativeTo: .body)
    static let bodyMedium = dm(14, .regular, relativeTo: .callout)
    static let bodySmall = dm(12, .regular, relativeTo: .footnote)
    static let labelLarge = dm(14, .medium, relativeTo: .callout)
    static let labelMedium = dm(12, .medium, relativeTo: .caption)
    static let labelSmall = dm(11, .medium, relativeTo: .caption2)
}
