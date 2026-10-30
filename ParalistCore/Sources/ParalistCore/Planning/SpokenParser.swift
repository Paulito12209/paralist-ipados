// Zusammenhang: Planning/SpokenEvent.swift, Planning/SpokenWords.swift, Planning/SpokenDates.swift, Planning/SpokenTimes.swift, Planning/DayPeriods.swift, Model/Day.swift, Text/Pattern.swift
import Foundation

struct SpokenClock: Hashable {
    var hour: Int
    var minute = 0
    var pm: Bool?

    func minuteOfDay(_ period: DayPeriod?) -> Int {
        var h = hour
        if let pm {
            if pm && h < 12 { h += 12 }
            if !pm && h == 12 { h = 0 }
        } else if let period {
            switch period {
            case .afternoon, .evening: if h < 12 { h += 12 }
            case .noon: if h < 6 { h += 12 }
            case .morning: break
            }
        }
        return h * 60 + minute
    }
}

struct SpokenParser {
    struct Token {
        let raw: String
        let word: String
        var used = false
        var dotted: Bool { raw.hasSuffix(".") }
    }

    static let dash = Pattern("(\\d)\\s*[-–—]\\s*(\\d)")
    static let trim = CharacterSet(charactersIn: ",;:!?\"„“”'()….")

    var tokens: [Token]
    var day: Day?
    var period: DayPeriod?
    var start: SpokenClock?
    var end: SpokenClock?
    var duration: Int?
    var inMinutes: Int?
    var allDay = false
    var ledIn = false
    var reminder = false
    var sameTime = false
    var byWeekday = false

    init(_ text: String) {
        let spaced = Self.dash.replace(text.replacingOccurrences(of: "\n", with: " "), with: "$1 - $2")
        tokens = spaced.split(whereSeparator: { $0 == " " || $0 == "\t" }).map { part in
            let raw = String(part)
            let word = raw.lowercased().trimmingCharacters(in: Self.trim)
            let blank = word.isEmpty && !["-", "–", "—"].contains(raw)
            return Token(raw: raw, word: word.isEmpty ? raw.lowercased() : word, used: blank)
        }
    }

    mutating func run(today: Day) {
        fillers()
        lead()
        dates(today: today)
        times()
        periods()
        durations()
        wholeDay()
        reminders()
        dangling()
        clauses()
        dangling()
        trailing()
        dangling()
    }

    var title: String {
        let kept = tokens.filter { !$0.used && !$0.word.isEmpty && $0.raw.contains(where: { $0.isLetter || $0.isNumber }) }
        var parts: [String] = []
        for (n, token) in kept.enumerated() {
            var raw = token.raw
            if raw.hasSuffix("."), n + 1 < kept.count, kept[n + 1].raw.first?.isLowercase == true { raw.removeLast() }
            parts.append(raw)
        }
        let cleaned = parts.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: ",;:.-–!?").union(.whitespacesAndNewlines))
        guard let first = cleaned.first else { return "" }
        return first.uppercased() + cleaned.dropFirst()
    }

    private mutating func reminders() {
        var i = 0
        while i < tokens.count {
            guard free(i), let phrase = phrase(in: SpokenWords.reminderIndex, at: i) else {
                i += 1
                continue
            }
            reminder = true
            var end = i + phrase.count
            while free(end), SpokenWords.reminderTail.contains(word(end)) { end += 1 }
            use(i..<end)
            eatBack(i, SpokenWords.reminderLead)
            i = end
        }
    }

    func word(_ i: Int) -> String { i >= 0 && i < tokens.count ? tokens[i].word : "" }
    func free(_ i: Int) -> Bool { i >= 0 && i < tokens.count && !tokens[i].used }
    func dotted(_ i: Int) -> Bool { i >= 0 && i < tokens.count && tokens[i].dotted }

    mutating func use(_ range: Range<Int>) {
        for i in range where i >= 0 && i < tokens.count { tokens[i].used = true }
    }

    mutating func eatBack(_ i: Int, _ words: Set<String>) {
        var k = i - 1
        while free(k) && words.contains(word(k)) {
            tokens[k].used = true
            k -= 1
        }
    }

    func matches(_ phrase: [String], at i: Int) -> Bool {
        phrase.indices.allSatisfy { free(i + $0) && word(i + $0) == phrase[$0] }
    }

    func phrase(in index: [String: [[String]]], at i: Int) -> [String]? {
        index[word(i)]?.first { matches($0, at: i) }
    }

    private mutating func fillers() {
        for i in tokens.indices where SpokenWords.fillers.contains(tokens[i].word) { tokens[i].used = true }
        while let first = tokens.indices.first(where: { free($0) }), SpokenWords.leadFillers.contains(word(first)) {
            tokens[first].used = true
        }
    }

    private mutating func lead() {
        let s = tokens.indices.first(where: { free($0) }) ?? 0
        var j = s
        if let phrase = SpokenWords.leadPhrases.first(where: { matches($0, at: s) }) {
            j = s + phrase.count
            ledIn = true
            if SpokenWords.reminderWords.contains(phrase[0]) { reminder = true }
        } else if SpokenWords.eventNouns.contains(word(s)), tokens[s].raw.hasSuffix(":") {
            j = s + 1
            if SpokenWords.reminderWords.contains(word(s)) { reminder = true }
        }
        var k = j
        var marked = false
        while k < tokens.count, SpokenWords.lead.contains(word(k)) || SpokenWords.leadFill.contains(word(k)) || SpokenWords.fresh.contains(word(k)) {
            if SpokenWords.lead.contains(word(k)) || SpokenWords.fresh.contains(word(k)) { marked = true }
            k += 1
        }
        if marked && SpokenWords.eventNouns.contains(word(k)) {
            j = k + 1
            ledIn = true
            if SpokenWords.reminderWords.contains(word(k)) { reminder = true }
        }
        use(s..<j)
        for i in tokens.indices where free(i) && ["erinnerung", "reminder"].contains(word(i)) && (ledIn || marked || i == s) {
            reminder = true
            use(i..<(i + 1))
            eatBack(i, SpokenWords.articles.union(["als", "as"]))
        }
    }

    private mutating func clauses() {
        var clause = false
        for i in tokens.indices where free(i) {
            guard let opener = SpokenWords.clauseOpeners.first(where: { matches($0, at: i) }) else { continue }
            guard tokens[..<i].allSatisfy({ $0.used || SpokenWords.junk.contains($0.word) }) else { break }
            use(0..<(i + opener.count))
            clause = true
            let next = i + opener.count
            if let verb = SpokenWords.clauseVerbs.first(where: { matches($0, at: next) }) { use(next..<(next + verb.count)) }
            break
        }
        guard clause || ledIn else { return }
        if let last = tokens.indices.last(where: { free($0) }), SpokenWords.modals.contains(word(last)),
           tokens[..<last].contains(where: { !$0.used }) {
            tokens[last].used = true
        }
        ledIn = true
    }

    private mutating func trailing() {
        var last = tokens.count - 1
        while last > 0, free(last), SpokenWords.trailing.contains(word(last)), tokens[..<last].contains(where: { !$0.used }) {
            tokens[last].used = true
            last -= 1
        }
        guard ledIn else { return }
        for _ in 0..<4 {
            guard let first = tokens.indices.first(where: { free($0) }), let next = tokens.indices.first(where: { $0 > first && free($0) }) else { return }
            let w = word(first)
            let article = SpokenWords.articles.contains(w) && (w == "the" || tokens[next].raw.first?.isUppercase == true || ["einen", "eine", "ein", "a", "an"].contains(w))
            let leftover = SpokenWords.leadAdverbs.contains(w) || (reminder && SpokenWords.reminderLeftovers.contains(w))
            guard article || leftover || SpokenWords.linkers.contains(w) else { return }
            tokens[first].used = true
        }
    }

    private mutating func dangling() {
        for i in tokens.indices where free(i) && SpokenWords.linkers.contains(word(i)) {
            let nextUsed = i + 1 >= tokens.count || tokens[i + 1].used
            if nextUsed { tokens[i].used = true }
        }
    }
}
