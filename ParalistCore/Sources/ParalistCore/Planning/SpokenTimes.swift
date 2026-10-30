// Zusammenhang: Planning/SpokenParser.swift, Planning/SpokenWords.swift, Planning/SpokenDates.swift, Planning/DayPeriods.swift
import Foundation

extension SpokenParser {
    private static let colon = Pattern("^(\\d{1,2})[:.](\\d{2})$")
    private static let compact = Pattern("^(\\d{1,2})(?:[:.](\\d{2}))?(am|pm|a\\.m|p\\.m)$")
    private static let french = Pattern("^(\\d{1,2})h(\\d{2})?$")

    private func hour12(_ j: Int) -> Int? {
        guard let h = SpokenWords.number(word(j)), (1...12).contains(h) else { return nil }
        return h
    }

    private func before(_ h: Int) -> Int { h == 1 ? 12 : h - 1 }

    func clock(at i: Int, bare: Bool) -> (SpokenClock, Int)? {
        guard free(i) else { return nil }
        let w = word(i)
        if SpokenWords.midnightWords.contains(w) { return (SpokenClock(hour: 0), i + 1) }
        if w == "halb", let h = hour12(i + 1) { return finish(SpokenClock(hour: before(h), minute: 30), i + 2) }
        if w == "dreiviertel", let h = hour12(i + 1) { return finish(SpokenClock(hour: before(h), minute: 45), i + 2) }
        if w == "viertel" {
            if word(i + 1) == "nach" || word(i + 1) == "vor", let h = hour12(i + 2) {
                let c = word(i + 1) == "nach" ? SpokenClock(hour: h, minute: 15) : SpokenClock(hour: before(h), minute: 45)
                return finish(c, i + 3)
            }
            if let h = hour12(i + 1) { return finish(SpokenClock(hour: before(h), minute: 15), i + 2) }
        }
        if w == "half", word(i + 1) == "past", let h = hour12(i + 2) { return finish(SpokenClock(hour: h, minute: 30), i + 3) }
        if w == "quarter" {
            if ["past", "after"].contains(word(i + 1)), let h = hour12(i + 2) { return finish(SpokenClock(hour: h, minute: 15), i + 3) }
            if ["to", "before", "till"].contains(word(i + 1)), let h = hour12(i + 2) { return finish(SpokenClock(hour: before(h), minute: 45), i + 3) }
        }
        if let n = SpokenWords.number(w), [5, 10, 20, 25].contains(n), Int(w) == nil {
            if ["past", "after", "nach"].contains(word(i + 1)), let h = hour12(i + 2) { return finish(SpokenClock(hour: h, minute: n), i + 3) }
            if ["to", "vor"].contains(word(i + 1)), let h = hour12(i + 2) { return finish(SpokenClock(hour: before(h), minute: 60 - n), i + 3) }
        }
        let numeric = w.first?.isNumber == true
        if numeric, let m = Self.colon.first(in: w), let h = Int(m.group(1)), let mm = Int(m.group(2)), h < 24, mm < 60 {
            return finish(SpokenClock(hour: h, minute: mm), i + 1)
        }
        if numeric, let m = Self.compact.first(in: w), let h = Int(m.group(1)), (1...12).contains(h) {
            return (SpokenClock(hour: h, minute: Int(m.group(2)) ?? 0, pm: m.group(3).hasPrefix("p")), i + 1)
        }
        if numeric, let m = Self.french.first(in: w), let h = Int(m.group(1)), h < 24, let mm = Int(m.group(2).isEmpty ? "0" : m.group(2)), mm < 60 {
            return finish(SpokenClock(hour: h, minute: mm), i + 1)
        }
        guard let h = SpokenWords.number(w), (0...23).contains(h) else { return nil }
        let digits = Int(w) != nil
        let next = word(i + 1)
        if SpokenWords.clockWords.contains(next) {
            if SpokenWords.hourWords.contains(next), SpokenWords.durationPreps.contains(word(i - 1)) || SpokenWords.longWords.contains(word(i + 2)) { return nil }
            var c = SpokenClock(hour: h)
            var j = i + 2
            let unit = word(j + 1)
            if let mm = Int(word(j)), mm < 60, word(j).count <= 2, free(j), !SpokenWords.hourWords.contains(unit), !SpokenWords.minuteWords.contains(unit) {
                c.minute = mm
                j += 1
            }
            return finish(c, j)
        }
        if (1...12).contains(h), SpokenWords.meridiem(next) != nil { return finish(SpokenClock(hour: h), i + 1) }
        if bare && digits { return finish(SpokenClock(hour: h), i + 1) }
        return nil
    }

    private func finish(_ clock: SpokenClock, _ index: Int) -> (SpokenClock, Int) {
        var c = clock
        var j = index
        if SpokenWords.clockWords.contains(word(j)) && free(j) { j += 1 }
        if let pm = SpokenWords.meridiem(word(j)), free(j), (1...12).contains(c.hour) {
            c.pm = pm
            j += 1
        }
        return (c, j)
    }

    mutating func times() {
        var i = 0
        while i < tokens.count {
            guard free(i) else {
                i += 1
                continue
            }
            if start == nil, let phrase = phrase(in: SpokenWords.sameTimeIndex, at: i) {
                sameTime = true
                use(i..<(i + phrase.count))
                i += phrase.count
                continue
            }
            let prev = word(i - 1)
            let between = SpokenWords.betweenWords.contains(prev) && free(i - 1)
            let ahead = SpokenWords.rangeWords.contains(word(i + 1)) && clock(at: i + 2, bare: true) != nil
            let bare = SpokenWords.timePreps.contains(prev) || SpokenWords.rangeWords.contains(prev) || between || ahead
            guard let (c, j) = clock(at: i, bare: bare) else {
                i += 1
                continue
            }
            if start == nil {
                start = c
                use(i..<j)
                eatBack(i, SpokenWords.timePreps.union(SpokenWords.betweenWords))
                let connectors = between ? SpokenWords.rangeWords.union(SpokenWords.andWords) : SpokenWords.rangeWords
                if connectors.contains(word(j)), let (e, k) = clock(at: j + 1, bare: true) {
                    end = e
                    use(j..<k)
                    i = k
                    continue
                }
            } else if end == nil, SpokenWords.rangeWords.contains(prev), free(i - 1) {
                end = c
                use((i - 1)..<j)
            }
            i = max(j, i + 1)
        }
    }

    mutating func periods() {
        for i in tokens.indices where free(i) {
            let w = word(i)
            if SpokenWords.nightWords.contains(w) {
                if var s = start, s.pm == nil {
                    if (6...11).contains(s.hour) { s.pm = true } else if s.hour == 12 { s.hour = 0 }
                    start = s
                }
                use(i..<(i + 1))
                eatBack(i, SpokenWords.periodPreps)
                continue
            }
            guard let p = SpokenWords.periods[w] else { continue }
            if period == nil { period = p }
            use(i..<(i + 1))
            eatBack(i, SpokenWords.periodPreps)
        }
    }

    mutating func durations() {
        for i in tokens.indices where free(i) && SpokenWords.durationPreps.contains(word(i)) {
            guard let (minutes, last) = span(at: i + 1), duration == nil else { continue }
            duration = minutes
            use(i..<(last + 1))
        }
        for i in tokens.indices where free(i) && SpokenWords.longWords.contains(word(i)) && duration == nil {
            for from in stride(from: i - 1, through: max(0, i - 3), by: -1) where free(from) {
                guard let (minutes, last) = span(at: from), last == i - 1 else { continue }
                duration = minutes
                use(from..<(i + 1))
                break
            }
        }
    }

    private func span(at j: Int) -> (Int, Int)? {
        if ["eine", "a", "an", "una", "une"].contains(word(j)), ["halbe", "half", "media", "demi"].contains(word(j + 1)), SpokenWords.hourWords.contains(word(j + 2)) {
            return (30, j + 2)
        }
        if word(j) == "half", ["an", "a"].contains(word(j + 1)), SpokenWords.hourWords.contains(word(j + 2)) { return (30, j + 2) }
        if ["anderthalb", "eineinhalb"].contains(word(j)), SpokenWords.hourWords.contains(word(j + 1)) { return (90, j + 1) }
        if word(j) == "an", word(j + 1) == "hour", word(j + 2) == "and", word(j + 3) == "a", word(j + 4) == "half" { return (90, j + 4) }
        let n = ["a", "an", "eine", "una", "une"].contains(word(j)) ? 1 : SpokenWords.number(word(j))
        guard let n, (1...1440).contains(n) else { return nil }
        if SpokenWords.hourWords.contains(word(j + 1)) { return (n * 60, j + 1) }
        if SpokenWords.minuteWords.contains(word(j + 1)) { return (n, j + 1) }
        return nil
    }

    mutating func wholeDay() {
        for i in tokens.indices where free(i) {
            if SpokenWords.allDayWords.contains(word(i)) {
                allDay = true
                use(i..<(i + 1))
            } else if let phrase = phrase(in: SpokenWords.allDayIndex, at: i) {
                allDay = true
                use(i..<(i + phrase.count))
            }
        }
    }
}
