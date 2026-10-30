// Zusammenhang: Markdown/EntryCodec.swift, Markdown/FrontMatter.swift, Markdown/Limits.swift, Markdown/Instants.swift
import Foundation
import Testing
@testable import ParalistCore

struct EntryCodecTests {
    private let now = at("2026-10-16T12:00:00Z")

    private func sample() -> Entry {
        Entry("abc-123", .task, "Einkaufen: Milch \"frisch\"", at("2026-10-01T08:00:00Z"), at("2026-10-02T09:30:00Z")) {
            $0.places = ["proj-1"]
            $0.due = Day(year: 2026, month: 10, day: 20)
            $0.status = .open
            $0.favorite = true
            $0.reminders = [at("2026-10-20T07:00:00Z")]
            $0.url = "https://example.org/a?b=c"
            $0.attachment = Attachment(hash: String(repeating: "a", count: 64), name: "bild.jpg", mime: "image/jpeg", size: 1234)
            $0.body = "# Notizen\n\n- eins\n"
            $0.links = ["link-9"]
            $0.extras = ["fremd": "wert"]
        }
    }

    @Test func roundTrip() throws {
        let entry = sample()
        let decoded = try EntryCodec.decode(EntryCodec.encode(entry), now: now)
        #expect(decoded == entry)
    }

    @Test func rejectsBrokenYaml() {
        #expect(throws: EntryParseError.self) { try EntryCodec.decode("---\nid: [\n---\n", now: now) }
        #expect(throws: EntryParseError.self) { try EntryCodec.decode("---\nid: abc-123\ntyp: aufgabe\n", now: now) }
    }

    @Test func rejectsPathLikeIds() {
        for bad in ["../etc", "a/b", "ABC", "x", String(repeating: "a", count: 65), ".."] {
            let text = "---\nid: \"\(bad)\"\ntyp: notiz\nerstellt: 2026-10-01T08:00:00Z\n---\n"
            #expect(throws: EntryParseError.self, "\(bad)") { try EntryCodec.decode(text, now: now) }
        }
    }

    @Test func rejectsImplausibleDates() {
        let old = "---\nid: abc-123\ntyp: notiz\nerstellt: 1999-12-31T00:00:00Z\n---\n"
        let far = "---\nid: abc-123\ntyp: notiz\nerstellt: 2026-10-01T08:00:00Z\nfaellig: 2300-01-01\n---\n"
        let junk = "---\nid: abc-123\ntyp: notiz\nerstellt: gestern\n---\n"
        for text in [old, far, junk] {
            #expect(throws: EntryParseError.self) { try EntryCodec.decode(text, now: now) }
        }
    }

    @Test func rejectsUnknownTypeStatusAndBadAttachment() {
        let base = "---\nid: abc-123\nerstellt: 2026-10-01T08:00:00Z\n"
        #expect(throws: EntryParseError.self) { try EntryCodec.decode("\(base)typ: virus\n---\n", now: now) }
        #expect(throws: EntryParseError.self) { try EntryCodec.decode("\(base)typ: aufgabe\nstatus: egal\n---\n", now: now) }
        #expect(throws: EntryParseError.self) {
            try EntryCodec.decode("\(base)typ: datei\nanhang_hash: ../../x\n---\n", now: now)
        }
        #expect(throws: EntryParseError.self) {
            try EntryCodec.decode("\(base)typ: datei\nanhang_hash: \(String(repeating: "b", count: 64))\nanhang_name: ../evil.apk\n---\n", now: now)
        }
    }

    @Test func rejectsOversizedFileAndTitle() {
        let big = "---\nid: abc-123\ntyp: notiz\nerstellt: 2026-10-01T08:00:00Z\n---\n" + String(repeating: "x", count: Limits.maxFileBytes)
        #expect(throws: EntryParseError.self) { try EntryCodec.decode(big, now: now) }
        let title = "---\nid: abc-123\ntyp: notiz\nerstellt: 2026-10-01T08:00:00Z\ntitel: \"\(String(repeating: "t", count: 501))\"\n---\n"
        #expect(throws: EntryParseError.self) { try EntryCodec.decode(title, now: now) }
    }

    @Test func keepsUnknownKeysOnRewrite() throws {
        let text = "---\nid: abc-123\ntyp: notiz\nerstellt: 2026-10-01T08:00:00Z\nfarbe: rot\n---\nHallo\n"
        let entry = try EntryCodec.decode(text, now: now)
        #expect(entry.extras["farbe"] == "rot")
        let again = try EntryCodec.decode(EntryCodec.encode(entry), now: now)
        #expect(again.extras["farbe"] == "rot")
        #expect(again.body == "Hallo\n")
    }
}

struct FrontMatterTests {
    @Test func roundTripsScalarsAndLists() throws {
        let fields: [(String, YamlValue)] = [
            ("id", .scalar("abcd-1234")),
            ("titel", .scalar("Zeile: eins \"zwei\"\nneu")),
            ("orte", .items(["p-1", "a 2"])),
            ("leer", .items([])),
        ]
        let text = FrontMatter.write(fields, body: "Körper\n")
        let parsed = try FrontMatter.parse(text)
        #expect(parsed.keys == fields.map(\.0))
        #expect(parsed.fields == Dictionary(uniqueKeysWithValues: fields))
        #expect(parsed.body == "Körper\n")
    }

    @Test func rejectsMissingOrUnclosedHead() {
        #expect(throws: FrontMatterError.self) { try FrontMatter.parse("Kein Kopf") }
        #expect(throws: FrontMatterError.self) { try FrontMatter.parse("---\nid: x\nohne Ende") }
    }

    @Test func rejectsDuplicateKeysAndBadKeys() {
        #expect(throws: FrontMatterError.self) { try FrontMatter.parse("---\nid: a\nid: b\n---\n") }
        #expect(throws: FrontMatterError.self) { try FrontMatter.parse("---\n../x: a\n---\n") }
        #expect(throws: FrontMatterError.self) { try FrontMatter.parse("---\n  - ohne Schlüssel\n---\n") }
    }

    @Test func rejectsOversizedHeadAndLists() {
        let huge = "---\n" + "k: " + String(repeating: "x", count: Limits.maxFrontMatterChars) + "\n---\n"
        #expect(throws: FrontMatterError.self) { try FrontMatter.parse(huge) }
        let list = "---\norte:\n" + String(repeating: "  - a\n", count: Limits.maxListItems + 1) + "---\n"
        #expect(throws: FrontMatterError.self) { try FrontMatter.parse(list) }
    }

    @Test func rejectsUnknownEscapes() {
        #expect(throws: FrontMatterError.self) { try FrontMatter.parse("---\nt: \"\\x41\"\n---\n") }
    }

    @Test func bodyMayContainFences() throws {
        let parsed = try FrontMatter.parse("---\nid: a\n---\nText\n---\nmehr\n")
        #expect(parsed.body == "Text\n---\nmehr\n")
    }
}
