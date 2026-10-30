// Zusammenhang: Planning/SpokenParser.swift, Planning/SpokenWords.swift, Planning/SpokenTimes.swift, Model/Day.swift
import Foundation

extension SpokenParser {
    private static let numericDate = Pattern("^(\\d{1,2})\\.(\\d{1,2})(?:\\.(\\d{2}|\\d{4}))?$")

    mutating func dates(today: Day) {
        var i = 0
        while i < tokens.count {
            defer { i += 1 }
            guard free(i) else { continue }
            let w = word(i)
            if let (minutes, next) = relativeMinutes(i) {
                inMinutes = minutes
                use(i..<next)
                continue
            }
            if let (found, next) = relative(i, today: today) {
                day = found
                if w == "tonight" && period == nil { period = .evening }
                use(i..<next)
                continue
            }
            if SpokenWords.tomorrowWords.contains(w) {
                let before = word(i - 1)
                let morning = SpokenWords.morningLike.contains(w) &&
                    (day != nil || before == "heute" || before == "am" || before == "por" || before == "la" || SpokenWords.weekdays[before] != nil)
                if morning {
                    if period == nil { period = .morning }
                    use(i..<(i + 1))
                    eatBack(i, ["am", "por", "la", "en"])
                } else if day == nil {
                    day = today.adding(days: 1)
                    use(i..<(i + 1))
                }
                continue
            }
            if let (found, lower, upper) = week(i, today: today) {
                day = found
                use(lower..<upper)
                eatBack(lower, SpokenWords.dayPreps.union(["la", "de", "en"]))
                continue
            }
            guard day == nil || byWeekday else { continue }
            if day == nil, let target = SpokenWords.weekdays[w] ?? (dotted(i) ? SpokenWords.weekdayAbbr[w] : nil) ?? SpokenWords.weekdayCompound(w)?.0 {
                var ahead = (target - today.weekday + 7) % 7
                if ahead == 0 { ahead = 7 }
                day = today.adding(days: ahead)
                byWeekday = true
                if period == nil, let part = SpokenWords.weekdayCompound(w)?.1 { period = part }
                use(i..<(i + 1))
                eatBack(i, SpokenWords.dayPreps)
            } else if let found = absolute(i, today: today) {
                byWeekday = false
                day = found.0
                use(i..<found.1)
                eatBack(i, SpokenWords.dayPreps)
            }
        }
    }

    private func relative(_ i: Int, today: Day) -> (Day, Int)? {
        let w = word(i)
        if w == "in" || w == "en" || w == "dans" {
            let n = ["a", "an", "einem", "einer", "un", "una", "une"].contains(word(i + 1)) ? 1 : SpokenWords.number(word(i + 1))
            guard let n, (0...365).contains(n) else { return nil }
            let base = day ?? today
            if SpokenWords.dayWords.contains(word(i + 2)) { return (base.adding(days: n), i + 3) }
            if SpokenWords.weekWords.contains(word(i + 2)) { return (base.adding(days: 7 * n), i + 3) }
            if SpokenWords.monthWords.contains(word(i + 2)) { return (base.adding(months: n), i + 3) }
            return nil
        }
        guard day == nil else { return nil }
        if SpokenWords.todayWords.contains(w) { return (today, i + 1) }
        if w == "tonight" { return (today, i + 1) }
        if SpokenWords.afterTomorrowWords.contains(w) { return (today.adding(days: 2), i + 1) }
        if SpokenWords.yesterdayWords.contains(w) { return (today.adding(days: -1), i + 1) }
        if SpokenWords.beforeYesterdayWords.contains(w) { return (today.adding(days: -2), i + 1) }
        if matches(["pasado", "mañana"], at: i) || matches(["pasado", "manana"], at: i) { return (today.adding(days: 2), i + 2) }
        if matches(["day", "after", "tomorrow"], at: i) { return (today.adding(days: 2), i + 3) }
        if matches(["the", "day", "after", "tomorrow"], at: i) { return (today.adding(days: 2), i + 4) }
        if matches(["day", "before", "yesterday"], at: i) { return (today.adding(days: -2), i + 3) }
        if matches(["the", "day", "before", "yesterday"], at: i) { return (today.adding(days: -2), i + 4) }
        return nil
    }

    private func relativeMinutes(_ i: Int) -> (Int, Int)? {
        guard ["in", "en", "dans"].contains(word(i)) else { return nil }
        let j = i + 1
        if ["einer", "a", "an", "una", "une"].contains(word(j)), ["halben", "half"].contains(word(j + 1)) || word(j + 1) == "media",
           SpokenWords.hourWords.contains(word(j + 2)) { return (30, j + 3) }
        if word(j) == "half", ["an", "a"].contains(word(j + 1)), SpokenWords.hourWords.contains(word(j + 2)) { return (30, j + 3) }
        if ["anderthalb", "eineinhalb"].contains(word(j)), SpokenWords.hourWords.contains(word(j + 1)) { return (90, j + 2) }
        let n = ["a", "an", "einer", "einem", "un", "una", "une"].contains(word(j)) ? 1 : SpokenWords.number(word(j))
        guard let n, (1...1440).contains(n) else { return nil }
        if SpokenWords.hourWords.contains(word(j + 1)) { return (n * 60, j + 2) }
        if SpokenWords.minuteWords.contains(word(j + 1)) { return (n, j + 2) }
        return nil
    }

    private func week(_ i: Int, today: Day) -> (Day, Int, Int)? {
        let w = word(i)
        if SpokenWords.weekendWords.contains(w) || matches(["fin", "de", "semana"], at: i) {
            guard day == nil else { return nil }
            let ahead = today.weekday >= 6 ? 0 : 6 - today.weekday
            return (today.adding(days: ahead), i, i + (w == "fin" ? 3 : 1))
        }
        var step = SpokenWords.nextWords.contains(w) ? 1 : SpokenWords.afterNextWords.contains(w) ? 2 : 0
        var noun = i + 1
        if step == 0, SpokenWords.weekWords.contains(w) {
            if SpokenWords.nextWords.contains(word(i + 1)) { return (today.adding(days: 7), i, i + 2) }
            if matches(["que", "viene"], at: i + 1) { return (today.adding(days: 7), i, i + 3) }
            return nil
        }
        if step == 0, SpokenWords.monthWords.contains(w), SpokenWords.nextWords.contains(word(i + 1)) {
            return (today.adding(months: 1), i, i + 2)
        }
        guard step > 0 else { return nil }
        if SpokenWords.monthWords.contains(word(noun)) { return (today.adding(months: step), i, noun + 1) }
        guard SpokenWords.weekWords.contains(word(noun)) else { return nil }
        let monday = today.adding(days: 1 - today.weekday + 7 * step)
        var after = noun + 1
        if ["am", "on"].contains(word(after)) { after += 1 }
        if let t = SpokenWords.weekdays[word(after)], free(after) { return (monday.adding(days: t - 1), i, after + 1) }
        if let t = SpokenWords.weekdays[word(i - 1)] { return (monday.adding(days: t - 1), free(i - 1) ? i - 1 : i, noun + 1) }
        step = max(step, 1)
        noun += 1
        return (today.adding(days: 7 * step), i, noun)
    }

    private func absolute(_ i: Int, today: Day) -> (Day, Int)? {
        let w = word(i)
        if w.first?.isNumber == true, let m = Self.numericDate.first(in: w) {
            let timeLike = SpokenWords.clockWords.contains(word(i + 1)) || SpokenWords.timePreps.contains(word(i - 1))
            guard !timeLike, let d = Int(m.group(1)), let mo = Int(m.group(2)) else { return nil }
            let year = Int(m.group(3)).map { $0 < 100 ? 2000 + $0 : $0 }
            return make(d, mo, year, today: today).map { ($0, i + 1) }
        }
        if let d = SpokenWords.ordinal(w) {
            var j = i + 1
            if word(j) == "of" || word(j) == "de" { j += 1 }
            if let mo = SpokenWords.months[word(j)] {
                let year = yearAt(j + 1)
                return make(d, mo, year, today: today).map { ($0, j + 1 + (year == nil ? 0 : 1)) }
            }
            let marked = dotted(i) || Int(w) == nil
            guard marked, SpokenWords.dayPreps.contains(word(i - 1)), !SpokenWords.clockWords.contains(word(i + 1)) else { return nil }
            return upcoming(d, today: today).map { ($0, i + 1) }
        }
        if let mo = SpokenWords.months[w], let d = SpokenWords.ordinal(word(i + 1)) {
            let year = yearAt(i + 2)
            return make(d, mo, year, today: today).map { ($0, i + 2 + (year == nil ? 0 : 1)) }
        }
        return nil
    }

    private func yearAt(_ i: Int) -> Int? {
        guard let y = Int(word(i)), (2000...2100).contains(y) else { return nil }
        return y
    }

    private func upcoming(_ d: Int, today: Day) -> Day? {
        for shift in 0...2 {
            let m = today.adding(months: shift)
            guard d <= Day.length(of: m.month, in: m.year) else { continue }
            let candidate = Day(year: m.year, month: m.month, day: d)
            if candidate >= today { return candidate }
        }
        return nil
    }

    private func make(_ d: Int, _ m: Int, _ year: Int?, today: Day) -> Day? {
        guard (1...12).contains(m) else { return nil }
        var y = year ?? today.year
        guard d >= 1, d <= Day.length(of: m, in: y) else { return nil }
        if year == nil && Day(year: y, month: m, day: d) < today {
            y += 1
            guard d <= Day.length(of: m, in: y) else { return nil }
        }
        return Day(year: y, month: m, day: d)
    }
}
