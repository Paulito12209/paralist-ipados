// Zusammenhang: Shell/Router.swift (Route, open), Shell/RouterSplit.swift (openSplit), Shell/SplitRootView.swift (rechte Seite), Shell/TabSlotMenu.swift (TabSlotLook), Entries/TypeLook.swift (ListTitles, TypeLook), Theme/CategoryDimens.swift, Icons/GlyphIcon.swift
import ParalistCore
import SwiftUI

struct CategoryTile: Identifiable {
    let route: Route
    let title: String
    let icon: String
    let color: Color
    var id: Route { route }
}

struct CategoryPanel: View {
    @Environment(Router.self) private var router

    private var tiles: [CategoryTile] {
        [
            list(.projects, TypeLook.of(.project).color),
            list(.areas, TypeLook.of(.area).color),
            list(.resources, Palette.fixed(0x10B981)),
            list(.archive, Palette.fixed(0x6B7280)),
            list(.inbox, Palette.fixed(0x4F82DA)),
            tab(.tasks, TypeLook.of(.task).color),
            tab(.calendar, TypeLook.of(.event).color),
            list(.notes, TypeLook.of(.note).color),
            list(.bookmarks, TypeLook.of(.bookmark).color),
            list(.files, TypeLook.of(.document).color),
            tab(.media, Palette.mediaAudio),
            tab(.flashcards, TypeLook.of(.flashcard).color),
            tab(.chats, Palette.fixed(0x14B8A6)),
            CategoryTile(route: .trash, title: L.s("trash_title"), icon: AppIcons.delete, color: Palette.fixed(0xB3261C)),
            CategoryTile(route: .progress, title: L.s("page_progress"), icon: AppIcons.stats, color: Palette.fixed(0x4D72AD)),
            CategoryTile(route: .settings, title: L.s("page_settings"), icon: AppIcons.settings, color: Palette.fixed(0x5F6368)),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CategoryDimens.spacing) {
                Text(L.s("ipad_categories"))
                    .font(Typo.headlineLarge)
                    .foregroundStyle(Palette.onSurface)
                    .padding(.bottom, CategoryDimens.titleBottom)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: CategoryDimens.spacing), count: 2),
                    spacing: CategoryDimens.spacing
                ) {
                    ForEach(tiles) { item in
                        Button { router.open(item.route) } label: { tile(item) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(CategoryDimens.padding)
        }
        .background(Palette.background)
    }

    private func tile(_ item: CategoryTile) -> some View {
        let fill = item.color.mix(with: .black, by: CategoryDimens.darken)
        return RoundedRectangle(cornerRadius: CategoryDimens.radius, style: .continuous)
            .fill(fill)
            .frame(height: CategoryDimens.tileHeight)
            .overlay(alignment: .topTrailing) {
                GlyphIcon(item.icon, size: CategoryDimens.decorSize, weight: .semibold)
                    .foregroundStyle(.white.opacity(CategoryDimens.decorOpacity))
                    .rotationEffect(.degrees(CategoryDimens.decorAngle))
                    .offset(x: CategoryDimens.decorOffsetX, y: CategoryDimens.decorOffsetY)
            }
            .overlay(alignment: .bottomLeading) {
                Text(item.title)
                    .font(Typo.dm(18, .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.leading)
                    .padding(CategoryDimens.labelInset)
            }
            .clipShape(RoundedRectangle(cornerRadius: CategoryDimens.radius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: CategoryDimens.radius, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(item.title)
            .accessibilityAddTraits(.isButton)
    }

    private func list(_ kind: ListKind, _ color: Color) -> CategoryTile {
        CategoryTile(route: .list(kind), title: ListTitles.of(kind), icon: ListTitles.icon(kind), color: color)
    }

    private func tab(_ tab: AppTab, _ color: Color) -> CategoryTile {
        CategoryTile(route: tab.route, title: TabSlotLook.title(tab), icon: TabSlotLook.icon(tab).outlined, color: color)
    }
}
