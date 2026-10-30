// Zusammenhang: Model/Entry.swift, Library/EntryLibrary.swift, Paralist/Entry/EntryMenu.swift
import Foundation

public enum EntryChanges {
    public static func withType(_ entry: Entry, _ type: EntryType) -> Entry {
        if type == entry.type { return entry }
        var e = entry
        e.type = type
        let status = EntryStatus.valid(entry.status, for: e)
        e.status = status
        e.doneAt = status == .done ? entry.doneAt : nil
        e.due = (type == .task || type == .project) ? entry.due : nil
        e.start = type == .event ? entry.start : nil
        e.end = type == .event ? entry.end : nil
        e.allDay = type == .event && entry.allDay
        e.places = type.isContainer ? [] : entry.places
        e.deck = type == .flashcard ? entry.deck : nil
        e.options = type == .flashcard ? entry.options : []
        e.correctOption = type == .flashcard ? entry.correctOption : nil
        e.tagKind = type == .tag ? entry.tagKind : nil
        return e
    }

    public static func withLink(_ entry: Entry, _ other: String, linked: Bool) -> Entry {
        if other == entry.id { return entry }
        var links: [String]
        if linked {
            links = entry.links
            if !links.contains(other) { links.append(other) }
        } else {
            links = entry.links.filter { $0 != other }
        }
        if links == entry.links { return entry }
        var e = entry
        e.links = links
        return e
    }

    public static func withoutReferences(_ entry: Entry, _ gone: Set<String>) -> Entry {
        let links = entry.links.filter { !gone.contains($0) }
        let places = entry.places.filter { !gone.contains($0) }
        let deck = entry.deck.flatMap { gone.contains($0) ? nil : $0 }
        if links.count == entry.links.count && places.count == entry.places.count && deck == entry.deck { return entry }
        var e = entry
        e.links = links
        e.places = places
        e.deck = deck
        return e
    }
}
