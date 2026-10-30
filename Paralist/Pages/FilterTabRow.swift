// Zusammenhang: Pages/MediaPage.swift (MediaFilterRow), Pages/ListPage.swift, Pages/OverviewParts.swift (OverviewTabs-Punkt), ParalistCore Library/ListFilter.swift
import ParalistCore
import SwiftUI

struct FilterTabRow<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let label: (Item) -> String
    let count: (Item) -> Int
    @Namespace private var dot

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(items, id: \.self) { item in
                        let active = selection == item
                        Button {
                            withAnimation(Motion.short) { selection = item }
                        } label: {
                            HStack(spacing: 6) {
                                Text(label(item))
                                if count(item) > 0 { Text("\(count(item))").foregroundStyle(Palette.muted) }
                            }
                            .font(Typo.dm(16, .medium))
                            .foregroundStyle(active ? Palette.level : Palette.subtle)
                            .overlay(alignment: .bottom) {
                                if active {
                                    Circle().fill(Palette.level)
                                        .frame(width: OverviewDimens.tabDot, height: OverviewDimens.tabDot)
                                        .offset(y: OverviewDimens.tabDot + OverviewDimens.tabDotGap)
                                        .matchedGeometryEffect(id: "dot", in: dot)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: OverviewDimens.tabHeight)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(active ? .isSelected : [])
                        .id(item)
                    }
                }
                .padding(.horizontal, Dimens.titleEdge - 14)
            }
            .onChange(of: selection) { _, now in
                withAnimation(Motion.short) { reader.scrollTo(now, anchor: .center) }
            }
            .onAppear { reader.scrollTo(selection, anchor: .center) }
        }
        .padding(.bottom, 8)
    }
}

extension ListFilter {
    var label: String {
        switch self {
        case .all: return L.s("list_all")
        case .areas: return L.s("tile_areas")
        case .projects: return L.s("tile_projects")
        case .tasks: return L.s("list_tasks")
        case .events: return L.s("list_events")
        case .notes: return L.s("list_notes")
        case .documents: return L.s("list_documents")
        case .bookmarks: return L.s("list_bookmarks")
        case .images: return L.s("media_filter_images")
        case .videos: return L.s("media_filter_videos")
        case .audios: return L.s("media_filter_audios")
        case .files: return L.s("list_files")
        case .flashcards: return L.s("list_flashcards")
        }
    }
}
