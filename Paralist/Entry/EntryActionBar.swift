// Zusammenhang: Entry/EntryCanvasPanel.swift (Detail-Ansicht), Entry/CoverChrome.swift (Coveransicht), Entry/EntryMoreMenu.swift, Entry/EntryToolbar.swift, Entry/EntryPage.swift (canvas, settle), Shell/SplitParts.swift, Theme/EntryActionDimens.swift, docs/detailseite.md
import ParalistCore
import SwiftUI

struct EntryViewPill: View {
    let key: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(L.s(key))
                .font(Typo.dm(Dimens.entryActionPillFont, .semibold))
                .foregroundStyle(Palette.onSurface)
                .lineLimit(1)
                .padding(.horizontal, Dimens.entryActionPillPad)
                .frame(height: Dimens.entryActionPillHeight)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
    }
}

struct EntryActionBar: View {
    let entry: Entry
    let onCover: () -> Void
    let onDelete: () -> Void
    @Binding var sheet: EntrySheet?
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        HStack(spacing: Dimens.entryActionBarGap) {
            EntryViewPill(key: "ipad_to_cover", action: onCover)
            Spacer(minLength: 0)
            EntryFavoriteButton(entry: entry, model: model)
                .font(.system(size: Dimens.entryBarActionIcon))
                .frame(width: Dimens.entryBarActionCircle, height: Dimens.entryBarActionCircle)
                .glassEffect(.regular.interactive(), in: Circle())
            EntryMoreMenu(entry: entry, model: model, router: router, sheet: $sheet, onDelete: onDelete)
                .font(.system(size: Dimens.entryBarActionIcon))
                .frame(width: Dimens.entryBarActionCircle, height: Dimens.entryBarActionCircle)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .padding(.horizontal, Dimens.entryInset)
        .padding(.bottom, Dimens.entryActionBarBottom)
    }
}
