// Zusammenhang: Chat/ChatViewSheet.swift, Pages/SectionStage.swift (ChatStage), Shell/PageBar.swift, Pages/TasksPage.swift (TaskGroupRow), Pages/FilterTabRow.swift, Search/SearchView.swift (Chat-Bereich der Suche), Entries/EntryRow.swift (QuickAddRow), Shell/SectionChrome.swift (tabRoot, SectionHeader), Chat/ChatModel.swift, Chat/ChatThreadPage.swift, Shell/Router.swift (topRequest, Route.chats, Route.chat), Pages/MenuPage.swift, Pages/ListPage.swift (plainRow), Pages/OverviewParts.swift (PanelCard), Entries/EntryRow.swift (RowMetrics), ParalistCore Chat/ChatList.swift, Chat/ChatView.swift, Shell/AppTabBar.swift (HintPulse), ParalistCore Chat/ChatHint.swift
import ParalistCore
import SwiftUI

struct ChatListPage: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var query = ""
    @State private var searching = false
    @State private var filter = ChatFilter.all
    @State private var showsPin = false
    @State private var customizing = false
    @State private var renaming: String?
    @State private var name = ""
    @State private var deleting: String?
    @Environment(\.tabRoot) private var tabRoot
    @State private var position = ScrollPosition()

    var body: some View {
        let chats = model.chats
        let view = model.prefs.chatView
        let filters = ChatFilter.visible(in: chats.threads)
        let active = filters.contains(filter) ? filter : .all
        let shown = view.arrange(chats.threads, filter: active, query: query)
        ScrollViewReader { proxy in
            List {
                if tabRoot, !router.split { SectionHeader().plainRow() }
                PageTitle(text: L.s("chat_title"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Dimens.titleEdge)
                    .plainRow()
                ChatStage(count: shown.count, pinned: ChatViewSetting.pinned(shown), showsPin: $showsPin) { router.open(.chat($0.id)) }
                    .padding(.top, TaskDimens.stageTop)
                    .plainRow()
                TaskGroupRow(label: L.s(ListPage.sortLabel(view.sort)), count: showsPin ? shown.count : 0) { customizing = true }
                    .id(PageSearchAnchor.id)
                    .clearRow()
                if filters.count > 1 {
                    FilterTabRow(items: filters, selection: Binding(get: { active }, set: { filter = $0 }), label: { L.s($0.label) }) { tab in
                        chats.threads.filter(tab.matches).count
                    }
                    .plainRow()
                }
                if chats.threads.isEmpty {
                    EmptyHint(icon: AppIcons.chat.outlined, info: L.s("chat_empty_list"), action: start).plainRow()
                } else if shown.isEmpty {
                    Text(L.s("chat_no_results")).font(Typo.bodyMedium).foregroundStyle(Palette.subtle)
                        .padding(.horizontal, Dimens.titleEdge)
                        .plainRow()
                }
                ForEach(shown) { thread in
                    PanelCard {
                        ChatRow(thread: thread) { router.open(.chat(thread.id)) }
                    }
                    .plainRow()
                        .contextMenu {
                            pinButton(thread)
                            Button { beginRename(thread) } label: { Label(L.s("chat_rename"), systemImage: AppIcons.rename) }
                            Button(role: .destructive) { deleting = thread.id } label: { Label(L.s("chat_delete"), systemImage: AppIcons.delete) }
                        }
                        .swipeActions(edge: .trailing) {
                            Button { deleting = thread.id } label: { Label(L.s("chat_delete"), systemImage: AppIcons.delete) }
                                .tint(Palette.error)
                        }
                        .swipeActions(edge: .leading) {
                            pinButton(thread).tint(Palette.level)
                            Button { beginRename(thread) } label: { Label(L.s("chat_rename"), systemImage: AppIcons.rename) }
                                .tint(Palette.primary)
                        }
                }
                if !chats.threads.isEmpty && query.isEmpty {
                    PanelCard { QuickAddRow(label: L.s("chat_new"), metrics: .card, pulse: chatHint.newChatPulse, action: start) }.plainRow()
                }
                PageSearchRoom(active: searching).plainRow()
            }
            .pageSearchScroll(proxy, active: searching, query: query)
            .scrollPosition($position)
            .onChange(of: router.topRequest(.chats)) { _, _ in
                guard tabRoot else { return }
                withAnimation(Motion.dock) { position.scrollTo(edge: .top) }
            }
        }
        .listStyle(.plain)
        .scrollEdgeEffectHidden(tabRoot, for: .top)
        .scrollDismissesKeyboard(.interactively)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle(L.s("chat_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: .title)
        .sheet(isPresented: $customizing) { ChatViewSheet() }
        .pageBar(!tabRoot, search: PageSearch(query: $query, active: $searching), prompt: L.s("chat_search")) {
            PageBarAdd(label: L.s("chat_new"), action: start)
                .overlay { if chatHint.newChatPulse { HintPulse(size: TabBarDimens.pulseRing) } }
        }
        .alert(L.s("chat_rename"), isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField(L.s("chat_new"), text: $name)
            Button(L.s("dialog_save")) { if let renaming { chats.rename(renaming, name) } }
            Button(L.s("dialog_cancel"), role: .cancel) {}
        }
        .alert(L.s("chat_delete"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button(L.s("entry_delete"), role: .destructive) { if let deleting { chats.delete(deleting) } }
            Button(L.s("dialog_cancel"), role: .cancel) {}
        } message: { Text(L.s("chat_delete_confirm")) }
    }

    private var chatHint: ChatHintPlacement {
        ChatHint.placement(seen: model.prefs.chatHintSeen, chatsInTabBar: model.prefs.tabOrder.shows(AppTab.chats.key))
    }

    private func start() { router.open(.chat(model.chats.newId())) }

    private func pinButton(_ thread: ChatThread) -> some View {
        Button { withAnimation(Motion.short) { model.chats.setPinned(thread.id, !thread.pinned) } } label: {
            Label(L.s(thread.pinned ? "entry_unpin" : "tool_pin"), systemImage: thread.pinned ? AppIcons.pin.filled : AppIcons.pin.outlined)
        }
    }

    private func beginRename(_ thread: ChatThread) {
        name = thread.title
        renaming = thread.id
    }
}

struct ChatRow: View {
    let thread: ChatThread
    let onOpen: () -> Void
    private let metrics = RowMetrics.card

    var body: some View {
        HStack(spacing: metrics.gap) {
            GlyphIcon(AppIcons.chat.outlined, size: metrics.icon)
                .foregroundStyle(Palette.level)
                .frame(width: metrics.glyph, height: metrics.glyph)
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(thread.title.isEmpty ? L.s("chat_new") : thread.title)
                        .font(Typo.bodyLarge).foregroundStyle(Palette.onSurface).lineLimit(1)
                    if thread.pinned {
                        Image(systemName: AppIcons.pin.filled).font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.subtle)
                            .accessibilityLabel(L.s("list_pinned"))
                    }
                    Spacer(minLength: 0)
                    Text(Self.stamp(thread.updated)).font(Typo.bodySmall).foregroundStyle(Palette.subtle)
                }
                let preview = ChatPreview.of(thread).isEmpty && thread.last?.attachment != nil ? L.s("chat_image") : ChatPreview.of(thread)
                if !preview.isEmpty {
                    Text(preview).font(Typo.bodySmall).foregroundStyle(Palette.subtle).lineLimit(1)
                }
            }
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

    static func stamp(_ date: Date) -> String {
        let day = Day.of(date, in: .current)
        return day == Day.of(Date(), in: .current) ? L.time(date) : L.date(day)
    }
}
