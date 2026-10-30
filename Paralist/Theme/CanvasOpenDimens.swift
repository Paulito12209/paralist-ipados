// Zusammenhang: Theme/Dimens.swift (canvasCardRadius, canvasOpen*, canvasHeadHeight, entryTextBox, TaskDimens.pinRadius, pinPad), Entry/EntryActions.swift (CanvasCardHead, CanvasOpenButton), Entry/EntryBodyEditor.swift, Pages/FolderStage.swift (PinnedCardShell), docs/detailseite.md
import SwiftUI

extension Dimens {
    static let canvasHeadTop: CGFloat = 2
    static let canvasHeadTrailing: CGFloat = 6
    static let canvasOpenEdge: CGFloat = (TaskDimens.pinPad * canvasCardRadius / TaskDimens.pinRadius).rounded()
    static let canvasOpenShift = CGSize(
        width: canvasHeadTrailing + (canvasOpenHit - canvasOpenCircle) / 2 - canvasOpenEdge,
        height: canvasOpenEdge - canvasHeadTop - (canvasHeadHeight - canvasOpenHit) / 2 - (canvasOpenHit - canvasOpenCircle) / 2
    )
    static let entryTextViewMin: CGFloat = 240
}
