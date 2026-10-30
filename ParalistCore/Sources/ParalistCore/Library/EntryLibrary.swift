// Zusammenhang: Store/EntryStore.swift, Flashcards/ReviewLog.swift, Library/ListKind.swift, Library/Usage.swift, Paralist/App/AppModel.swift, Library/PinLimit.swift, Library/LinkPlace.swift, Library/AttachmentEntry.swift, Library/LinkHistory.swift
import Foundation

public final class EntryLibrary: @unchecked Sendable {
    public let store: EntryStore
    public let reviews: ReviewLog
    private let ids: IdGenerator
    private let clock: Clock
    private let usageFile: URL
    private let linksFile: URL
    public private(set) var entries: [String: Entry] = [:]
    public private(set) var broken: [BrokenFile] = []
    public private(set) var cardStates: [String: CardState] = [:]
    public private(set) var reviewEvents: [String: [ReviewEvent]] = [:]
    public private(set) var usage = UsageData()
    public private(set) var links = LinkHistory()

    public init(root: URL, ids: IdGenerator = SecureIds(), clock: Clock = SystemClock()) {
        store = EntryStore(root: root, clock: clock)
        reviews = ReviewLog(root: root)
        self.ids = ids
        self.clock = clock
        usageFile = root.appendingPathComponent("nutzung.json")
        if let data = try? Data(contentsOf: usageFile), let decoded = try? JSONDecoder().decode(UsageData.self, from: data) {
            usage = decoded
        }
        linksFile = root.appendingPathComponent("linkverlauf.json")
        links = Self.readLinks(linksFile)
    }

    @discardableResult
    public func rebuild() -> Int {
        let scan = store.scan()
        entries = Dictionary(scan.entries.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        broken = scan.broken
        reviewEvents = reviews.readAll(now: clock.now())
        cardStates = [:]
        for card in scan.entries where card.type == .flashcard {
            cardStates[card.id] = ReviewLog.replay(reviewEvents[card.id] ?? [])
        }
        links = Self.readLinks(linksFile).merged(with: links)
        var grew = false
        for entry in scan.entries + store.listTrash().map(\.entry) { grew = links.record(entry.url, at: entry.created) || grew }
        if grew { persistLinks() }
        return scan.entries.count
    }

    public var all: [Entry] { Array(entries.values) }

    public func entry(_ id: String) -> Entry? { entries[id] }

    public func list(_ kind: ListKind) -> [Entry] {
        let rows = entries.values.filter { kind.includes($0) }
        if kind == .archive { return rows.sorted { $0.updated > $1.updated } }
        return rows.sorted(by: Ordering.pinnedThenUpdated)
    }

    public func byType(_ type: EntryType) -> [Entry] {
        entries.values.filter { $0.type == type && !$0.archived }.sorted(by: Ordering.pinnedThenUpdated)
    }

    public var containers: [Entry] {
        entries.values.filter { $0.type.isContainer && !$0.archived }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    public func fileEntry(_ hash: String, excluding id: String? = nil) -> Entry? {
        AttachmentEntry.existing(hash, in: all, excluding: id)
    }

    public func inPlace(_ placeId: String) -> [Entry] {
        entries.values.filter { $0.places.contains(placeId) && !$0.archived }.sorted(by: Ordering.pinnedThenUpdated)
    }

    public func inDeck(_ deckId: String) -> [Entry] {
        entries.values.filter { $0.deck == deckId && !$0.archived }.sorted { $0.created < $1.created }
    }

    public func calendar(from: Date, to: Date, fromDay: Day, toDay: Day) -> [Entry] {
        entries.values.filter { e in
            guard !e.archived else { return false }
            if let s = e.start, s >= from, s < to { return true }
            if let d = e.due, d >= fromDay, d <= toDay { return true }
            return false
        }.sorted { ($0.start ?? .distantFuture, $0.due?.epochDay ?? .max) < ($1.start ?? .distantFuture, $1.due?.epochDay ?? .max) }
    }

    public func search(_ text: String) -> [Entry] {
        let terms = SearchQuery.terms(text)
        if terms.isEmpty { return [] }
        return Array(entries.values.filter { SearchQuery.matches($0, terms: terms) }.sorted { $0.updated > $1.updated }.prefix(100))
    }

    public func rows(_ ids: [String]) -> [Entry] { ids.compactMap { entries[$0] } }

    public func newEntry(_ type: EntryType, title: String) -> Entry {
        let now = clock.now()
        var e = Entry(id: ids.next(), type: type, title: title, created: now, updated: now)
        e.status = type.hasStatus ? .open : nil
        return e
    }

    @discardableResult
    public func save(_ entry: Entry) throws -> Entry {
        let saved = try store.save(entry)
        index(saved)
        if links.record(saved.url, at: saved.updated) { persistLinks() }
        return saved
    }

    @discardableResult
    public func update(_ id: String, _ change: (Entry) -> Entry) throws -> Entry? {
        guard let entry = store.load(id) else { return nil }
        return try save(change(entry))
    }

    @discardableResult
    public func enforcePinLimit(for entry: Entry, limit: Int) -> [Entry] {
        PinLimit.displaced(by: entry, among: all, limit: limit).compactMap { id in
            guard var other = store.load(id) else { return nil }
            other.pinned = false
            guard let written = try? store.write(other) else { return nil }
            index(written)
            return written
        }
    }

    @discardableResult
    public func setStatus(_ id: String, _ status: TaskStatus) throws -> Entry? {
        let now = clock.now()
        return try update(id) { e in
            guard e.type.hasStatus, EntryStatus.options(for: e).contains(status) else { return e }
            var c = e
            c.status = status
            c.doneAt = status == .done ? now : nil
            return c
        }
    }

    @discardableResult
    public func setDone(_ id: String, _ done: Bool) throws -> Entry? { try setStatus(id, done ? .done : .open) }

    @discardableResult
    public func setLinked(_ id: String, _ other: String, linked: Bool) throws -> Entry? {
        let mine = store.load(id)
        let theirs = store.load(other)
        if let theirs { try save(Self.link(theirs, to: id, with: mine, linked: linked)) }
        return try update(id) { Self.link($0, to: other, with: theirs, linked: linked) }
    }

    private static func link(_ entry: Entry, to other: String, with partner: Entry?, linked: Bool) -> Entry {
        let changed = EntryChanges.withLink(entry, other, linked: linked)
        guard linked, let partner else { return changed }
        return LinkPlace.adopted(changed, linkedTo: partner)
    }

    @discardableResult
    public func dropPlaceLinks() -> Int {
        var count = 0
        for fixed in LinkPlace.repaired(all) {
            guard let written = try? store.write(fixed) else { continue }
            index(written)
            count += 1
        }
        return count
    }

    @discardableResult
    public func review(_ cardId: String, _ rating: Rating) throws -> CardState? {
        guard store.load(cardId) != nil else { return nil }
        let now = clock.now()
        try reviews.append(ReviewEvent(cardId: cardId, at: now, rating: rating))
        let events = reviews.read(cardId, now: now)
        reviewEvents[cardId] = events
        let state = ReviewLog.replay(events)
        cardStates[cardId] = state
        return state
    }

    public func candidates(deck: String?) -> [StudyCandidate] {
        entries.values.filter { $0.type == .flashcard && !$0.archived && (deck == nil || $0.deck == deck) }
            .map { StudyCandidate(cardId: $0.id, state: cardStates[$0.id] ?? CardState()) }
    }

    @discardableResult
    public func moveToTrash(_ id: String) -> Bool {
        let moved = store.moveToTrash(id)
        if moved {
            entries[id] = nil
            cardStates[id] = nil
            usage.forget(id)
            persistUsage()
        }
        return moved
    }

    @discardableResult
    public func restore(_ id: String) -> Entry? {
        guard let entry = store.restoreFromTrash(id) else { return nil }
        index(entry)
        return entry
    }

    public func trash() -> [TrashedEntry] { store.listTrash() }

    @discardableResult
    public func deleteForever(_ ids: [String]) -> Int {
        let gone = Set(ids.filter { store.deleteFromTrash($0) })
        gone.forEach { reviews.delete($0) }
        dropReferences(gone)
        return gone.count
    }

    @discardableResult
    public func purgeExpiredTrash() -> Int {
        let gone = Set(store.purgeTrash(now: clock.now()))
        gone.forEach { reviews.delete($0) }
        dropReferences(gone)
        return gone.count
    }

    public func recordOpened(_ id: String) {
        usage.recordOpened(id, at: clock.now())
        persistUsage()
    }

    public func recordShared(_ id: String) {
        usage.recordShared(id)
        persistUsage()
    }

    public func recordMoved(_ id: String, from: Date?, to: Date?) {
        usage.recordMoved(id, from: from, to: to, at: clock.now())
        persistUsage()
    }

    public func recordCancelled(_ id: String) {
        usage.recordCancelled(id, at: clock.now())
        persistUsage()
    }

    public func recordSearch(_ text: String) {
        usage.recordSearch(text, at: clock.now())
        persistUsage()
    }

    public func forgetSearch(_ text: String) {
        usage.forgetSearch(text)
        persistUsage()
    }

    public var xp: [XpEvent] { XpLog.build(all, reviews: Array(reviewEvents.values)) }

    private func dropReferences(_ gone: Set<String>) {
        if gone.isEmpty { return }
        for entry in store.scan().entries {
            let cleaned = EntryChanges.withoutReferences(entry, gone)
            if cleaned != entry, let written = try? store.write(cleaned) { index(written) }
        }
    }

    private func index(_ entry: Entry) {
        entries[entry.id] = entry
        if entry.type == .flashcard {
            cardStates[entry.id] = ReviewLog.replay(reviewEvents[entry.id] ?? [])
        } else {
            cardStates[entry.id] = nil
        }
    }

    private func persistLinks() {
        links = Self.readLinks(linksFile).merged(with: links)
        if let data = try? JSONEncoder().encode(links) { try? data.write(to: linksFile, options: .atomic) }
    }

    private static func readLinks(_ file: URL) -> LinkHistory {
        guard let data = try? Data(contentsOf: file), let decoded = try? JSONDecoder().decode(LinkHistory.self, from: data) else { return LinkHistory() }
        return decoded
    }

    private func persistUsage() {
        if let data = try? JSONEncoder().encode(usage) { try? data.write(to: usageFile, options: .atomic) }
    }
}
