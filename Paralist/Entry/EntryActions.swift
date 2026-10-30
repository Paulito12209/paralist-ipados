// Zusammenhang: Entry/EntryCanvasPanel.swift, Entry/EntryBlocks.swift (LinkAddMenu, EntryTextBox, EntryRelations), Entry/EntryBodyEditor.swift, Entry/EntryParts.swift (EntrySheets), Entry/CanvasCard.swift, Entries/TypeLook.swift (StatusLook, TagKindLook), Theme/Dimens.swift, Theme/CanvasOpenDimens.swift (canvasOpenShift)
import ParalistCore
import SwiftUI

struct EntryActionButtons: View {
    let entry: Entry
    @Binding var sheet: EntrySheet?
    let onCreateLinked: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if entry.type.hasStatus {
                let status = StatusLook.of(entry.status, for: entry.type)
                Button { sheet = .status } label: { ActionCircle(icon: status.icon, tint: status.color, label: L.s(status.label)) }
                    .accessibilityHint(L.s("status_title"))
            } else if entry.type == .tag {
                let kind = TagKindLook.of(entry.tagKind)
                Button { sheet = .tagKind } label: { ActionCircle(icon: kind.icon.outlined, tint: TypeLook.of(.tag).color, label: L.s(kind.label)) }
                    .accessibilityHint(L.s("tag_kind_title"))
            }
            LinkAddMenu(onCreate: onCreateLinked, onLink: { sheet = .links }) {
                ActionCircle(icon: AppIcons.link, label: L.s("entry_link"))
            }
            .accessibilityLabel(L.s("entry_link_add"))
            Button { sheet = .reminders } label: {
                let active = entry.hasUpcomingReminder(now: Date())
                ActionCircle(icon: active ? AppIcons.bell.filled : AppIcons.bell.outlined, tint: active ? Palette.level : nil, label: L.s("reminder_bell"))
            }
            .accessibilityLabel(L.s("entry_reminder_add"))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

struct ActionCircle: View {
    let icon: String
    var tint: Color?
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            GlyphIcon(icon, size: Dimens.entryActionIcon, weight: .medium)
                .foregroundStyle(tint ?? Palette.onSurface)
                .frame(width: Dimens.entryActionCircle, height: Dimens.entryActionCircle)
                .background(Palette.surfaceHigh, in: Circle())
                .overlay(Circle().strokeBorder(Palette.cardStroke, lineWidth: Dimens.canvasCardStroke))
            Text(label).font(Typo.entryMeta).foregroundStyle(Palette.onSurface).lineLimit(1).minimumScaleFactor(0.85)
        }
        .frame(width: Dimens.entryActionWidth)
        .contentShape(Rectangle())
    }
}

struct CanvasCardHead<Trailing: View>: View {
    let icon: String
    let title: String
    var count: Int?
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 8) {
            GlyphIcon(icon, size: 16).foregroundStyle(Palette.onSurfaceVariant)
            Text(title).font(Typo.titleSmall).foregroundStyle(Palette.onSurface)
            if let count { Text("\(count)").font(Typo.titleSmall).foregroundStyle(Palette.muted) }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.leading, Dimens.canvasCardPad)
        .padding(.trailing, Dimens.canvasHeadTrailing)
        .frame(minHeight: Dimens.canvasHeadHeight)
        .padding(.top, Dimens.canvasHeadTop)
    }
}

struct CanvasOpenButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: AppIcons.openCanvas)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.onSurface)
                .frame(width: Dimens.canvasOpenCircle, height: Dimens.canvasOpenCircle)
                .glassEffect(.regular.interactive(), in: Circle())
                .frame(width: Dimens.canvasOpenHit, height: Dimens.canvasOpenHit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(Dimens.canvasOpenShift)
        .accessibilityLabel(L.s("entry_canvas_open"))
    }
}

struct EntryTextToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                GlyphIcon(AppIcons.text, size: 18).foregroundStyle(Palette.onSurfaceVariant)
                Text(label).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
            }
        }
        .tint(Palette.level)
        .padding(.horizontal, Dimens.canvasCardPad)
        .frame(minHeight: Dimens.entryToggleHeight)
        .canvasCard()
        .padding(.horizontal, Dimens.entryInset)
        .padding(.top, Dimens.canvasCardGap)
    }
}
