// Zusammenhang: Chat/ChatThreadPage.swift, Chat/ChatModel.swift (setLinked), Entry/LinkSheet.swift (gleicher Aufbau), Components/Chips.swift, ParalistCore Chat/ChatList.swift (pickable)
import ParalistCore
import SwiftUI

struct ChatLinkSheet: View {
    let threadId: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var kind: ListKind?
    @State private var query = ""

    var body: some View {
        let linked = model.chats.thread(threadId)?.links ?? []
        let items = ChatList.pickable(model.all, kind: kind, query: query, linked: linked)
        NavigationStack {
            List {
                if items.isEmpty {
                    Text(L.s("empty_kind_all")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                }
                ForEach(items) { entry in
                    let item = ChoiceItem.entry(entry)
                    let on = linked.contains(entry.id)
                    Button { model.chats.setLinked(threadId, entry.id, !on) } label: {
                        HStack(spacing: 16) {
                            GlyphIcon(item.icon, size: 20).foregroundStyle(item.tint).frame(width: 28)
                            Text(item.label).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface).lineLimit(1)
                            Spacer()
                            if on { Image(systemName: AppIcons.check).foregroundStyle(Palette.primary) }
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top, spacing: 0) { tabs }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: L.s("chat_link_search"))
            .navigationTitle(L.s("chat_link_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: AppIcons.check) }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var tabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil, icon: AppIcons.suggestions, label: L.s("chat_link_all"))
                ForEach(ChatList.pickKinds) { kind in
                    chip(kind, icon: ListTitles.icon(kind), label: ListTitles.of(kind))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func chip(_ value: ListKind?, icon: String, label: String) -> some View {
        Button { kind = value } label: {
            ComposerChip(icon: icon, label: label, selected: kind == value, caret: false)
        }
    }
}
