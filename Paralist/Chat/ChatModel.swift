// Zusammenhang: ParalistCore Chat/*.swift, Chat/ChatEngine.swift, App/AppModel.swift (chats, reload, chatSnapshot, applyChatDraft), Chat/ChatDraftCard.swift, App/DemoSeed.swift, Chat/ChatListPage.swift, Chat/ChatThreadPage.swift, Entry/EntryBlocks.swift
import Foundation
import Observation
import ParalistCore

@MainActor
@Observable
final class ChatModel {
    let store: ChatStore
    @ObservationIgnored let engine = ChatEngine()
    @ObservationIgnored var snapshot: (() -> ChatSnapshot)?
    @ObservationIgnored var apply: ((ChatDraft) -> [String]?)?
    @ObservationIgnored var thinking: (() -> ChatThinking)?
    @ObservationIgnored var attachmentsInUse: (() -> Set<String>)?
    @ObservationIgnored var applySkillName: ((String) -> Void)?
    private(set) var threads: [ChatThread] = []
    private(set) var streaming: [String: String] = [:]
    private(set) var failures: [String: ChatFailure] = [:]
    private(set) var availability: ChatAvailability = .notEligible
    private(set) var failedDrafts: Set<String> = []
    @ObservationIgnored private var tasks: [String: Task<Void, Never>] = [:]

    init(root: URL) {
        store = ChatStore(root: root)
        reload()
    }

    var hasModel: Bool { availability == .ready }

    var supportsThinking: Bool { hasModel && engine.supportsThinking }

    func reload() {
        threads = store.all()
        refreshAvailability()
    }

    func refreshAvailability() {
        let now = engine.availability
        if now != availability { availability = now }
    }

    func thread(_ id: String) -> ChatThread? { threads.first { $0.id == id } }

    func search(_ query: String) -> [ChatThread] { ChatList.filter(threads, query: query) }

    func linked(to entryId: String) -> [ChatThread] { ChatList.linked(to: entryId, in: threads) }

    func newId() -> String { store.newId() }

    func send(_ text: String, attachment: String? = nil, mentions: [String] = [], fallbackTitle: String = "", in id: String) {
        var thread = thread(id) ?? store.draft(id)
        let before = thread.messages.count
        var message = store.message(.user, text, attachment: attachment)
        message.mentions = mentions
        thread.append(message, fallbackTitle: fallbackTitle)
        guard thread.messages.count > before else { return }
        for mention in thread.messages.last?.mentions ?? [] { thread.setLinked(mention, true) }
        if !mentions.isEmpty { engine.forget(id) }
        save(thread)
        answer(thread)
    }

    func retry(_ id: String) {
        failures[id] = nil
        guard let thread = thread(id), thread.lastQuestion != nil else { return }
        answer(thread)
    }

    func stop(_ id: String) { tasks[id]?.cancel() }

    func demoWaiting(_ id: String) { streaming[id] = "" }

    func demoFailed(_ id: String) { failures[id] = .generic }

    func setLinked(_ id: String, _ entryId: String, _ linked: Bool) {
        var thread = thread(id) ?? store.draft(id)
        thread.setLinked(entryId, linked)
        engine.forget(id)
        save(thread)
    }

    func rename(_ id: String, _ title: String) {
        guard let saved = try? store.rename(id, title) else { return }
        upsert(saved)
    }

    func setPinned(_ id: String, _ pinned: Bool) {
        guard var thread = thread(id), thread.pinned != pinned else { return }
        thread.pinned = pinned
        save(thread)
    }

    func delete(_ id: String) {
        stop(id)
        let gone = thread(id)?.attachments ?? []
        store.delete(id)
        engine.forget(id)
        streaming[id] = nil
        failures[id] = nil
        threads.removeAll { $0.id == id }
        removeOrphans(gone)
    }

    func discardImage(_ hash: String) { removeOrphans([hash]) }

    private func removeOrphans(_ hashes: [String]) {
        let orphans = ChatAttachments.orphans(hashes, threads: threads, inUse: attachmentsInUse?() ?? [])
        guard !orphans.isEmpty else { return }
        store.deleteAttachments(orphans)
        engine.forgetScans(orphans)
    }

    func createDraft(_ draftId: String, in id: String) {
        guard var thread = thread(id), var draft = thread.draft(draftId), draft.state == .open else { return }
        guard let shown = apply?(draft) else {
            failedDrafts.insert(draftId)
            return
        }
        failedDrafts.remove(draftId)
        draft.state = .saved
        draft.saved = shown
        thread.setDraft(draft)
        save(thread)
    }

    func discardDraft(_ draftId: String, in id: String) {
        guard var thread = thread(id), var draft = thread.draft(draftId), draft.state == .open else { return }
        draft.state = .discarded
        thread.setDraft(draft)
        save(thread)
    }

    func toggleDraftItem(_ draftId: String, at index: Int, in id: String) {
        guard var thread = thread(id), var draft = thread.draft(draftId), draft.state == .open, draft.items.indices.contains(index) else { return }
        draft.items[index].selected.toggle()
        thread.setDraft(draft)
        save(thread)
    }

    func chooseRow(_ name: String, draft draftId: String, in id: String) {
        guard let thread = thread(id), let draft = thread.draft(draftId), draft.state == .open, draft.asksForRow,
              let hash = thread.question(before: draftId)?.attachment else { return }
        applySkillName?(name)
        guard let snapshot = snapshot?() else { return }
        Task {
            guard let fresh = await engine.planDraft(hash: hash, id: draftId, snapshot: snapshot), var current = self.thread(id) else { return }
            current.setDraft(fresh)
            save(current)
        }
    }

    func editDraft(_ draft: ChatDraft, in id: String) {
        guard var thread = thread(id), thread.draft(draft.id)?.state == .open else { return }
        thread.setDraft(ChatDrafts.cleaned(draft, today: Day.of(store.now(), in: .current)))
        save(thread)
    }

    private func answer(_ thread: ChatThread) {
        refreshAvailability()
        guard let snapshot = snapshot?(), tasks[thread.id] == nil else { return }
        guard hasModel else {
            planOnly(thread, snapshot)
            return
        }
        let id = thread.id
        failures[id] = nil
        streaming[id] = ""
        tasks[id] = Task {
            var reply = ChatReply(text: "", seen: [])
            do {
                for try await part in engine.reply(to: thread, snapshot: snapshot, thinking: thinking?() ?? .standard) {
                    reply = part
                    streaming[id] = part.text
                }
                try Task.checkCancellation()
                finish(id, reply, snapshot)
            } catch {
                if !Task.isCancelled, !reply.drafts.isEmpty {
                    finish(id, ChatReply(text: "", seen: reply.seen, drafts: reply.drafts), snapshot)
                } else {
                    failures[id] = ChatEngine.failure(Task.isCancelled ? CancellationError() : error)
                }
            }
            streaming[id] = nil
            tasks[id] = nil
        }
    }

    private func planOnly(_ thread: ChatThread, _ snapshot: ChatSnapshot) {
        guard let hash = thread.lastQuestion?.attachment else { return }
        let id = thread.id
        failures[id] = nil
        streaming[id] = ""
        tasks[id] = Task {
            if let draft = await engine.planDraft(hash: hash, id: store.newId(), snapshot: snapshot), !draft.isEmpty {
                finish(id, ChatReply(text: "", seen: [], drafts: [draft]), snapshot)
            }
            streaming[id] = nil
            tasks[id] = nil
        }
    }

    private func finish(_ id: String, _ reply: ChatReply, _ snapshot: ChatSnapshot) {
        guard var current = thread(id) else { return }
        let pool = Set(reply.seen + current.links)
        let mentions = ChatMentions.find(reply.text, candidates: snapshot.entries.filter { pool.contains($0.id) })
        let text = reply.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !reply.drafts.isEmpty ? L.s("chat_draft_ready") : reply.text
        var message = store.message(.assistant, text)
        message.entries = mentions
        message.drafts = reply.drafts
        let before = current.messages.count
        current.append(message)
        if current.messages.count == before { failures[id] = .generic }
        save(current)
    }

    private func save(_ thread: ChatThread) {
        guard let saved = try? store.write(thread) else { return }
        upsert(saved)
    }

    private func upsert(_ thread: ChatThread) {
        threads.removeAll { $0.id == thread.id }
        threads.append(thread)
        threads.sort(by: ChatList.newestFirst)
    }
}
