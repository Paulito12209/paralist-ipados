// Zusammenhang: Planning/SpokenParser.swift, Planning/SpokenDates.swift, Planning/SpokenTimes.swift, Planning/SpokenEvent.swift, Planning/DayPeriods.swift
import Foundation

enum SpokenWords {
    static let numbers: [String: Int] = [
        "null": 0, "ein": 1, "eins": 1, "eine": 1, "einen": 1, "einem": 1, "einer": 1, "zwei": 2, "drei": 3, "vier": 4,
        "fünf": 5, "fuenf": 5, "sechs": 6, "sieben": 7, "acht": 8, "neun": 9, "zehn": 10, "elf": 11, "zwölf": 12, "zwoelf": 12,
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12, "twenty": 20,
        "una": 1, "uno": 1, "dos": 2, "tres": 3, "cuatro": 4, "cinco": 5, "seis": 6, "siete": 7, "ocho": 8, "nueve": 9,
        "diez": 10, "once": 11, "doce": 12,
        "une": 1, "un": 1, "deux": 2, "trois": 3, "quatre": 4, "cinq": 5, "sept": 7, "huit": 8, "neuf": 9, "dix": 10,
        "onze": 11, "douze": 12,
    ]

    static let weekdays: [String: Int] = [
        "montag": 1, "dienstag": 2, "mittwoch": 3, "donnerstag": 4, "freitag": 5, "samstag": 6, "sonnabend": 6, "sonntag": 7,
        "monday": 1, "tuesday": 2, "wednesday": 3, "thursday": 4, "friday": 5, "saturday": 6, "sunday": 7,
        "lunes": 1, "martes": 2, "miércoles": 3, "miercoles": 3, "jueves": 4, "viernes": 5, "sábado": 6, "sabado": 6, "domingo": 7,
        "lundi": 1, "mardi": 2, "mercredi": 3, "jeudi": 4, "vendredi": 5, "samedi": 6, "dimanche": 7,
    ]

    static let weekdayAbbr: [String: Int] = [
        "mo": 1, "di": 2, "mi": 3, "do": 4, "fr": 5, "sa": 6, "so": 7,
        "mon": 1, "tue": 2, "tues": 2, "wed": 3, "thu": 4, "thur": 4, "thurs": 4, "fri": 5, "sat": 6, "sun": 7,
    ]

    static let months: [String: Int] = [
        "januar": 1, "jänner": 1, "februar": 2, "märz": 3, "maerz": 3, "april": 4, "mai": 5, "juni": 6, "juli": 7,
        "august": 8, "september": 9, "oktober": 10, "november": 11, "dezember": 12,
        "january": 1, "february": 2, "march": 3, "may": 5, "june": 6, "july": 7, "october": 10, "december": 12,
        "jan": 1, "feb": 2, "mär": 3, "mrz": 3, "apr": 4, "jun": 6, "jul": 7, "aug": 8, "sep": 9, "sept": 9, "okt": 10, "oct": 10,
        "nov": 11, "dez": 12, "dec": 12,
        "enero": 1, "febrero": 2, "marzo": 3, "abril": 4, "mayo": 5, "junio": 6, "julio": 7, "agosto": 8, "septiembre": 9,
        "octubre": 10, "noviembre": 11, "diciembre": 12,
        "janvier": 1, "février": 2, "fevrier": 2, "mars": 3, "avril": 4, "juin": 6, "juillet": 7, "août": 8, "aout": 8,
        "septembre": 9, "octobre": 10, "novembre": 11, "décembre": 12, "decembre": 12,
    ]

    static let periods: [String: DayPeriod] = [
        "morgens": .morning, "früh": .morning, "frueh": .morning, "vormittags": .morning, "vormittag": .morning, "morning": .morning,
        "matin": .morning,
        "mittags": .noon, "mittag": .noon, "noon": .noon, "midday": .noon, "mediodía": .noon, "mediodia": .noon, "midi": .noon,
        "nachmittags": .afternoon, "nachmittag": .afternoon, "afternoon": .afternoon, "tarde": .afternoon,
        "après-midi": .afternoon, "apres-midi": .afternoon,
        "abends": .evening, "abend": .evening, "evening": .evening, "noche": .evening, "soir": .evening,
    ]

    static let weekdayParts: [String: DayPeriod] = ["morgen": .morning, "vormittag": .morning, "mittag": .noon, "nachmittag": .afternoon, "abend": .evening]

    static func weekdayCompound(_ word: String) -> (Int, DayPeriod)? {
        let w = word.hasSuffix("s") ? String(word.dropLast()) : word
        for (name, day) in weekdays where w.hasPrefix(name) && w.count > name.count {
            if let period = weekdayParts[String(w.dropFirst(name.count))] { return (day, period) }
        }
        return nil
    }

    static let nightWords: Set<String> = ["nachts", "nacht", "night", "tonight", "madrugada", "nuit"]
    static let midnightWords: Set<String> = ["mitternacht", "midnight", "medianoche", "minuit"]

    static let todayWords: Set<String> = ["heute", "today", "hoy", "aujourd'hui", "aujourd’hui"]
    static let tomorrowWords: Set<String> = ["morgen", "tomorrow", "mañana", "manana", "demain"]
    static let morningLike: Set<String> = ["morgen", "mañana", "manana"]
    static let afterTomorrowWords: Set<String> = ["übermorgen", "uebermorgen", "après-demain", "apres-demain"]
    static let yesterdayWords: Set<String> = ["gestern", "yesterday", "ayer"]
    static let beforeYesterdayWords: Set<String> = ["vorgestern", "anteayer", "avant-hier"]
    static let weekendWords: Set<String> = ["wochenende", "weekend", "week-end"]
    static let nextWords: Set<String> = ["nächste", "nächsten", "nächster", "naechste", "naechsten", "kommende", "kommenden", "kommender",
                                         "next", "coming", "próxima", "proxima", "próximo", "proximo", "prochaine", "prochain"]
    static let afterNextWords: Set<String> = ["übernächste", "übernächsten", "uebernaechste", "uebernaechsten"]

    static let lead: Set<String> = ["erstelle", "erstell", "stelle", "stell", "lege", "leg", "trag", "trage", "mach", "mache", "setze", "setz", "plane", "plan",
                                    "notiere", "notier", "create", "add", "make", "schedule", "set", "put"]
    static let leadFill: Set<String> = ["mir", "me", "bitte", "please", "einen", "ein", "eine", "a", "an", "up", "for"]
    static let fresh: Set<String> = ["neuer", "neuen", "neue", "neues", "new"]
    static let eventNouns: Set<String> = ["termin", "event", "appointment", "aufgabe", "task", "todo", "to-do", "erinnerung", "reminder"]
    static let leadPhrases: [[String]] = [
        ["erinnere", "mich", "daran"], ["erinnere", "mich", "an"], ["erinnere", "mich"], ["erinner", "mich", "an"], ["erinner", "mich"],
        ["remind", "me", "to"], ["remind", "me", "about"], ["remind", "me", "of"], ["remind", "me"],
        ["ich", "habe"], ["ich", "hab"], ["ich", "muss"], ["ich", "soll"], ["ich", "möchte"], ["ich", "will"], ["wir", "haben"],
        ["i", "have", "to"], ["i", "have", "a"], ["i", "have", "an"], ["i", "have"], ["i", "need", "to"], ["i", "must"], ["i", "want", "to"],
        ["we", "have"], ["wir", "müssen"], ["wir", "sollen"], ["wir", "wollen"],
        ["denk", "dran"], ["denk", "daran"], ["denke", "dran"], ["denke", "daran"], ["nicht", "vergessen"], ["vergiss", "nicht"],
        ["don't", "forget", "to"], ["dont", "forget", "to"], ["do", "not", "forget", "to"], ["don't", "forget"], ["dont", "forget"],
    ]
    static let fillers: Set<String> = ["ähm", "äh", "öhm", "ehm", "hm", "hmm", "uh", "uhm", "erm"]
    static let leadFillers: Set<String> = ["also", "okay", "ok", "bitte", "please", "naja"]
    static let leadAdverbs: Set<String> = ["unbedingt", "noch", "mal", "auch", "dann", "bitte"]
    static let reminderLeftovers: Set<String> = ["an", "ans", "daran", "dran"]
    static let reminderWords: Set<String> = ["erinnerung", "reminder", "erinnere", "erinner", "remind"]
    static let sameTimePhrases: [[String]] = [["um", "dieselbe", "uhrzeit"], ["um", "die", "gleiche", "uhrzeit"], ["um", "diese", "uhrzeit"],
                                              ["zu", "dieser", "uhrzeit"], ["zu", "dieser", "zeit"], ["um", "die", "uhrzeit"], ["um", "die", "zeit"],
                                              ["dieselbe", "uhrzeit"], ["die", "gleiche", "uhrzeit"], ["gleiche", "uhrzeit"], ["diese", "uhrzeit"],
                                              ["zur", "selben", "zeit"], ["zur", "gleichen", "zeit"], ["at", "the", "same", "time"], ["at", "this", "time"],
                                              ["at", "that", "time"], ["the", "same", "time"], ["same", "time"]]
    static let reminderPhrases: [[String]] = [
        ["erinnere", "mich", "bitte", "daran"], ["erinnere", "mich", "daran"], ["erinnere", "mich", "dran"], ["erinnere", "mich"],
        ["erinner", "mich", "daran"], ["erinner", "mich"], ["erinnert", "mich"],
        ["stelle", "mir", "einen", "reminder"], ["stell", "mir", "einen", "reminder"], ["stelle", "mir", "eine", "erinnerung"], ["stell", "mir", "eine", "erinnerung"],
        ["stelle", "einen", "reminder"], ["stell", "einen", "reminder"], ["stelle", "eine", "erinnerung"], ["stell", "eine", "erinnerung"],
        ["setze", "einen", "reminder"], ["setz", "einen", "reminder"], ["setze", "eine", "erinnerung"], ["setz", "eine", "erinnerung"],
        ["erstelle", "mir", "einen", "reminder"], ["erstelle", "mir", "eine", "erinnerung"], ["erstelle", "einen", "reminder"], ["erstelle", "eine", "erinnerung"],
        ["erstell", "mir", "einen", "reminder"], ["erstell", "mir", "eine", "erinnerung"], ["mach", "mir", "einen", "reminder"], ["mach", "mir", "eine", "erinnerung"],
        ["mache", "mir", "einen", "reminder"], ["mache", "mir", "eine", "erinnerung"], ["leg", "mir", "einen", "reminder"], ["lege", "mir", "eine", "erinnerung"],
        ["erinnerung", "stellen"], ["reminder", "stellen"], ["erinnerung", "setzen"], ["reminder", "setzen"], ["erinnerung", "einstellen"],
        ["reminder", "einstellen"], ["erinnerung", "erstellen"], ["reminder", "erstellen"], ["erinnerung", "anlegen"], ["reminder", "anlegen"],
        ["mit", "erinnerung"], ["mit", "reminder"], ["als", "erinnerung"], ["als", "reminder"], ["einen", "reminder"], ["eine", "erinnerung"],
        ["remind", "me", "about", "it"], ["remind", "me", "about", "this"], ["remind", "me", "to"], ["remind", "me", "about"], ["remind", "me", "of"],
        ["remind", "me"], ["set", "me", "a", "reminder"], ["set", "a", "reminder"], ["create", "a", "reminder"], ["add", "a", "reminder"],
        ["with", "a", "reminder"], ["with", "reminder"], ["as", "a", "reminder"], ["a", "reminder"],
        ["erinnerung"], ["reminder"],
    ]
    static let reminderLead: Set<String> = ["und", "and", "bitte", "please", "außerdem", "also", "dann", "sowie", "plus"]
    static let reminderTail: Set<String> = ["bitte", "please", "daran", "dran", "noch", "dazu", "auch"]
    static let articles: Set<String> = ["einen", "eine", "ein", "a", "an", "die", "der", "das", "den", "dem", "the"]
    static let clauseOpeners: [[String]] = [["dass", "ich"], ["dass", "wir"], ["dass", "du"], ["das", "ich"], ["that", "i"], ["that", "we"], ["that", "you"]]
    static let clauseVerbs: [[String]] = [["have", "to"], ["need", "to"], ["must"], ["should"], ["want", "to"], ["muss"], ["soll"], ["will"], ["möchte"]]
    static let modals: Set<String> = ["muss", "müssen", "musst", "soll", "sollen", "sollst", "sollte", "sollten", "will", "wollen", "willst",
                                      "möchte", "möchten", "kann", "können", "könnte", "darf", "dürfen", "should", "must"]

    static let junk: Set<String> = lead.union(leadFill).union(fresh).union(linkers).union(reminderLead).union(reminderTail).union(articles)

    static func index(_ phrases: [[String]]) -> [String: [[String]]] {
        var out: [String: [[String]]] = [:]
        for phrase in phrases where !phrase.isEmpty { out[phrase[0], default: []].append(phrase) }
        return out
    }

    static let reminderIndex = index(reminderPhrases)
    static let sameTimeIndex = index(sameTimePhrases)
    static let allDayIndex = index(allDayPhrases)
    static let trailing: Set<String> = ["eintragen", "einplanen", "anlegen", "erstellen", "speichern", "notieren", "hinzufügen", "vormerken",
                                        "bitte", "please", "danke", "thanks"]
    static let linkers: Set<String> = ["am", "um", "ab", "von", "bis", "gegen", "für", "fuer", "at", "on", "from", "to", "until", "till", "by",
                                       "for", "a", "à", "le", "de", "desde", "hasta", "en", "el", "la", "las", "au", "du", "zum", "zur", "im",
                                       "in", "around", "por"]

    static let dayWords: Set<String> = ["tag", "tagen", "tage", "day", "days", "día", "días", "dia", "dias", "jour", "jours"]
    static let weekWords: Set<String> = ["woche", "wochen", "week", "weeks", "semana", "semanas", "semaine", "semaines"]
    static let monthWords: Set<String> = ["monat", "monate", "monaten", "month", "months", "mes", "meses", "mois"]
    static let hourWords: Set<String> = ["stunde", "stunden", "std", "hour", "hours", "h", "hora", "horas", "heure", "heures"]
    static let minuteWords: Set<String> = ["minute", "minuten", "min", "mins", "minutes", "minuto", "minutos"]
    static let clockWords: Set<String> = ["uhr", "o'clock", "oclock", "h", "heures", "heure", "horas", "hrs"]
    static let rangeWords: Set<String> = ["bis", "to", "until", "till", "-", "hasta", "à", "jusqu'à", "jusqu’à", "jusqua"]
    static let andWords: Set<String> = ["und", "and", "y", "et"]
    static let betweenWords: Set<String> = ["zwischen", "between", "entre"]
    static let timePreps: Set<String> = ["um", "at", "gegen", "ab", "von", "from", "so", "ca", "circa", "etwa", "around", "spätestens",
                                         "a", "las", "la", "à", "vers", "hacia", "de", "dès", "des"]
    static let dayPreps: Set<String> = ["am", "on", "den", "dem", "the", "diesen", "dieser", "this", "next", "coming",
                                        "nächsten", "nächster", "nächste", "naechsten", "kommenden", "kommender", "el", "le", "ce", "este",
                                        "bis", "until", "by", "spätestens", "zum"]
    static let periodPreps: Set<String> = ["am", "in", "the", "zu", "at", "this", "por", "la", "le", "en", "de"]
    static let durationPreps: Set<String> = ["für", "fuer", "for", "durante", "pendant"]
    static let longWords: Set<String> = ["lang"]
    static let allDayWords: Set<String> = ["ganztägig", "ganztaegig", "ganztags", "allday", "all-day"]
    static let allDayPhrases: [[String]] = [["den", "ganzen", "tag"], ["all", "day"], ["the", "whole", "day"], ["todo", "el", "día"],
                                            ["todo", "el", "dia"], ["toute", "la", "journée"], ["toute", "la", "journee"]]

    static func number(_ word: String) -> Int? {
        if let value = Int(word), word.count <= 4 { return value }
        return numbers[word]
    }

    static func ordinal(_ word: String) -> Int? {
        var w = word
        for suffix in ["st", "nd", "rd", "th", "ter", "ten", "er", "e"] where w.hasSuffix(suffix) && w.count > suffix.count {
            w = String(w.dropLast(suffix.count))
            break
        }
        guard let value = Int(w), (1...31).contains(value) else { return nil }
        return value
    }

    static func meridiem(_ word: String) -> Bool? {
        switch word {
        case "pm", "p.m", "p.m.": return true
        case "am", "a.m", "a.m.": return false
        default: return nil
        }
    }
}
