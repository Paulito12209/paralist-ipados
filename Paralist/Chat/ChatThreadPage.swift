// Zusammenhang: Chat/ChatModel.swift, Chat/ChatBubble.swift, Chat/ChatMentionParts.swift, Shell/Router.swift (chatSeed, leave), ParalistCore Chat/ChatMentionQuery.swift, Chat/ChatImageParts.swift (ChatImages, Quick Look), Chat/ChatDraftCard.swift, Chat/ChatInputBar.swift, Chat/ChatMascotStage.swift, Chat/ChatThreadParts.swift, Chat/ChatLinkSheet.swift, Chat/ChatListPage.swift, Shell/Router.swift (Route.chat), Entry/MarkdownText.swift, ParalistCore Chat/ChatHint.swift, App/AppPrefs.swift (chatHintSeen), Shell/RouterSplit.swift (DetailPane, push(from:), leave)
import ParalistCore
import QuickLook
import SwiftUI

struct ChatThreadPage: View {
    let id: String
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.detailPane) private var pane
    @Environment(\.openURL) private var openURL
    @State private var draft = ""
    @State private var image: Attachment?
    @State private var mentions: [String] = []
    @State private var preview: URL?
    @State private var renaming = false
    @State private var name = ""
    @State private var deleting = false
    @State private var linking = false
    @FocusState private var focused: Bool
    @State private var position = ScrollPosition(edge: .bottom)

    var body: some View {
        let chats = model.chats
        let thread = chats.thread(id)
        let messages = thread?.messages ?? []
        let pending = chats.streaming[id]
        let failure = chats.failures[id]
        let intro = ChatHint.placement(seen: model.prefs.chatHintSeen, chatsInTabBar: false, threadEmpty: messages.isEmpty && pending == nil).intro
        let reply = messages.last { $0.role == .assistant }
        let topics = LaunchOptions.mascotTopics ?? MascotScenes.topics(draftKinds: reply?.drafts.map(\.kind) ?? [],
                                         entryTypes: ((reply?.entries ?? []) + (thread?.links ?? [])).compactMap { model.entry($0)?.type })
        ScrollView {
            LazyVStack(alignment: .leading, spacing: ChatDimens.messageGap) {
                if let thread, !thread.links.isEmpty {
                    ChatEntryChips(ids: thread.links, label: L.s("chat_linked"))
                }
                if messages.isEmpty && pending == nil {
                    EmptyHint(icon: AppIcons.chat.outlined, info: L.s("chat_empty_thread")).padding(.top, 40)
                    if chats.hasModel {
                        ChatSuggestions(project: model.byType(.project).first?.title) { send($0) }
                    }
                }
                ForEach(messages) { message in
                    VStack(alignment: .leading, spacing: 8) {
                        ChatBubble(role: message.role, text: message.text,
                                   image: message.attachment.flatMap { model.library.store.attachmentFile($0) },
                                   openImage: { preview = message.attachment.flatMap { ChatImages.previewURL($0, store: model.library.store) } },
                                   mentions: message.mentions, onLink: follow)
                        if message.role == .assistant {
                            ChatEntryChips(ids: message.entries)
                            ForEach(message.drafts) { ChatDraftCard(threadId: id, draft: $0) }
                        }
                    }
                }
                if let pending, !pending.isEmpty {
                    ChatBubble(role: .assistant, text: pending, onLink: follow)
                }
                ChatAvailabilityNotice(availability: chats.availability)
            }
            .padding(.horizontal, Dimens.pageEdge)
            .padding(.vertical, 12)
        }
        .scrollPosition($position)
        .defaultScrollAnchor(.bottom)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.surface)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                ChatMascotStage(failure: failure, working: pending != nil, topics: topics, intro: intro, retry: { chats.retry(id) }, dismissIntro: { model.prefs.chatHintSeen = true })
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { _ in settle() }
                if let token = ChatMentionQuery.token(in: draft) {
                    ChatMentionSuggestions(entries: ChatMentionQuery.suggestions(token, entries: model.all, exclude: mentions), skills: Set(Skills.all(in: model.all).map(\.id))) { entry in
                        draft = ChatMentionQuery.removingToken(from: draft)
                        if mentions.count < ChatMentionQuery.maxMentions { mentions.append(entry.id) }
                    }
                }
                ChatInputBar(text: $draft, image: $image, mentions: $mentions, focused: $focused,
                             thinking: Binding(get: { model.prefs.chatThinking }, set: { model.prefs.chatThinking = $0 }),
                             showsThinking: chats.supportsThinking, enabled: chats.hasModel, busy: pending != nil, send: { send(draft) }, stop: { chats.stop(id) })
            }
            .background(Palette.surface)
        }
        .onChange(of: messages.count) { settle() }
        .navigationTitle(thread.map { $0.title.isEmpty ? L.s("chat_new") : $0.title } ?? L.s("chat_new"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { linking = true } label: { Label(L.s("chat_link"), systemImage: AppIcons.copyLink) }
                    if let thread {
                        Button {
                            name = thread.title
                            renaming = true
                        } label: { Label(L.s("chat_rename"), systemImage: AppIcons.rename) }
                        Button(role: .destructive) { deleting = true } label: { Label(L.s("chat_delete"), systemImage: AppIcons.delete) }
                    }
                } label: { Image(systemName: AppIcons.more) }
                .accessibilityLabel(L.s("entry_more"))
            }
        }
        .sheet(isPresented: $linking) { ChatLinkSheet(threadId: id) }
        .quickLookPreview($preview)
        .alert(L.s("chat_rename"), isPresented: $renaming) {
            TextField(L.s("chat_new"), text: $name)
            Button(L.s("dialog_save")) { chats.rename(id, name) }
            Button(L.s("dialog_cancel"), role: .cancel) {}
        }
        .alert(L.s("chat_delete"), isPresented: $deleting) {
            Button(L.s("entry_delete"), role: .destructive) {
                chats.delete(id)
                router.leave(dismiss, pane: pane)
            }
            Button(L.s("dialog_cancel"), role: .cancel) {}
        } message: { Text(L.s("chat_delete_confirm")) }
        .onAppear {
            chats.refreshAvailability()
            if let seed = router.chatSeed {
                mentions = [seed]
                router.chatSeed = nil
                focused = true
            }
            if let text = LaunchOptions.chatText, draft.isEmpty { draft = text }
        }
        .onChange(of: focused) { settle() }
        .task {
            guard messages.isEmpty, chats.hasModel, model.prefs.chatHintSeen else { return }
            try? await Task.sleep(for: Motion.focusDelay)
            focused = true
        }
    }

    private func settle() {
        Task { @MainActor in
            try? await Task.sleep(for: Motion.menuSettle)
            withAnimation(Motion.create) { position.scrollTo(edge: .bottom) }
        }
    }

    private func send(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image != nil || !mentions.isEmpty else { return }
        model.prefs.chatHintSeen = true
        let fallback = mentions.lazy.compactMap { model.entry($0)?.title }.first { !$0.isEmpty } ?? ""
        model.chats.send(text, attachment: image?.hash, mentions: mentions, fallbackTitle: fallback, in: id)
        Task { @MainActor in
            draft = ""
            image = nil
            mentions = []
        }
    }

    private func follow(_ link: String) {
        if let url = URL(string: link) { openURL(url) }
    }
}
