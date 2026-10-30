// Zusammenhang: Entry/EntryBlocks.swift (EntryTextBox, EntryRelations), Entry/EntryInfoSheet.swift, Theme/Dimens.swift, Theme/Palette.swift
import SwiftUI

struct CanvasCard: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Dimens.canvasCardRadius, style: .continuous)
        content
            .background(LinearGradient(colors: [Palette.cardTop, Palette.cardBottom], startPoint: .top, endPoint: .bottom), in: shape)
            .overlay(shape.strokeBorder(Palette.cardStroke, lineWidth: Dimens.canvasCardStroke).allowsHitTesting(false))
            .clipShape(shape)
            .contentShape(shape)
    }
}

extension View {
    func canvasCard() -> some View { modifier(CanvasCard()) }
}
