// Zusammenhang: Theme/Palette.swift (task*, level), Entries/TypeLook.swift (Kategoriefarben), Pages/TaskFolder.swift, Pages/FolderStage.swift, Pages/SectionStage.swift, Pages/TaskStage.swift, ParalistCore Library/ListKind.swift
import ParalistCore
import SwiftUI
import UIKit

struct FolderTone {
    let backTop: Color
    let backBottom: Color
    let flapBase: Color
    let glowDeep: Color
    let glowMid: Color
    let glowSoft: Color
    let glowIndigo: Color
    let ink: Color
    let inkMuted: Color
    let sheet: Color
    let knobOn: Color
    let knobOff: Color

    static let task = FolderTone(backTop: Palette.taskBackTop, backBottom: Palette.taskBackBottom, flapBase: Palette.taskFlapBase,
                                 glowDeep: Palette.taskGlowDeep, glowMid: Palette.taskGlowMid, glowSoft: Palette.taskGlowSoft,
                                 glowIndigo: Palette.taskGlowIndigo, ink: Palette.taskInk, inkMuted: Palette.taskInkMuted,
                                 sheet: Palette.taskSheet, knobOn: Palette.taskKnobOn, knobOff: Palette.taskKnobOff)

    static let chats = of(Palette.level)

    static func of(_ kind: ListKind) -> FolderTone {
        switch kind {
        case .tasks: return .task
        case .projects: return of(TypeLook.of(.project).color)
        case .areas: return of(TypeLook.of(.area).color)
        case .resources, .files: return of(TypeLook.of(.file).color)
        case .notes: return of(TypeLook.of(.note).color)
        case .events: return of(TypeLook.of(.event).color)
        case .bookmarks: return of(TypeLook.of(.bookmark).color)
        case .tags: return of(TypeLook.of(.tag).color)
        case .flashcards: return of(TypeLook.of(.flashcard).color)
        case .marked, .favorites: return of(Palette.favorite)
        case .archive: return of(Palette.openTask)
        case .inbox, .pinned, .all: return of(Palette.filterActive)
        }
    }

    static func of(_ base: Color) -> FolderTone {
        let white = UIColor.white, black = UIColor.black
        return FolderTone(
            backTop: mix(base, light: (white, 0.76), dark: (black, 0.58)),
            backBottom: mix(base, light: (white, 0.55), dark: (black, 0.8)),
            flapBase: mix(base, light: (white, 0.92), dark: (black, 0.9)),
            glowDeep: mix(base, light: (white, 0.2), dark: (white, 0)),
            glowMid: mix(base, light: (white, 0.45), dark: (black, 0.2)),
            glowSoft: mix(base, light: (white, 0.7), dark: (white, 0.25)),
            glowIndigo: mix(base, light: (black, 0.15), dark: (black, 0.45)),
            ink: mix(base, light: (black, 0.62), dark: (white, 1)),
            inkMuted: mix(base, light: (UIColor.gray, 0.6), dark: (white, 0.62)),
            sheet: mix(base, light: (white, 1), dark: (white, 0.9)),
            knobOn: base,
            knobOff: Palette.taskKnobOff
        )
    }

    private static func mix(_ base: Color, light: (UIColor, CGFloat), dark: (UIColor, CGFloat)) -> Color {
        let source = UIColor(base)
        return Color(uiColor: UIColor { traits in
            let (target, amount) = traits.userInterfaceStyle == .dark ? dark : light
            return blend(source.resolvedColor(with: traits), target.resolvedColor(with: traits), amount)
        })
    }

    private static func blend(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor {
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t, alpha: 1)
    }
}

extension EnvironmentValues {
    @Entry var folderTone = FolderTone.task
}
