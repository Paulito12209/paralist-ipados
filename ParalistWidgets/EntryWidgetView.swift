// Zusammenhang: ParalistWidgets/EntryWidget.swift, ParalistWidgets/EntryProvider.swift, Paralist/Entry/CoverArtwork.swift, Paralist/Entries/TypeLook.swift, Paralist/Icons/GlyphIcon.swift, Paralist/Theme/Dimens.swift (WidgetDimens), Paralist/Theme/Typography.swift, ParalistCore Links/IncomingLink.swift
import ParalistCore
import SwiftUI
import WidgetKit

struct EntryWidgetView: View {
    let snapshot: EntrySnapshot
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var margins

    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
    }

    var body: some View {
        content
            .containerBackground(for: .widget) { background }
    }

    @ViewBuilder
    private var background: some View {
        if isAccessory {
            Color.clear
        } else if case .ready(let entry, _) = snapshot.state {
            ZStack {
                CoverArtwork(color: TypeLook.of(entry).color)
                veil
            }
        } else {
            Palette.surface
        }
    }

    private var veil: some View {
        LinearGradient(
            stops: [
                .init(color: Palette.surface.opacity(0), location: WidgetDimens.stage - WidgetDimens.veilFade),
                .init(color: Palette.surface.opacity(WidgetDimens.veilOpacity), location: WidgetDimens.stage + WidgetDimens.veilFade),
                .init(color: Palette.surface.opacity(WidgetDimens.veilBottomOpacity), location: 1),
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    @ViewBuilder
    private var content: some View {
        switch snapshot.state {
        case .empty: hint(L.s("widget_empty"))
        case .missing: hint(L.s("widget_missing"))
        case .ready(let entry, let children): ready(entry, children).widgetURL(IncomingLink.entryURL(entry.id))
        }
    }

    @ViewBuilder
    private func hint(_ text: String) -> some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                GlyphIcon(AppIcons.info, size: WidgetDimens.circularIcon).widgetAccentable()
            }
        case .accessoryInline:
            Text(text)
        case .accessoryRectangular:
            Text(text).font(Typo.bodySmall).lineLimit(3)
        default:
            Text(text)
                .font(Typo.bodySmall)
                .foregroundStyle(Palette.onSurfaceVariant)
                .padding(margins)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func ready(_ entry: Entry, _ children: Int) -> some View {
        let look = TypeLook.of(entry)
        let icon = TypeLook.of(entry.type).icon.filled
        let kind = L.s(TypeLook.of(entry.type).label)
        let title = entry.title.isEmpty ? L.s("list_untitled") : entry.title
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                GlyphIcon(icon, size: WidgetDimens.circularIcon).widgetAccentable()
            }
        case .accessoryInline:
            Text(title)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: WidgetDimens.lineGap) {
                HStack(spacing: WidgetDimens.lineGap * 2) {
                    GlyphIcon(icon, size: WidgetDimens.inlineIcon)
                    Text(kind).font(Typo.labelMedium)
                }
                .widgetAccentable()
                Text(title).font(Typo.titleSmall).lineLimit(1).truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            cover(look, icon, kind, title, family == .systemMedium ? detail(entry, children) : nil)
        }
    }

    private func cover(_ look: TypeLook, _ icon: String, _ kind: String, _ title: String, _ detail: String?) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                GlyphIcon(icon, size: WidgetDimens.emblem, weight: .medium)
                    .foregroundStyle(look.color)
                    .shadow(color: .black.opacity(WidgetDimens.emblemShadow), radius: WidgetDimens.emblemShadowRadius, y: 3)
                    .widgetAccentable()
                    .frame(width: geo.size.width, height: geo.size.height * WidgetDimens.stage)
                    .offset(y: geo.size.height * WidgetDimens.emblemDrop)
                    .frame(maxHeight: .infinity, alignment: .top)
                VStack(alignment: .leading, spacing: WidgetDimens.lineGap) {
                    Text(kind).font(Typo.labelSmall).foregroundStyle(Palette.onSurfaceVariant).widgetAccentable()
                    Text(title).font(Typo.titleMedium).foregroundStyle(Palette.onSurface).lineLimit(1).truncationMode(.tail)
                    if let detail {
                        Text(detail).font(Typo.bodySmall).foregroundStyle(Palette.onSurfaceVariant).lineLimit(1)
                    }
                }
                .padding(.leading, margins.leading)
                .padding(.trailing, margins.trailing)
                .padding(.bottom, margins.bottom)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func detail(_ entry: Entry, _ children: Int) -> String? {
        switch entry.type {
        case .area, .project:
            return L.f("widget_links_count", children)
        case .task:
            let parts = [L.s(StatusLook.of(entry.status).label), entry.due.map { L.date($0) }].compactMap { $0 }
            return parts.joined(separator: " · ")
        case .event:
            return entry.start.map(L.dateTime) ?? entry.due.map { L.date($0) }
        case .bookmark:
            return entry.url.flatMap(LinkBrand.host)
        default:
            return entry.preview.isEmpty ? nil : entry.preview
        }
    }
}
