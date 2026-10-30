// Zusammenhang: Paralist/Composer/ComposerSheet.swift, Planning/SpokenEvent.swift, Planning/DayPeriods.swift, ParalistShare/ShareView.swift, Planning/ReminderPlanner.swift, Tests/ParalistCoreTests/ComposerDraftTests.swift, Library/AttachmentEntry.swift, Library/LinkPlace.swift, Library/PlacePicker.swift
import Foundation

public struct ComposerDraft: Sendable {
    public var type: EntryType
    public var title = ""
    public var body = ""
    public var url = ""
    public var places: [String] = []
    public var deck: String?
    public var favorite = false
    public var pinned = false
    public var date: Day?
    public var minute: Int?
    public var endDate: Day?
    public var endMinute: Int?
    public var eventOffset: EventOffset = .min15
    public var reminders: [Date] = []
    public var attachment: Attachment?
    public var link: String?
    public var links: Set<String> = []
    public var showBody = false
    public var urlError = false
    public var urlConfirmed = false

    private static let scheme = Pattern("^[a-zA-Z][a-zA-Z0-9+.-]*://")

    public init(type: EntryType) { self.type = type }

    public var showsBody: Bool { showBody || type == .flashcard }
    public var hasDate: Bool { type == .task || type == .event || type == .project }
    public var hasPlace: Bool { EntryParent.applies(to: type) }
    public var hasReminders: Bool { !reminders.isEmpty || (type == .event && eventOffset != .none && date != nil) }

    public func start(zone: TimeZone) -> Date? {
        guard type == .event, let date else { return nil }
        guard let minute else { return date.startOfDay(in: zone) }
        return date.at(hour: minute / 60, minute: minute % 60, in: zone)
    }

    public func end(zone: TimeZone) -> Date? {
        guard let start = start(zone: zone), let date, minute != nil else { return nil }
        let end = endMinute.map { (endDate ?? date).at(hour: $0 / 60, minute: $0 % 60, in: zone) }
        return EventTimes.end(start: start, end: end)
    }

    public mutating func setTimes(start: Date?, end: Date?, allDay: Bool, zone: TimeZone) {
        guard let start else {
            date = nil
            minute = nil
            endDate = nil
            endMinute = nil
            return
        }
        date = Day.of(start, in: zone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let s = calendar.dateComponents([.hour, .minute], from: start)
        minute = allDay ? nil : (s.hour ?? 0) * 60 + (s.minute ?? 0)
        guard !allDay, let end = end.map({ EventTimes.end(start: start, end: $0) }) else {
            endDate = nil
            endMinute = nil
            return
        }
        let e = calendar.dateComponents([.hour, .minute], from: end)
        endDate = Day.of(end, in: zone)
        endMinute = (e.hour ?? 0) * 60 + (e.minute ?? 0)
    }

    public mutating func apply(_ spoken: SpokenEvent) {
        let name = spoken.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { title = String(name.prefix(Limits.maxInputTitleChars)) }
        guard hasDate, let day = spoken.day else { return }
        date = day
        minute = spoken.startMinute
        guard type == .event else { return }
        endDate = spoken.endDay
        endMinute = spoken.endMinute
    }

    public mutating func absorbTitle(now: Date, zone: TimeZone, periods: DayPeriods) -> Date? {
        guard hasDate, !title.isEmpty else { return nil }
        let spoken = SpokenEvent.parse(title, now: now, zone: zone, periods: periods, baseDay: date, baseMinute: minute)
        guard spoken.reminder || (date == nil && spoken.day != nil) else { return nil }
        let name = spoken.title
        apply(spoken)
        if name.isEmpty { title = "" }
        return remind(spoken, periods: periods, zone: zone)
    }

    public mutating func remind(_ spoken: SpokenEvent, periods: DayPeriods, zone: TimeZone) -> Date? {
        guard spoken.reminder, hasDate, type != .event, let date else { return nil }
        let m = minute ?? periods[.morning]
        let at = date.at(hour: m / 60, minute: m % 60, in: zone)
        reminders = [at]
        return at
    }

    public static func normalizeUrl(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.count > Limits.maxUrlChars { return nil }
        let full = scheme.contains(trimmed) && scheme.first(in: trimmed)?.range.lowerBound == trimmed.startIndex ? trimmed : "https://" + trimmed
        let lower = full.lowercased()
        guard lower.hasPrefix("http://") || lower.hasPrefix("https://") else { return nil }
        if full.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.contains($0) }) { return nil }
        return full
    }

    public static func hostOf(_ url: String) -> String {
        guard let host = URLComponents(string: url)?.host, !host.isEmpty else { return url }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    public mutating func confirmUrl() {
        if let clean = Self.normalizeUrl(url) {
            url = clean
            urlError = false
            urlConfirmed = true
        } else {
            urlError = !url.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    public mutating func paste(_ link: String) {
        url = link
        confirmUrl()
    }

    public mutating func dictateUrl(_ text: String) {
        paste(text.lowercased().filter { !$0.isWhitespace })
    }

    public var linkSubject: Entry {
        var e = Entry(id: "", type: type, title: title, created: .distantPast, updated: .distantPast)
        e.places = hasPlace ? places : []
        return e
    }

    public mutating func linkTo(_ partner: Entry?) {
        link = nil
        deck = partner.flatMap { LinkPlace.deck(for: .flashcard, linkedTo: $0) }
        guard let partner, !(type == .flashcard && deck != nil) else { return }
        var subject = linkSubject
        subject.places = []
        let picked = hasPlace && !pickerExcludes.contains(partner.type) ? PlacePicker.places(for: subject, picking: partner) : []
        if picked.isEmpty { link = partner.id } else { places = picked }
    }

    public var target: String? { places.first }

    public func isPicked(_ id: String) -> Bool { places.contains(id) }

    public var pickerExcludes: Set<EntryType> { type == .flashcard ? [.deck] : [] }

    public mutating func pick(_ partner: Entry?) {
        let again = partner.map { isPicked($0.id) } ?? false
        places = []
        guard let partner, !again, !pickerExcludes.contains(partner.type) else { return }
        places = PlacePicker.places(for: linkSubject, picking: partner)
        if let target { links.remove(target) }
    }

    public mutating func toggleLink(_ id: String) {
        if links.contains(id) { links.remove(id) } else if id != target { links.insert(id) }
    }

    public func linkable(in all: [Entry]) -> [Entry] {
        all.filter { $0.id != target && !$0.archived }
    }

    public mutating func chooseDeck(_ id: String) {
        deck = deck == id ? nil : id
    }

    public mutating func openDate(now: Date, zone: TimeZone) {
        guard hasDate, date == nil else { return }
        date = Day.of(now, in: zone)
        if type == .event { minute = Self.nextHour(now, zone: zone) }
    }

    public mutating func clearDate() {
        date = nil
        minute = nil
        endDate = nil
        endMinute = nil
    }

    public func time(zone: TimeZone) -> Date? {
        guard let date, let minute else { return nil }
        return date.at(hour: minute / 60, minute: minute % 60, in: zone)
    }

    public mutating func setDay(_ day: Day, zone: TimeZone) {
        guard type == .event, let start = start(zone: zone), let end = end(zone: zone) else {
            date = day
            return
        }
        date = day
        guard let moved = self.start(zone: zone) else { return }
        setTimes(start: moved, end: EventTimes.moved(end: end, from: start, to: moved), allDay: false, zone: zone)
    }

    public mutating func setTime(_ time: Date?, zone: TimeZone) {
        guard let date else { return }
        guard let time else {
            minute = nil
            endDate = nil
            endMinute = nil
            return
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let c = calendar.dateComponents([.hour, .minute], from: time)
        let new = date.at(hour: c.hour ?? 0, minute: c.minute ?? 0, in: zone)
        guard type == .event else {
            minute = (c.hour ?? 0) * 60 + (c.minute ?? 0)
            return
        }
        let old = start(zone: zone)
        let end = minute == nil ? nil : end(zone: zone)
        let moved = old.flatMap { from in end.map { EventTimes.moved(end: $0, from: from, to: new) } }
        setTimes(start: new, end: moved, allDay: false, zone: zone)
    }

    public mutating func setEnd(_ end: Date, zone: TimeZone) {
        guard type == .event, minute != nil, let start = start(zone: zone) else { return }
        setTimes(start: start, end: end, allDay: false, zone: zone)
    }

    public static func nextHour(_ now: Date, zone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return min(calendar.component(.hour, from: now) + 1, 23) * 60
    }

    public mutating func attach(_ file: Attachment) {
        attachment = file
        let untitled = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if type == .note && untitled { type = .file }
        if untitled && AttachmentEntry.holds(type) {
            title = SharedFile.title(file.name)
        }
    }

    public mutating func build(_ base: Entry, zone: TimeZone) -> Entry? {
        var cleanUrl: String?
        if type == .bookmark {
            let raw = url.trimmingCharacters(in: .whitespaces)
            if !raw.isEmpty {
                guard let normalized = Self.normalizeUrl(raw) else {
                    urlError = true
                    return nil
                }
                cleanUrl = normalized
            }
        }
        var e = base
        e.type = type
        e.status = type.hasStatus ? (base.status ?? .open) : nil
        let start = start(zone: zone)
        var all = reminders
        if let start, let offset = eventOffset.before(start) { all.append(offset) }
        e.reminders = Array(Set(all)).sorted()
        var name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty, let cleanUrl { name = Self.hostOf(cleanUrl) }
        e.title = String(name.prefix(Limits.maxTitleChars))
        let trimmedBody = body.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        e.body = showsBody && !trimmedBody.isEmpty ? trimmedBody + "\n" : ""
        e.places = hasPlace ? places : []
        e.deck = type == .flashcard ? deck : nil
        e.favorite = favorite
        e.pinned = pinned
        e.setDue((type == .task || type == .project) ? date : nil)
        e.setDueTime(e.due == nil ? nil : minute.flatMap { DueTime(hour: $0 / 60, minute: $0 % 60) })
        e.start = start
        e.end = end(zone: zone)
        e.allDay = start != nil && minute == nil
        e.url = type == .bookmark ? cleanUrl : nil
        e.attachment = attachment
        if let link { e = EntryChanges.withLink(e, link, linked: true) }
        return e
    }
}
