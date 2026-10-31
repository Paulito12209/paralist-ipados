// Zusammenhang: Theme/Dimens.swift, Theme/Typography.swift, Entries/TypeLook.swift, App/ParalistApp.swift, ParalistShare/*, ParalistWidgets/*
import SwiftUI
import UIKit

enum Palette {
    static let primary = tone(0x0B57D0, 0xC3C8DC)
    static let toggleOn = tone(0x0B57D0, 0x3B8EEA)
    static let onPrimary = tone(0xFFFFFF, 0x1D2030)
    static let primaryContainer = tone(0xD3E3FD, 0x5C6070)
    static let onPrimaryContainer = tone(0x041E49, 0xECEEF8)
    static let secondaryContainer = tone(0xC2E7FF, 0x4A4E5A)
    static let onSecondaryContainer = tone(0x001D35, 0xE3E3E8)
    static let tertiary = tone(0x146C2E, 0x6DD58C)
    static let tertiaryContainer = tone(0xC4EED0, 0x0F5223)
    static let error = tone(0xB3261C, 0xF2B8B5)
    static let onError = tone(0xFFFFFF, 0x601410)
    static let background = tone(0xF3F3F6, 0x121316)
    static let window = tone(0xDFE2E8, 0x000000)
    static let padTabActive = tone(0xD9E2EF, 0x3A4456)
    static let surface = tone(0xFFFFFF, 0x121316)
    static let onSurface = tone(0x1F1F1F, 0xE3E3E3)
    static let onSurfaceVariant = tone(0x444746, 0xC4C7C5)
    static let surfaceLowest = tone(0xFFFFFF, 0x0D0E10)
    static let surfaceLow = tone(0xF6F8FC, 0x191A1E)
    static let surfaceContainer = tone(0xEEF2F9, 0x1E1F23)
    static let addPlaceholder = tone(0xA8B8D6, 0x3C414D)
    static let tile = tone(0xFFFFFF, 0x1E1F23)
    static let menuTop = tone(0xF3F3F6, 0x2A2B30)
    static let menuPanel = tone(0xFFFFFF, 0x191A1E)
    static let menuTile = tone(0xFFFFFF, 0x0D0E10)
    static let surfaceHigh = tone(0xE5EAF2, 0x2A2B30)
    static let composerCard = tone(0xFFFFFF, 0x2A2B30)
    static let composerButton = tone(0xEEF0F4, 0x3A3C42)
    static let success = tone(0x2E8B57, 0x5CC98A)
    static let composerPill = tone(0xFFFFFF, 0x181A1E)
    static let surfaceHighest = tone(0xDDE3EC, 0x34363C)
    static let outline = tone(0x747775, 0x8E918F)
    static let outlineVariant = tone(0xC4C7C5, 0x3C3F44)
    static let scrim = Color.black

    static let muted = tone(0x747775, 0x8A8F99)
    static let calendarPage = background
    static let calendarGrid = tone(0xFFFFFF, 0x1C1D21)
    static let calendarLine = tone(0xC9CBD1, 0x3C3F44)
    static let calendarPill = tone(0xFFFFFF, 0x24252A)
    static let calendarBadge = tone(0xE1E3E9, 0x34363C)
    static let subtle = tone(0x5F6368, 0x9A9DA4)
    static let menuDot = tone(0xE5383B, 0xE5383B)
    static let ribStops: [Gradient.Stop] = [
        .init(color: .white.opacity(0.16), location: 0),
        .init(color: .white.opacity(0.04), location: 5 / 14),
        .init(color: .black.opacity(0.10), location: 11 / 14),
        .init(color: .black.opacity(0.22), location: 1),
    ]
    static let ribShade: [Gradient.Stop] = [
        .init(color: .black.opacity(0.2), location: 0),
        .init(color: .black.opacity(0.45), location: 0.6),
        .init(color: .black.opacity(0.45), location: 1),
    ]
    static let favorite = tone(0xF5B400, 0xF5B400)
    static let briefing = tone(0x4E8A6F, 0x9CC8B2)
    static let openTask = tone(0xB0B4BA, 0x6F737A)
    static let inProgress = tone(0x0B8CE9, 0x4DA3FF)
    static let done = tone(0x1E8E3E, 0x5BC97A)
    static let onOpenTask = tone(0x1F1F1F, 0xFFFFFF)
    static let onInProgress = tone(0xFFFFFF, 0x0B1A2E)
    static let onDone = tone(0xFFFFFF, 0x0B2414)
    static let reviewed = tone(0xB45309, 0xF2A33A)
    static let level = tone(0x4D72AD, 0xA9C9FF)
    static let onLevel = tone(0xFFFFFF, 0x101418)
    static let filterActive = tone(0x0B57D0, 0x4DA3FF)
    static let tabTextActive = tone(0x1F1F1F, 0xFFFFFF)
    static let tabActive = tone(0xE6E8EB, 0x181A1E)
    static let sheetTop = tone(0xF4F6FB, 0x24262C)
    static let sheetBottom = tone(0xBBCDF2, 0x24407F)
    static let sheetGlow = tone(0xFFFFFF, 0xC8D4F0)
    static let chipFill = tone(0xFFFFFF, 0x0E1014)
    static let edgePicker = tone(0xFFFFFF, 0x0A0B0D)
    static let edgeGlow = tone(0x7FA6E8, 0x3D5F99)
    static let mascotTop = tone(0x8FB4F0, 0x6D8FD0)
    static let mascotBottom = tone(0x4F82DA, 0x3D5F99)
    static let mascotEye = tone(0xFFFFFF, 0xF2F4FA)
    static let mascotCard = tone(0xFFFFFF, 0xE6E8EF)
    static let mascotRocket = tone(0xE8EBF2, 0xD3D7E3)
    static let mascotRocketTip = tone(0xE5484D, 0xF2686C)
    static let coverInk = fixed(0x0A0C16)
    static let coverCore = fixed(0x05060C)
    static let coverLight = fixed(0xFAFBFF)
    static let coverSilver = fixed(0xAEB6D8)
    static let briefingInk = fixed(0x101114)
    static let briefingTile = fixed(0x2C2D31)
    static let briefingGlowWarm = fixed(0x8A4A3A)
    static let briefingGlowCool = fixed(0x3A5A8A)
    static let briefingGlowGreen = fixed(0x4E8A6F)
    static let briefingRead = fixed(0x6DD58C)
    static let cardTop = tone(0xFFFFFF, 0x2A2B30)
    static let cardBottom = tone(0xF8FAFD, 0x222327)
    static let cardStroke = tone(0xDDE3EC, 0x34363C)
    static let entryGrabber = tone(0xC4C8CF, 0x4A4D54)
    static let taskBackTop = tone(0xC4E2FA, 0x0F3D66)
    static let taskBackBottom = tone(0x94C9F3, 0x061A2E)
    static let taskFlapBase = tone(0xEBF5FD, 0x03101C)
    static let taskGlowDeep = tone(0x3FA2EE, 0x0B8CE9)
    static let taskGlowMid = tone(0x7DC0F4, 0x0A6FBC)
    static let taskGlowSoft = tone(0xB3DAF8, 0x4AA9F0)
    static let taskGlowIndigo = tone(0x2B84D6, 0x0B4F8A)
    static let taskInk = tone(0x06355C, 0xFFFFFF)
    static let taskInkMuted = tone(0x4F6E8A, 0xA6B8CA)
    static let taskSheet = tone(0xFFFFFF, 0xE6F2FD)
    static let taskKnobOn = tone(0x0B8CE9, 0x0B8CE9)
    static let taskKnobOff = tone(0x8A97A6, 0x7A8591)
    static let mediaPhoto = fixed(0x34C759)
    static let mediaVideo = fixed(0xFF3B30)
    static let mediaSpotify = fixed(0x1DB954)
    static let mediaAudio = fixed(0xFF9500)
    static let mediaDocument = fixed(0x007AFF)
    static let mediaPdf = fixed(0xE5322D)
    static let mediaMarkdown = fixed(0x2F6FEB)

    static func fixed(_ hex: UInt32) -> Color { Color(uiColor: uiColor(hex)) }

    private static func tone(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in uiColor(traits.userInterfaceStyle == .dark ? dark : light) })
    }

    private static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
