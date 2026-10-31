// Zusammenhang: ParalistCore Library/SplitLayout.swift, Shell/SplitRootView.swift, Shell/SplitTopBar.swift, Shell/SplitParts.swift, Shell/Router.swift (tabBarFloor, tabBarReserve), Shell/RootView.swift (NoticeBar), Shell/CreateOverlay.swift, docs/ipad.md
import SwiftUI

enum SplitDimens {
    static let minSide: CGFloat = 320
    static let minMain: CGFloat = 440
    static let margin: CGFloat = 10
    static let gap: CGFloat = 10
    static let radius: CGFloat = 28
    static let topBar: CGFloat = 60
    static let barInset: CGFloat = 8
    static let button: CGFloat = 44
    static let pillItem: CGFloat = 38
    static let pillInset: CGFloat = 4
    static let pillEdge: CGFloat = 16
    static let pillFont: CGFloat = 15
    static let fab: CGFloat = 56
    static let fabInset: CGFloat = 16
    static let floor: CGFloat = fab + 2 * fabInset
    static let createWidth: CGFloat = 560
}
