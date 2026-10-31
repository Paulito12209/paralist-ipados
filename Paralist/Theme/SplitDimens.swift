// Zusammenhang: ParalistCore Library/SplitLayout.swift, Shell/SplitRootView.swift, Shell/SplitTopBar.swift, Shell/SplitPanes.swift, Shell/SplitParts.swift, Shell/Router.swift (tabBarFloor, tabBarReserve), Shell/RootView.swift (NoticeBar), Shell/CreateOverlay.swift, docs/ipad.md
import SwiftUI

enum SplitDimens {
    static let minList: CGFloat = 320
    static let minDetail: CGFloat = 440
    static let minPane: CGFloat = 320
    static let margin: CGFloat = 10
    static let gap: CGFloat = 10
    static let radius: CGFloat = 28
    static let topBar: CGFloat = 52
    static let button: CGFloat = 44
    static let pillItem: CGFloat = 38
    static let pillInset: CGFloat = 4
    static let pillEdge: CGFloat = 14
    static let rail: CGFloat = 72
    static let railGap: CGFloat = 8
    static let divider: CGFloat = 10
    static let handle: CGFloat = 4
    static let handleHeight: CGFloat = 44
    static let fab: CGFloat = 56
    static let fabInset: CGFloat = 16
    static let floor: CGFloat = fab + 2 * fabInset
    static let createWidth: CGFloat = 560
    static let emptyGap: CGFloat = 16
}
