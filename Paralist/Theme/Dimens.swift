// Zusammenhang: Theme/Palette.swift, Theme/CalendarDimens.swift (Kalendermaße), ParalistWidgets/EntryWidgetView.swift (WidgetDimens), Shell/*, Pages/*, Entries/EntryRow.swift, Theme/ChatDimens.swift (ChatDimens, MascotDimens), Pages/Briefing* (BriefingDimens)
import SwiftUI

enum Dimens {
    static let pageEdge: CGFloat = 16
    static let titleEdge: CGFloat = 20
    static let titleTop: CGFloat = 20
    static let titleBottom: CGFloat = 24
    static let entryInset: CGFloat = 16
    static let entryTitleTop: CGFloat = 14
    static let entryMetaGap: CGFloat = 6
    static let rowLogo: CGFloat = 12
    static let rowLogoRadius: CGFloat = 3
    static let rowLogoGap: CGFloat = 4
    static let entryMetaBottom: CGFloat = 14
    static let entryTitleVeilLead: CGFloat = 120
    static let entrySheetRadius: CGFloat = 28
    static let entryGrabberWidth: CGFloat = 36
    static let entryGrabberHeight: CGFloat = 5
    static let entryGrabberTop: CGFloat = 8
    static let entryActionTop: CGFloat = 20
    static let entryActionCircle: CGFloat = 56
    static let entryActionWidth: CGFloat = 96
    static let entryActionIcon: CGFloat = 20
    static let entryPlaceTop: CGFloat = 16
    static let entryPlaceInset: CGFloat = 32
    static let canvasOpenCircle: CGFloat = 32
    static let canvasOpenHit: CGFloat = 44
    static let canvasHeadHeight: CGFloat = 48
    static let entryToggleHeight: CGFloat = 56
    static let reminderNoteChip: CGFloat = 28
    static let reminderNoteIndent: CGFloat = 30
    static let reminderRowPad: CGFloat = 14
    static let entryTextEmpty: CGFloat = 72
    static let entryTitleFade: CGFloat = 48
    static let canvasCardRadius: CGFloat = 20
    static let canvasCardGap: CGFloat = 12
    static let canvasCardPad: CGFloat = 16
    static let canvasCardStroke: CGFloat = 1
    static let entryTextBox: CGFloat = 160
    static let entryRowEdge: CGFloat = 20
    static let entryBarHeight: CGFloat = 48
    static let touchTarget: CGFloat = 48
    static let markerHit: CGFloat = 36
    static let iconSize: CGFloat = 24
    static let sheetRadius: CGFloat = 28
    static let composerHeight: CGFloat = 176
    static let cardRadius: CGFloat = 20
    static let listRadius: CGFloat = 16
    static let tileRadius: CGFloat = 14
    static let tileGap: CGFloat = 8
    static let tileTintAlpha: Double = 0.14
    static let kindIcon: CGFloat = 20
    static let levelRing: CGFloat = 36
    static let searchHeight: CGFloat = 40
    static let createIconSize: CGFloat = 30
    static let dayCell: CGFloat = 40
    static let weekLabelWidth: CGFloat = 48
    static let weekPill: CGFloat = 40
    static let weekPillMin: CGFloat = 76
    static let mediaRatio: CGFloat = 16 / 9
    static let coverEmblem: CGFloat = 64
    static let coverLogo: CGFloat = 96
    static let coverLogoSmall: CGFloat = 44
    static let coverLogoCorner: CGFloat = 22
    static let coverLogoSharp: CGFloat = 120
    static let canvasRunout: CGFloat = 2000
    static let coverRatioTolerance: CGFloat = 0.05
    static let coverHintDot: CGFloat = 9
    static let coverHintBox: CGFloat = 56
    static let coverHintCircle: CGFloat = 36
    static let coverHintEdge: CGFloat = 16
    static let coverHintLift: CGFloat = 12
    static let coverAnchor: CGFloat = 3 / 7
    static let coverTitleLines = 5
    static let coverFadeLead: CGFloat = 56
    static let coverPlay: CGFloat = 48
    static let coverPlayIcon: CGFloat = 20
    static let coverRowInset: CGFloat = 24
    static let coverTopFade: CGFloat = 160
    static let coverVeilTail: CGFloat = 8
    static let coverVeilShade: Double = 0.55
    static let spotifyCompact: CGFloat = 152
    static let spotifyTall: CGFloat = 352
    static let edgeNotchWidth: CGFloat = 64
    static let edgeNotchHeight: CGFloat = 280
    static let edgeNotchCurve: CGFloat = 96
    static let edgeShadow: Double = 0.16
    static let edgeShift: CGFloat = 2
    static let edgePeek: CGFloat = 12
    static let caretGap: CGFloat = 28
    static let entryTextFade: CGFloat = 96
    static let edgePeekHit: CGFloat = 32
    static let swipeBackStart: CGFloat = 16
    static let swipeBackShare: CGFloat = 0.35
    static let swipeBackEdge: CGFloat = 24
    static let edgeEndGap: CGFloat = 16
    static let edgePickerLift: CGFloat = 24
    static let edgePickerBottom: CGFloat = 72
    static let edgeTuckScroll: CGFloat = 8
    static let settingsMaxWidth: CGFloat = 640
    static let swipeThreshold: CGFloat = 80
    static let searchOpenSwipe: CGFloat = 200
    static let searchDimDark: Double = 0.2
    static let searchDimLight: Double = 0.05
    static let tabBarClearance: CGFloat = 64
    static let navBarClearance: CGFloat = 56
    static let headerHeight: CGFloat = 56
    static let statusFade: CGFloat = 70
    static let collapseStep: CGFloat = 4
    static let collapseJump: CGFloat = 200
    static let collapseSlack: CGFloat = 24
}

enum ComposerDimens {
    static let rowGap: CGFloat = 16
    static let control: CGFloat = 36
    static let attach: CGFloat = 40
    static let pillHeight: CGFloat = 36
    static let edge: CGFloat = 16
    static let chipGap: CGFloat = 10
    static let button: CGFloat = 36
    static let inset: CGFloat = 8
    static let radius: CGFloat = button / 2 + inset
    static let textInset: CGFloat = 16
    static let tool: CGFloat = 40
    static let tile: CGFloat = 48
    static let tileRadius: CGFloat = 14
    static let tileClose: CGFloat = 22
    static let dateGap: CGFloat = 12
    static let dateIconGap: CGFloat = 8
    static let dateSpanGap: CGFloat = 4
    static let dateRow: CGFloat = 40
    static let dateDivider: CGFloat = 20
    static let dateClear: CGFloat = 20
    static let tileCloseInset: CGFloat = tileRadius - tileClose / 2
    static let tileInset: CGFloat = radius - tileRadius
    static let dimDark: Double = 0.35
    static let dimLight: Double = 0.08
    static let dictationGap: CGFloat = 12
    static let dictationFont: CGFloat = 22
    static let dictationButton: CGFloat = 44
    static let counterGap: CGFloat = 4
    static let counterTail = 15
}

enum OverviewDimens {
    static let tileGap: CGFloat = 12
    static let tileEdge: CGFloat = 16
    static let tileHeight: CGFloat = 112
    static let tilePadding: CGFloat = 12
    static let tileRadius: CGFloat = 18
    static let tileIconGap: CGFloat = 10
    static let tileCountGap: CGFloat = 6
    static let tilesToList: CGFloat = 24
    static let panelEdge: CGFloat = 0
    static let panelRadius: CGFloat = 26
    static let tabHeight: CGFloat = 36
    static let tabsHeight: CGFloat = 44
    static let tabsEdge: CGFloat = 16
    static let viewButton: CGFloat = 36
    static let tabDot: CGFloat = 4
    static let tabDotGap: CGFloat = 3
    static let viewIcon: CGFloat = 20
    static let rowEdgeRadius: CGFloat = 4
    static let rowGap: CGFloat = 2
    static let headMinHeight: CGFloat = 56
    static let chooserHeight: CGFloat = 40
    static let headHeight: CGFloat = 48
    static let chooserRadius: CGFloat = 20
    static let zoneMinHeight: CGFloat = 56
    static let pinnedFade: CGFloat = 24
    static let pinnedCover: CGFloat = 400
}

enum TaskDimens {
    static let folderLead: CGFloat = 48
    static let folderTrail: CGFloat = 46
    static let pinPeek: CGFloat = 32
    static let stageTop: CGFloat = 16
    static let folderHeight: CGFloat = 212
    static let folderRadius: CGFloat = 26
    static let folderTabWidth: CGFloat = 0.42
    static let folderTabHeight: CGFloat = 16
    static let flapTabTop: CGFloat = 0.22
    static let flapTop: CGFloat = 0.36
    static let flapTabWidth: CGFloat = 0.38
    static let flapRadius: CGFloat = 24
    static let flapPad: CGFloat = 16
    static let sheetFrontGap: CGFloat = 8
    static let sheetBackInset: CGFloat = 14
    static let sheetFrontInset: CGFloat = 10
    static let sheetRadius: CGFloat = 18
    static let countSize: CGFloat = 26
    static let restHeight: CGFloat = 176
    static let restPeek: CGFloat = 36
    static let swipeTrigger: CGFloat = 60
    static let iconCircle: CGFloat = 36
    static let toggleHeight: CGFloat = 38
    static let toggleKnob: CGFloat = 28
    static let pinRadius: CGFloat = 26
    static let pinPad: CGFloat = 16
    static let pinGlyph: CGFloat = 44
    static let pillHeight: CGFloat = 38
    static let stageBottom: CGFloat = 22
    static let pulseScale: CGFloat = 1.9
    static let pulseSeconds: Double = 1.6
    static let hintEdge: CGFloat = 32
    static let hintShare: CGFloat = 0.5
    static let groupRowBottom: CGFloat = 2
}

enum SwipeDimens {
    static let hold: Double = 0.25
    static let trigger: CGFloat = 88
    static let limit: CGFloat = 140
    static let edge: CGFloat = 24
    static let idleFill: Double = 0.55
    static let slop: CGFloat = 10
    static let backZone: CGFloat = 72
}

enum Motion {
    static let short = Animation.easeOut(duration: 0.15)
    static let drawer = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.3)
    static let drawerDim = Animation.easeOut(duration: 0.25).delay(0.28)
    static let page = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.28)
    static let bars = Animation.easeInOut(duration: 0.22)
    static let create = Animation.spring(duration: 0.4, bounce: 0.14)
    static let dock = Animation.spring(duration: 0.42, bounce: 0.18)
    static let fall = Animation.spring(duration: 0.55, bounce: 0.35)
    static let focusDelay = Duration.milliseconds(450)
    static let menuSettle = Duration.milliseconds(120)
}

enum CreateDimens {
    static let panelTop: CGFloat = 64
    static let panelEdge: CGFloat = 8
    static let panelBottom: CGFloat = 8
    static let panelRadius: CGFloat = 42
    static let sheetOpacity: Double = 0.7
    static let homeIndicator: CGFloat = 30
    static let tileWidth: CGFloat = 104
    static let tileHeight: CGFloat = 96
    static let tileRadius: CGFloat = 28
    static let tileGap: CGFloat = 10
    static let closeDrag: CGFloat = 90
    static let dimDark: Double = 0.62
    static let dimLight: Double = 0.4
}

enum MenuDimens {
    static let updateDot: CGFloat = 7
    static let navRow: CGFloat = 52
    static let navMore: CGFloat = 44
    static let navNumber: CGFloat = 20
    static let infoTap: CGFloat = 28
    static let glowSize: CGFloat = 360
    static let glowVisible: CGFloat = 0.25
    static let glowBlur: CGFloat = 18
    static let glowOpacity: Double = 0.95
    static let glowSeconds: Double = 1.8
    static let peek: CGFloat = 56
    static let dividerEdge: CGFloat = 16
    static let contentRadius: CGFloat = 40
    static let closeDrag: CGFloat = 70
    static let closeFling: CGFloat = 200
    static let dragStart: CGFloat = 10
    static let axisRatio: CGFloat = 1.5
    static let tapLock: TimeInterval = 0.4
    static let dimDark: Double = 0.5
    static let dimLight: Double = 0.25
    static let shadow: CGFloat = 24
    static let ribPeriod: CGFloat = 14
    static let ribBlur: CGFloat = 6
    static let ribZoom: CGFloat = 1.04
    static let textShadow: Double = 0.35
}

enum TabBarDimens {
    static let height: CGFloat = 62
    static let compact: CGFloat = 52
    static let gap: CGFloat = 10
    static let edge: CGFloat = 20
    static let clearance: CGFloat = 22
    static let dip: CGFloat = 12
    static let rest: CGFloat = 8
    static let icon: CGFloat = 22
    static let assetIcon: CGFloat = 26
    static let label: CGFloat = 10
    static let inset: CGFloat = 4
    static let slot: CGFloat = 88
    static let bareSlot: CGFloat = 76
    static let searchPill: CGFloat = 38
    static let searchPillIcon: CGFloat = 14
    static let searchPillText: CGFloat = 16
    static let searchPillEdge: CGFloat = 16
    static let tools: CGFloat = 56
    static let pulseRing: CGFloat = 44
    static let pulseScale: CGFloat = 1.35
    static let pulseSeconds: Double = 1.4
}

enum PageBarDimens {
    static let height: CGFloat = 52
    static let top: CGFloat = 8
    static let field: CGFloat = 48
    static let scrollDelay = 120
    static let searchRoom: CGFloat = 720
}

enum WidgetDimens {
    static let stage: CGFloat = 4 / 7
    static let veilFade: CGFloat = 0.1
    static let veilOpacity: Double = 0.86
    static let veilBottomOpacity: Double = 0.94
    static let emblem: CGFloat = 38
    static let emblemDrop: CGFloat = 1 / 8
    static let emblemShadow: Double = 0.18
    static let emblemShadowRadius: CGFloat = 8
    static let circularIcon: CGFloat = 22
    static let inlineIcon: CGFloat = 13
    static let lineGap: CGFloat = 2
}

enum MediaDimens {
    static let gap: CGFloat = 3
    static let edge: CGFloat = 3
    static let radius: CGFloat = 4
    static let barButton: CGFloat = 56
}

enum InfoDimens {
    static let edge: CGFloat = 16
    static let tileHeight: CGFloat = 64
    static let tileRadius: CGFloat = 14
    static let tileGap: CGFloat = 10
    static let sectionGap: CGFloat = 32
    static let rowHeight: CGFloat = 52
    static let rowIcon: CGFloat = 18
    static let tileTint: Double = 0.18
    static let sourcePad: CGFloat = 16
    static let copyPad: CGFloat = 14
    static let copyHeight: CGFloat = 36
}

enum EmptyDimens {
    static let emblem: CGFloat = 80
    static let glyph: CGFloat = 32
    static let fade: Double = 0.3
    static let info: CGFloat = 32
    static let infoGlyph: CGFloat = 15
    static let infoShift: CGFloat = 6
    static let popoverWidth: CGFloat = 280
}

enum BriefingDimens {
    static let coverHeight: CGFloat = 120
    static let grabberWidth: CGFloat = 36
    static let grabberHeight: CGFloat = 5
    static let grabberTop: CGFloat = 10
    static let tile: CGFloat = 60
    static let tileSmall: CGFloat = 44
    static let tileRadius: CGFloat = 15
    static let tileIcon: CGFloat = 26
    static let sheetStart: CGFloat = 400
    static let badgeHeight: CGFloat = 30
    static let edge: CGFloat = 24
    static let sectionGap: CGFloat = 36
    static let rowHeight: CGFloat = 52
    static let rowIcon: CGFloat = 20
    static let headerIcon: CGFloat = 22
    static let chipHeight: CGFloat = 34
    static let barHeight: CGFloat = 64
    static let barGap: CGFloat = 12
    static let barEdge: CGFloat = 16
    static let barFade: CGFloat = 48
    static let ticks = 15
    static let tickGap: CGFloat = 7
    static let tickShort: CGFloat = 6
    static let tickLong: CGFloat = 12
}
