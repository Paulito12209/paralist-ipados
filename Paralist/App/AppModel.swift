// Zusammenhang: Chat/ChatModel.swift, Net/UpdateChecker.swift, App/AppPrefs.swift (taskView, Archiv), ParalistCore Library/TaskView.swift, App/AppPaths.swift, Reminders/ReminderScheduler.swift, ParalistCore Library/EntryLibrary.swift
import Foundation
import Observation
import ParalistCore
import SwiftUI

struct Notice: Identifiable, Equatable {
    let id = UUID()
    let text: String
    var undoId: String?
    var top = false
    var title: String?
    var success = false
}

@MainActor
@Observable
final class AppModel {
    let library: EntryLibrary
    let prefs: AppPrefs
    let reminders: ReminderScheduler
    let chats: ChatModel
    private(set) var revision = 0
    var notice: Notice?
    var updateAvailable = false

    init() {
        prefs = AppPrefs()
        library = EntryLibrary(root: AppPaths.root)
        reminders = ReminderScheduler()
        reminders.lockScreenDetails = prefs.lockScreenDetails
        if AppPaths.isDemo { DemoSeed.fill(library) }
        chats = ChatModel(root: AppPaths.root)
        library.rebuild()
        library.dropPlaceLinks()
        library.purgeExpiredTrash()
        reminders.scheduleBriefing(prefs, briefing: weekBriefing(for: WeekBriefingBuilder.weekFor(today)))
        chats.snapshot = { [unowned self] in chatSnapshot() }
        chats.apply = { [unowned self] in applyChatDraft($0) }
        chats.thinking = { [unowned self] in prefs.chatThinking }
        chats.attachmentsInUse = { [unowned self] in attachmentsInUse() }
        chats.applySkillName = { [unowned self] in applySkillName($0) }
    }

    func applySkillName(_ name: String) {
        let planned = Skills.planSkill(name: name, title: L.s("skill_shift_title"), text: L.s("skill_shift_text"), in: all, make: { library.newEntry($0, title: $1) })
        planned.forEach { save($0) }
        if let note = planned.last, let tag = Skills.tag(in: all) { setLinked(note.id, tag.id, linked: true) }
    }

    func applyChatDraft(_ draft: ChatDraft) -> [String]? {
        let planned = ChatDrafts.entries(draft, decks: byType(.deck), reminder: Skills.shift(in: all)?.reminder, make: { library.newEntry($0, title: $1) })
        guard !planned.created.isEmpty else { return nil }
        let saved = planned.created.compactMap { try? library.save($0) }
        guard !saved.isEmpty else { return nil }
        saved.forEach { reminders.reschedule($0) }
        changed()
        return saved.count == planned.created.count ? planned.shown : saved.map(\.id)
    }

    func chatSnapshot() -> ChatSnapshot {
        let language = Locale(identifier: "en").localizedString(forLanguageCode: prefs.language.tag) ?? "English"
        let decks = Dictionary(uniqueKeysWithValues: byType(.deck).map { ($0.id, dueCount(deck: $0.id)) })
        return ChatSnapshot(entries: all, today: today, zone: .current, dueCards: decks, language: language,
                            languageTag: prefs.language.tag, attachmentsDir: library.store.attachmentsDir,
                            workTitle: L.s("shift_work"), absentTitle: L.s("shift_absent"))
    }

    private func attachmentsInUse() -> Set<String> {
        Set(all.compactMap { $0.attachment?.hash } + trash().compactMap { $0.entry.attachment?.hash })
    }

    var today: Day { Day.of(Date(), in: .current) }

    func reload() {
        library.rebuild()
        chats.reload()
        changed()
    }

    private func changed() { revision += 1 }

    var all: [Entry] { _ = revision; return library.all }
    func entry(_ id: String) -> Entry? { _ = revision; return library.entry(id) }
    func list(_ kind: ListKind) -> [Entry] {
        _ = revision
        if kind == .archive { return prefs.taskView.archive(library.all, today: today, zone: .current) }
        return library.list(kind)
    }
    func byType(_ type: EntryType) -> [Entry] { _ = revision; return library.byType(type) }
    var containers: [Entry] { _ = revision; return library.containers }
    func inPlace(_ id: String) -> [Entry] { _ = revision; return library.inPlace(id) }
    func inDeck(_ id: String) -> [Entry] { _ = revision; return library.inDeck(id) }
    func search(_ text: String) -> [Entry] { _ = revision; return library.search(text) }
    func rows(_ ids: [String]) -> [Entry] { _ = revision; return library.rows(ids) }
    var usage: UsageData { _ = revision; return library.usage }
    var links: LinkHistory { _ = revision; return library.links }
    var cardStates: [String: CardState] { _ = revision; return library.cardStates }
    var tasks: [Entry] { byType(.task).sorted(by: Ordering.tasks) }
    var xpLog: [XpEvent] { _ = revision; return library.xp }
    var xp: Int { XpLog.total(xpLog) }

    func count(_ kind: ListKind) -> Int { list(kind).count }

    func calendar(around day: Day) -> [Entry] {
        _ = revision
        let week = Week.of(day)
        let fromDay = week.previous().monday
        let toDay = week.next().sunday
        return library.calendar(from: fromDay.startOfDay(in: .current), to: toDay.adding(days: 1).startOfDay(in: .current), fromDay: fromDay, toDay: toDay)
    }

    func calendar(month: MonthKey) -> [Entry] {
        _ = revision
        let fromDay = Week.of(month.first).monday
        let toDay = Week.of(month.last).sunday
        return library.calendar(from: fromDay.startOfDay(in: .current), to: toDay.adding(days: 1).startOfDay(in: .current), fromDay: fromDay, toDay: toDay)
    }

    func weekBriefing(for week: Week) -> WeekBriefing {
        WeekBriefingBuilder.build(all, week: week, today: today, zone: .current)
    }

    func newEntry(_ type: EntryType, title: String = "") -> Entry { library.newEntry(type, title: title) }

    @discardableResult
    func save(_ entry: Entry) -> Entry? {
        guard let saved = try? library.save(entry) else { return nil }
        reminders.reschedule(saved)
        releasePins(for: saved)
        changed()
        return saved
    }

    func update(_ id: String, _ change: (Entry) -> Entry) {
        let before = library.entry(id)
        guard let saved = try? library.update(id, change) else { return }
        if let before, before.type == .event, saved.type == .event, let old = before.start, old != saved.start {
            library.recordMoved(id, from: old, to: saved.start)
            if [.open, .inProgress].contains(saved.status) { _ = try? library.setStatus(id, .postponed) }
        }
        reminders.reschedule(saved)
        releasePins(for: saved)
        changed()
    }

    private func releasePins(for entry: Entry) {
        let released = library.enforcePinLimit(for: entry, limit: prefs.pinLimit)
        guard let first = released.first else { return }
        notice = Notice(text: L.f("pin_released", first.title.isEmpty ? L.s("list_untitled") : first.title))
    }

    func setDone(_ id: String, _ done: Bool) {
        if let saved = try? library.setDone(id, done) { reminders.reschedule(saved) }
        changed()
    }

    func setStatus(_ id: String, _ status: TaskStatus) {
        let before = library.entry(id)?.status
        if let saved = try? library.setStatus(id, status) {
            reminders.reschedule(saved)
            if saved.type == .event, status == .cancelled, before != .cancelled { library.recordCancelled(id) }
        }
        changed()
    }

    func setLinked(_ id: String, _ other: String, linked: Bool) {
        _ = try? library.setLinked(id, other, linked: linked)
        changed()
    }

    func review(_ cardId: String, _ rating: Rating) {
        _ = try? library.review(cardId, rating)
        _ = try? library.setStatus(cardId, EntryStatus.rated(rating))
        changed()
    }

    func finishStudy(deck: String?) {
        guard let deck, let entry = library.entry(deck), entry.status != .learned else { return }
        let cards = library.candidates(deck: deck)
        guard !cards.isEmpty, cards.allSatisfy({ $0.state.phase != .new }) else { return }
        _ = try? library.setStatus(deck, .learned)
        changed()
    }

    func moveToTrash(_ id: String) {
        let title = library.entry(id)?.title ?? ""
        let bookmark = library.entry(id)?.type == .bookmark
        guard library.moveToTrash(id) else { return }
        if bookmark { ClipboardMemory.markHandled() }
        reminders.cancel(id)
        notice = Notice(text: L.s("entry_deleted") + (title.isEmpty ? "" : " · \(title)"), undoId: id)
        changed()
    }

    func restore(_ id: String) {
        if let entry = library.restore(id) { reminders.reschedule(entry) }
        changed()
    }

    func restoreAll(_ ids: [String]) { ids.forEach(restore) }

    func trash() -> [TrashedEntry] { _ = revision; return library.trash() }

    func deleteForever(_ ids: [String]) {
        library.deleteForever(ids)
        changed()
    }

    func recordOpened(_ id: String) {
        library.recordOpened(id)
        changed()
    }

    func recordShared(_ id: String) {
        library.recordShared(id)
        if let entry = library.entry(id), EntryStatus.options(for: entry).contains(.shared) { _ = try? library.setStatus(id, .shared) }
        changed()
    }

    func shareItems(_ entry: Entry) -> [Any] {
        if let file = attachmentPreviewURL(entry) { return [file] }
        if let url = entry.url, let link = URL(string: url) { return [link] }
        return []
    }

    func recordSearch(_ text: String) {
        library.recordSearch(text)
        changed()
    }

    func forgetSearch(_ text: String) {
        library.forgetSearch(text)
        changed()
    }

    var searchHomeStart: SearchHome { SearchHome.start(entries: all, usage: usage) }
    var recentlyCreated: [Entry] { SearchHome.recentlyCreated(all) }

    func rebuildIndex() -> Int {
        let count = library.rebuild()
        reminders.rescheduleAll(library.all)
        chats.reload()
        changed()
        return count
    }

    func say(_ text: String, top: Bool = false) { notice = Notice(text: text, top: top) }

    func cheer(_ title: String, _ text: String) { notice = Notice(text: text, top: true, title: title, success: true) }

    func studyQueue(deck: String?) -> [StudyCandidate] {
        let now = Date()
        let introduced = StudyQueue.introducedToday(Array(library.reviewEvents.values), now: now, zone: .current)
        return StudyQueue.build(library.candidates(deck: deck), introducedToday: introduced, newPerDay: prefs.newCardsPerDay, now: now)
    }

    func dueCount(deck: String?) -> Int {
        _ = revision
        return StudyQueue.dueCount(library.candidates(deck: deck), now: Date())
    }

    func newAvailable(deck: String?) -> Int {
        _ = revision
        let fresh = library.candidates(deck: deck).filter { $0.state.phase == .new }.count
        let introduced = StudyQueue.introducedToday(Array(library.reviewEvents.values), now: Date(), zone: .current)
        return min(fresh, max(0, prefs.newCardsPerDay - introduced))
    }

    func attachmentURL(_ entry: Entry) -> URL? { entry.attachment.flatMap { library.store.attachmentFile($0.hash) } }

    func attachmentPreviewURL(_ entry: Entry) -> URL? {
        guard let attachment = entry.attachment, let file = attachmentURL(entry) else { return nil }
        return AttachmentPreview.url(for: attachment, source: file)
    }
}
