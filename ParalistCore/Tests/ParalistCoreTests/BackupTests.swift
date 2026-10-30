// Zusammenhang: Sources/ParalistCore/Backup/*.swift, ZipFixtures.swift
import Foundation
import Testing
@testable import ParalistCore

struct ChecksumTests {
    @Test func knownVectors() {
        #expect(CRC32.checksum(Data("123456789".utf8)) == 0xCBF4_3926)
        #expect(SHA256.hex(Data()) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        #expect(SHA256.hex(Data("abc".utf8)) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        #expect(SHA256.hex(Data(String(repeating: "a", count: 1000).utf8)) == "41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3")
    }
}

struct SafeUnzipTests {
    private func expect(_ reason: BackupRejected.Reason, limits: BackupLimits = BackupLimits(), _ zip: URL) {
        let staging = temporaryDirectory().appendingPathComponent("staging")
        do {
            _ = try SafeUnzip.extract(zip, to: staging, limits: limits)
            Issue.record("erwartet: \(reason)")
        } catch let error as BackupRejected {
            #expect(error.reason == reason)
            #expect(!FileManager.default.fileExists(atPath: staging.path))
        } catch {
            Issue.record("falscher Fehler: \(error)")
        }
    }

    @Test func rejectsPathTraversalAndAbsolutePaths() {
        for name in ["../evil.md", "eintraege/../../evil.md", "/data/data/app.paralist/x", "C:/x", "eintraege\\..\\x", "./eintraege/a.md"] {
            expect(.unsafePath, ZipFixtures.zip([(name, Data("x".utf8))]))
        }
    }

    @Test func rejectsSymlinks() {
        expect(.symlink, ZipFixtures.markSymlink(ZipFixtures.zip([("eintraege/link-1.md", Data("/etc/passwd".utf8))]), "eintraege/link-1.md"))
    }

    @Test func rejectsZipBomb() {
        expect(.suspiciousRatio, ZipFixtures.write(ZipFixtures.deflateBomb))
    }

    @Test func rejectsTooManyEntriesAndOversizedFiles() {
        var small = BackupLimits()
        small.maxEntries = 10
        small.maxFileBytes = 1_000
        expect(.tooManyEntries, limits: small, ZipFixtures.zip((1...11).map { ("x/\($0)", Data([1])) }))
        expect(.tooLarge, limits: small, ZipFixtures.zip([("anhaenge/" + String(repeating: "b", count: 64), Data(count: 2_000))]))
    }

    @Test func rejectsGarbage() {
        expect(.notAZip, ZipFixtures.write(Data("kein zip, nur text".utf8)))
    }

    @Test func extractsOnlyKnownLayoutIntoFreshStaging() throws {
        let zip = ZipFixtures.zip([
            ZipFixtures.entry("note-1", "Eins"),
            ("anhaenge/" + String(repeating: "c", count: 64), Data("%PDF-1.7".utf8)),
            ("lernverlauf/card-1.log", Data("2026-10-01T10:00:00Z 3\n".utf8)),
            ("paralist.json", Data("{}".utf8)),
            ("classes.dex", Data("dex".utf8)),
            ("eintraege/sub/x.md", Data("x".utf8)),
        ])
        let staged = try SafeUnzip.extract(zip, to: temporaryDirectory().appendingPathComponent("fresh"))
        let files = FileManager.default
        #expect(staged.ignored == 2)
        #expect(files.fileExists(atPath: staged.dir.appendingPathComponent("eintraege/note-1.md").path))
        #expect(files.fileExists(atPath: staged.dir.appendingPathComponent("anhaenge/" + String(repeating: "c", count: 64)).path))
        #expect(files.fileExists(atPath: staged.dir.appendingPathComponent("lernverlauf/card-1.log").path))
        #expect(!files.fileExists(atPath: staged.dir.appendingPathComponent("classes.dex").path))
    }

    @Test func readsDeflatedAndroidBackups() throws {
        let staged = try SafeUnzip.extract(ZipFixtures.write(ZipFixtures.androidDeflate), to: temporaryDirectory().appendingPathComponent("android"))
        let note = try String(contentsOf: staged.dir.appendingPathComponent("eintraege/note-1.md"), encoding: .utf8)
        let entry = try EntryCodec.decode(note, now: at("2026-10-16T12:00:00Z"))
        #expect(entry.title == "Eins aus Android")
        #expect(entry.body.hasPrefix("Text mit Wiederholung."))
        #expect(try Data(contentsOf: staged.dir.appendingPathComponent("anhaenge/" + String(repeating: "c", count: 64))) == Data("%PDF-1.7".utf8))
        #expect(try Data(contentsOf: staged.dir.appendingPathComponent("paralist.json")) == ZipFixtures.randomBytes)
        #expect(try String(contentsOf: staged.dir.appendingPathComponent("lernverlauf/note-1.log"), encoding: .utf8) == "2026-10-01T10:00:00Z 3\n")
    }

    @Test func corruptedDataIsRejected() {
        var bytes = [UInt8](ZipFixtures.androidDeflate)
        bytes[60] ^= 0xFF
        expect(.unreadable, ZipFixtures.write(Data(bytes)))
    }
}
