// Zusammenhang: Sources/ParalistCore/Chat/*.swift, Sources/ParalistCore/Backup/*.swift, ZipFixtures.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct ChatModelTests {
    private let now = at("2026-10-21T10:00:00Z")

    private func message(_ id: String, _ role: ChatRole, _ text: String, _ minute: Int = 0) -> ChatMessage {
        ChatMessage(id: id, role: role, text: text, at: now.addingTimeInterval(Double(minute) * 60))
    }

    @Test func firstUserMessageNamesTheThread() {
        var thread = ChatThread(id: "chat-1", created: now)
        thread.append(message("msg-1", .assistant, "Hallo"))
        #expect(thread.title.isEmpty)
        thread.append(message("msg-2", .user, "## Was steht **diese Woche** an?\nUnd danach?", 1))
        #expect(thread.title == "Was steht diese Woche an?")
        thread.append(message("msg-3", .user, "Etwas anderes", 2))
        #expect(thread.title == "Was steht diese Woche an?")
        #expect(thread.updated == now.addingTimeInterval(120))
    }

    @Test func aMessageWithoutTextTakesTheFallbackTitle() {
        var thread = ChatThread(id: "chat-1", created: now)
        var mention = message("msg-1", .user, "")
        mention.mentions = ["entry-1"]
        thread.append(mention, fallbackTitle: "  Schichtplan  ")
        #expect(thread.title == "Schichtplan")
        var other = ChatThread(id: "chat-2", created: now)
        other.append(message("msg-1", .user, "", 0))
        #expect(other.messages.isEmpty && other.title.isEmpty)
        other.append(ChatMessage(id: "msg-2", role: .user, text: "", at: now, attachment: String(repeating: "a", count: 64)))
        #expect(other.messages.count == 1 && other.title.isEmpty)
        other.append(message("msg-3", .user, "Was steht drauf?", 1), fallbackTitle: "Egal")
        #expect(other.title == "Was steht drauf?")
    }

    @Test func longTitlesAreCutAtAWord() {
        let title = ChatTitle.from("Fasse bitte das Projekt Umzug nach Leipzig mit allen offenen Aufgaben zusammen")
        #expect(title == "Fasse bitte das Projekt Umzug nach…")
        #expect(ChatTitle.from(String(repeating: "x", count: 60)) == String(repeating: "x", count: 40) + "…")
        #expect(ChatTitle.from("\n\n  \n- [ ] Liste") == "Liste")
    }

    @Test func emptyMessagesAreDroppedAndLongOnesClipped() {
        var thread = ChatThread(id: "chat-1", created: now)
        thread.append(message("msg-1", .user, "   \n "))
        #expect(thread.messages.isEmpty)
        thread.append(message("msg-2", .user, String(repeating: "a", count: ChatCodec.maxMessageChars + 50)))
        #expect(thread.messages.first?.text.count == ChatCodec.maxMessageChars)
    }

    @Test func renameIgnoresBlankAndCollapsesSpaces() {
        var thread = ChatThread(id: "chat-1", title: "Alt", created: now)
        thread.rename("   ")
        #expect(thread.title == "Alt")
        thread.rename("  Neuer   Titel \n")
        #expect(thread.title == "Neuer Titel")
    }

    @Test func previewShowsLastMessageWithoutMarkdown() {
        var thread = ChatThread(id: "chat-1", created: now)
        #expect(ChatPreview.of(thread).isEmpty)
        thread.append(message("msg-1", .user, "Frage"))
        thread.append(message("msg-2", .assistant, "# Woche\n\n- **Umzugskartons** bestellen\n- [Zahnarzt](paralist-ipad://eintrag/x) anrufen\n> `Notiz`", 1))
        #expect(ChatPreview.of(thread) == "Woche Umzugskartons bestellen Zahnarzt anrufen Notiz")
        thread.append(message("msg-3", .user, String(repeating: "wort ", count: 60), 2))
        #expect(ChatPreview.of(thread).count == ChatPreview.maxChars + 1)
        #expect(ChatPreview.of(thread).hasSuffix("…"))
    }

    @Test func searchMatchesTitleAndMessagesByWordPrefix() {
        var a = ChatThread(id: "chat-a", title: "Umzug", created: now, updated: now)
        a.messages = [message("msg-1", .user, "Kartons bestellen")]
        let b = ChatThread(id: "chat-b", title: "Spanisch üben", created: now, updated: now.addingTimeInterval(60))
        #expect(ChatList.filter([a, b], query: "").map(\.id) == ["chat-b", "chat-a"])
        #expect(ChatList.filter([a, b], query: "kart").map(\.id) == ["chat-a"])
        #expect(ChatList.filter([a, b], query: "ÜBEN").map(\.id) == ["chat-b"])
        #expect(ChatList.filter([a, b], query: "umzug best").map(\.id) == ["chat-a"])
        #expect(ChatList.filter([a, b], query: "arton").isEmpty)
    }
}

struct ChatCodecTests {
    private let now = at("2026-10-21T10:00:00Z")

    private func sample() -> ChatThread {
        ChatThread(id: "chat-1", title: "Woche \"plan\"", created: now, updated: now.addingTimeInterval(90), messages: [
            ChatMessage(id: "msg-1", role: .user, text: "Was steht an?\n## Zeile", at: now),
            ChatMessage(id: "msg-2", role: .assistant, text: "Nichts. 🎉 / ✓", at: now.addingTimeInterval(90.5)),
        ])
    }

    @Test func roundTripKeepsEverything() throws {
        let data = try ChatCodec.encode(sample())
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains("\"nachrichten\""))
        #expect(text.contains("\"rolle\" : \"modell\""))
        #expect(text.contains("\"geaendert\" : \"2026-10-21T10:01:30Z\""))
        #expect(try ChatCodec.decode(data) == sample())
    }

    @Test func rejectsHostileFiles() {
        func json(_ id: String = "chat-1", title: String = "T", messages: String = "[]", time: String = "2026-10-21T10:00:00Z") -> Data {
            Data("{\"format\":1,\"id\":\"\(id)\",\"titel\":\"\(title)\",\"erstellt\":\"\(time)\",\"geaendert\":\"\(time)\",\"nachrichten\":\(messages)}".utf8)
        }
        let msg = { (id: String, role: String) in "{\"id\":\"\(id)\",\"rolle\":\"\(role)\",\"text\":\"x\",\"zeit\":\"2026-10-21T10:00:00Z\"}" }
        #expect((try? ChatCodec.decode(json())) != nil)
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(Data("kein json".utf8)) }
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(json("../x")) }
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(json(title: String(repeating: "t", count: Limits.maxTitleChars + 1))) }
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(json(time: "gestern")) }
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(json(messages: "[\(msg("msg-1", "system"))]")) }
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(json(messages: "[\(msg("msg-1", "nutzer")),\(msg("msg-1", "modell"))]")) }
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(Data(count: ChatCodec.maxFileBytes + 1)) }
        let many = (0...ChatCodec.maxMessages).map { msg("msg-\($0)", "nutzer") }.joined(separator: ",")
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(json(messages: "[\(many)]")) }
    }
}

struct ChatStoreTests {
    private let now = at("2026-10-21T10:00:00Z")

    @Test func writeListRenameDelete() throws {
        let root = temporaryDirectory()
        let store = ChatStore(root: root, ids: CountingIds("chat"), clock: StepClock(now))
        #expect(store.all().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: store.dir.path))
        var first = store.draft(store.newId())
        first.append(store.message(.user, "Erster"))
        try store.write(first)
        var second = store.draft(store.newId())
        second.append(store.message(.user, "Zweiter"))
        try store.write(second)
        #expect(store.all().map(\.title) == ["Zweiter", "Erster"])
        try store.rename(first.id, "Umbenannt")
        #expect(store.all().map(\.title) == ["Umbenannt", "Zweiter"])
        #expect(try store.rename("chat-404", "x") == nil)
        #expect(store.delete(second.id))
        #expect(!store.delete(second.id))
        #expect(store.all().map(\.id) == [first.id])
        #expect(store.load(first.id)?.messages.first?.text == "Erster")
    }

    @Test func skipsBrokenAndMisnamedFiles() throws {
        let root = temporaryDirectory()
        let store = ChatStore(root: root, clock: FixedClock(now))
        var thread = store.draft("chat-good")
        thread.append(store.message(.user, "Hallo"))
        try store.write(thread)
        try Data("{".utf8).write(to: store.dir.appendingPathComponent("chat-bad.json"))
        try ChatCodec.encode(thread).write(to: store.dir.appendingPathComponent("chat-other.json"))
        #expect(store.all().map(\.id) == ["chat-good"])
        #expect(throws: EntryParseError.self) { try store.fileFor("../../x") }
    }
}

struct ChatBackupTests {
    private let now = at("2026-10-21T10:00:00Z")

    private func thread(_ id: String, _ title: String, updated: Date) -> ChatThread {
        ChatThread(id: id, title: title, created: now.addingTimeInterval(-86_400), updated: updated, messages: [
            ChatMessage(id: "msg-1", role: .user, text: title, at: now.addingTimeInterval(-86_400)),
        ])
    }

    private func plan(_ root: URL, _ zip: URL) throws -> ImportPlan {
        let staged = try SafeUnzip.extract(zip, to: temporaryDirectory().appendingPathComponent("st"))
        return try ImportPlanner(store: EntryStore(root: root, clock: FixedClock(now)), reviews: ReviewLog(root: root)) { data, _ in data }.plan(staged, now: now)
    }

    @Test func classifiesOnlyValidChatFiles() {
        #expect(BackupFormat.classify("chats/chat-1.json")?.area == .chats)
        #expect(BackupFormat.classify("chats/chat-1.md") == nil)
        #expect(BackupFormat.classify("chats/X.json") == nil)
        #expect(BackupFormat.classify("chats/sub/chat-1.json") == nil)
    }

    @Test func exportCarriesChatsAndImportKeepsTheNewer() throws {
        let source = temporaryDirectory()
        let sourceChats = ChatStore(root: source)
        try sourceChats.write(thread("chat-same", "Import neuer", updated: now))
        try sourceChats.write(thread("chat-keep", "Import älter", updated: now.addingTimeInterval(-3_600)))
        try sourceChats.write(thread("chat-new", "Ganz neu", updated: now))
        let zip = temporaryDirectory().appendingPathComponent("export.paralist")
        let stats = try BackupWriter.write(store: EntryStore(root: source), reviews: ReviewLog(root: source), to: zip, now: now)
        #expect(stats.chats == 3)

        let target = temporaryDirectory()
        let targetChats = ChatStore(root: target)
        try targetChats.write(thread("chat-same", "Lokal alt", updated: now.addingTimeInterval(-7_200)))
        try targetChats.write(thread("chat-keep", "Lokal neu", updated: now))
        try targetChats.write(thread("chat-only", "Nur lokal", updated: now))
        let p = try plan(target, zip)
        #expect(p.hasChanges)
        #expect(p.chatsToWrite.map(\.id).sorted() == ["chat-new", "chat-same"])
        let result = try ImportApplier(store: EntryStore(root: target), reviews: ReviewLog(root: target), safetyDir: temporaryDirectory()).apply(p, now: now)
        #expect(result.chats == 2)
        #expect(targetChats.load("chat-same")?.title == "Import neuer")
        #expect(targetChats.load("chat-keep")?.title == "Lokal neu")
        #expect(targetChats.load("chat-new")?.title == "Ganz neu")
        #expect(targetChats.load("chat-only")?.title == "Nur lokal")
    }

    @Test func brokenChatsAreRejectedWithoutBlockingTheImport() throws {
        let good = try ChatCodec.encode(thread("chat-good", "Gut", updated: now))
        let zip = ZipFixtures.zip([
            ZipFixtures.entry("note-1", "Eins"),
            ("chats/chat-good.json", good),
            ("chats/chat-bad.json", Data("{\"id\":\"../x\"}".utf8)),
            ("chats/chat-misnamed.json", good),
            ("chats/notes.txt", Data("x".utf8)),
        ])
        let target = temporaryDirectory()
        let p = try plan(target, zip)
        #expect(p.newEntries == 1)
        #expect(p.chatsToWrite.map(\.id) == ["chat-good"])
        #expect(p.chatsRejected == 2)
        #expect(p.ignoredFiles == 1)
    }

    @Test func importRemapsChatImagesAndDropsMissingOnes() throws {
        let pdf = Data("%PDF-1.7".utf8)
        let named = String(repeating: "c", count: 64)
        let missing = String(repeating: "d", count: 64)
        var thread = self.thread("chat-img", "Plan", updated: now)
        thread.messages += [
            ChatMessage(id: "msg-2", role: .user, text: "", at: now, attachment: named),
            ChatMessage(id: "msg-3", role: .user, text: "", at: now, attachment: missing),
            ChatMessage(id: "msg-4", role: .user, text: "Bleibt", at: now, attachment: missing),
        ]
        let zip = ZipFixtures.zip([("anhaenge/" + named, pdf), ("chats/chat-img.json", try ChatCodec.encode(thread))])
        let p = try plan(temporaryDirectory(), zip)
        let imported = try #require(p.chatsToWrite.first)
        #expect(imported.messages.map(\.id) == ["msg-1", "msg-2", "msg-4"])
        #expect(imported.messages.map(\.attachment) == [nil, SHA256.hex(pdf), nil])
    }

    @Test func failedImportRestoresReplacedChats() throws {
        let source = temporaryDirectory()
        try ChatStore(root: source).write(thread("chat-a", "Neu", updated: now))
        try ChatStore(root: source).write(thread("chat-b", "Auch neu", updated: now))
        let zip = temporaryDirectory().appendingPathComponent("export.paralist")
        try BackupWriter.write(store: EntryStore(root: source), reviews: ReviewLog(root: source), to: zip, now: now)
        let target = temporaryDirectory()
        let chats = ChatStore(root: target)
        try chats.write(thread("chat-a", "Alt", updated: now.addingTimeInterval(-60)))
        let p = try plan(target, zip)
        #expect(p.chatsToWrite.map(\.id) == ["chat-a", "chat-b"])
        struct Full: Error {}
        var writes = 0
        #expect(throws: Full.self) {
            _ = try ImportApplier(store: EntryStore(root: target), reviews: ReviewLog(root: target), safetyDir: temporaryDirectory()) {
                writes += 1
                if writes == 2 { throw Full() }
            }.apply(p, now: now)
        }
        #expect(chats.load("chat-a")?.title == "Alt")
        #expect(chats.load("chat-b") == nil)
    }
}
