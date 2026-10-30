// Zusammenhang: Entries/TypeLook.swift, Entries/EntrySubtitle.swift, Pages/OverviewPage.swift, Pages/ListPage.swift, Pages/TasksPage.swift, Entries/InlineAdd.swift, Search/SearchView.swift
import ParalistCore
import SwiftUI

struct RowMetrics {
    var inset: CGFloat = 12
    var glyph: CGFloat = 48
    var icon: CGFloat = 22
    var minHeight: CGFloat = 52
    var gap: CGFloat = 8

    var trailing: CGFloat { inset + (glyph - icon) / 2 }

    static let card = RowMetrics(inset: 16, glyph: 40, icon: 20, minHeight: 56, gap: 12)
}

struct EntryRow: View {
    @Environment(AppModel.self) private var model
    let entry: Entry
    var metrics = RowMetrics()
    var statusLook = false
    var dimmed = false
    var subtitle: String?
    var showsType = true
    var onToggleDone: (() -> Void)?
    var onOpen: () -> Void

    var body: some View {
        let look = TypeLook.inList(entry)
        HStack(spacing: metrics.gap) {
            glyph(look)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.title.isEmpty ? L.s("list_untitled") : entry.title)
                    .font(Typo.bodyLarge)
                    .foregroundStyle(dimmed ? Palette.muted : entry.isDone ? Palette.onSurfaceVariant : Palette.onSurface)
                    .strikethrough(entry.isDone)
                    .lineLimit(1)
                meta.font(Typo.bodySmall).foregroundStyle(Palette.subtle).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if entry.pinned { marker(AppIcons.pin.filled, label: "tool_pin") { $0.pinned = false } }
            if entry.favorite { marker(AppIcons.favorite.filled, label: "tool_favorite") { $0.favorite = false } }
        }
        .padding(.leading, metrics.inset)
        .padding(.trailing, metrics.trailing)
        .padding(.vertical, 4)
        .frame(minHeight: metrics.minHeight)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var meta: some View {
        if let subtitle {
            Text(subtitle)
        } else {
            let caption = EntryCaption.of(entry, showsType: showsType && onToggleDone == nil)
            CaptionLine(caption: caption, text: EntrySubtitle.text(entry, typeLabel: EntrySubtitle.label(caption)))
        }
    }

    @ViewBuilder
    private func glyph(_ look: TypeLook) -> some View {
        if dimmed {
            Image(systemName: statusLook ? StatusLook.of(entry.status).icon : look.icon.outlined)
                .font(.system(size: statusLook ? 22 : metrics.icon))
                .foregroundStyle(Palette.outline)
                .frame(width: metrics.glyph, height: metrics.glyph)
        } else if let onToggleDone {
            Button(action: onToggleDone) {
                Image(systemName: statusLook ? StatusLook.of(entry.status).icon : (entry.isDone ? look.icon.filled : AppIcons.circle))
                    .font(.system(size: 22))
                    .foregroundStyle(statusLook ? StatusLook.of(entry.status).color : (entry.isDone ? Palette.done : look.color))
                    .frame(width: metrics.glyph, height: metrics.glyph)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: entry.isDone) { _, now in now }
            .accessibilityLabel(L.s(entry.isDone ? "task_mark_open" : "task_mark_done"))
        } else {
            GlyphIcon(look.icon.outlined, size: metrics.icon)
                .foregroundStyle(look.color)
                .frame(width: metrics.glyph, height: metrics.glyph)
        }
    }

    private func marker(_ name: String, label: String, clear: @escaping (inout Entry) -> Void) -> some View {
        Button {
            model.update(entry.id) { var e = $0; clear(&e); return e }
        } label: {
            Image(systemName: name).font(.system(size: 13)).foregroundStyle(Palette.outline)
                .frame(width: Dimens.markerHit, height: Dimens.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, -(Dimens.markerHit - 13) / 2 + 3)
        .accessibilityLabel(L.s(label))
    }
}

struct QuickAddRow: View {
    var icon = AppIcons.addCircle
    let label: String
    var metrics = RowMetrics()
    var fullWidth = true
    var pulse = false
    let action: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: metrics.gap) {
                    GlyphIcon(icon, size: metrics.icon).frame(width: metrics.glyph, height: min(metrics.glyph, metrics.minHeight))
                        .foregroundStyle(Palette.addPlaceholder)
                        .overlay { if pulse { HintPulse(size: TabBarDimens.pulseRing) } }
                    Text(label).font(Typo.bodyLarge).foregroundStyle(Palette.addPlaceholder)
                    if fullWidth { Spacer(minLength: 0) }
                }
                .padding(.leading, metrics.inset)
                .padding(.trailing, 8)
                .frame(minHeight: metrics.minHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if !fullWidth { Spacer(minLength: 0) }
        }
    }
}
