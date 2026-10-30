// Zusammenhang: Sources/ParalistCore/Chat/ChatView.swift, Sources/ParalistCore/Chat/ChatCodec.swift (angepinnt), Sources/ParalistCore/Library/ListKind.swift (Ordering.pinnedLead), Sources/ParalistCore/Text/SearchQuery.swift (filter), TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct ChatViewTests {
    private let now = at("2026-10-21T10:00:00Z")

    private func thread(_ id: String, _ title: String, created: Int, updated: Int, pinned: Bool = false, links: [String] = []) -> ChatThread {
        ChatThread(id: id, title: title, created: now.addingTimeInterval(Double(created) * 60),
                   updated: now.addingTimeInterval(Double(updated) * 60), links: links, pinned: pinned)
    }

    private var sample: [ChatThread] {
        [thread("chat-a", "Umzug", created: 0, updated: 30),
         thread("chat-b", "Bücher", created: 10, updated: 20, pinned: true),
         thread("chat-c", "Spanisch", created: 20, updated: 10, links: ["entry-1"])]
    }

    @Test func pinnedChatsLeadThenSortOrder() {
        #expect(ChatViewSetting().arrange(sample).map(\.id) == ["chat-b", "chat-a", "chat-c"])
        #expect(ChatViewSetting(sort: .created).arrange(sample).map(\.id) == ["chat-b", "chat-c", "chat-a"])
        #expect(ChatViewSetting(sort: .created, ascending: true).arrange(sample).map(\.id) == ["chat-b", "chat-a", "chat-c"])
        #expect(ChatViewSetting(sort: .title).arrange(sample).map(\.id) == ["chat-b", "chat-c", "chat-a"])
        #expect(ChatViewSetting(sort: .title, ascending: false).arrange(sample).map(\.id) == ["chat-b", "chat-a", "chat-c"])
    }

    @Test func filterAndQueryNarrowTheList() {
        let view = ChatViewSetting()
        #expect(view.arrange(sample, filter: .pinned).map(\.id) == ["chat-b"])
        #expect(view.arrange(sample, filter: .linked).map(\.id) == ["chat-c"])
        #expect(view.arrange(sample, query: "spa").map(\.id) == ["chat-c"])
        #expect(view.arrange(sample, filter: .pinned, query: "spa").isEmpty)
    }

    @Test func onlyFiltersWithChatsAreOffered() {
        #expect(ChatFilter.visible(in: sample) == [.all, .pinned, .linked])
        #expect(ChatFilter.visible(in: [thread("chat-a", "A", created: 0, updated: 0)]) == [.all])
        #expect(ChatFilter.visible(in: []) == [.all])
    }

    @Test func newestPinnedChatIsShownOnTheFolder() {
        let threads = sample + [thread("chat-d", "Neu", created: 40, updated: 40, pinned: true)]
        #expect(ChatViewSetting.pinned(threads)?.id == "chat-d")
        #expect(ChatViewSetting.pinned([thread("chat-a", "A", created: 0, updated: 0)]) == nil)
    }

    @Test func settingSurvivesEncoding() {
        let view = ChatViewSetting(sort: .title, ascending: false)
        #expect(ChatViewSetting.decode(view.encoded) == view)
        #expect(ChatViewSetting.decode(nil) == ChatViewSetting())
        #expect(ChatViewSetting.decode("quatsch,auf") == ChatViewSetting())
        #expect(ChatViewSetting.decode("erstellt") == ChatViewSetting(sort: .created))
    }

    @Test func pinIsStoredOnlyWhenSet() throws {
        let pinned = thread("chat-a", "Umzug", created: 0, updated: 0, pinned: true)
        let data = try ChatCodec.encode(pinned)
        #expect(String(decoding: data, as: UTF8.self).contains("\"angepinnt\" : true"))
        #expect(try ChatCodec.decode(data).pinned)
        let plain = try ChatCodec.encode(thread("chat-b", "B", created: 0, updated: 0))
        #expect(!String(decoding: plain, as: UTF8.self).contains("angepinnt"))
        #expect(try !ChatCodec.decode(plain).pinned)
    }

    @Test func newestPinnedEntryLeadsACollection() {
        let a = Entry("entry-a", .project, "A", now, now.addingTimeInterval(60)) { $0.pinned = true }
        let b = Entry("entry-b", .project, "B", now, now.addingTimeInterval(120)) { $0.pinned = true }
        let c = Entry("entry-c", .project, "C", now, now.addingTimeInterval(180))
        #expect(Ordering.pinnedLead([a, b, c])?.id == "entry-b")
        #expect(Ordering.pinnedLead([c]) == nil)
    }

    @Test func pageSearchKeepsEverythingWithoutTerms() {
        let a = Entry("entry-a", .note, "Einkaufsliste", now, now)
        let b = Entry("entry-b", .note, "Urlaub planen", now, now)
        #expect(SearchQuery.filter([a, b], query: "").map(\.id) == ["entry-a", "entry-b"])
        #expect(SearchQuery.filter([a, b], query: "  ").map(\.id) == ["entry-a", "entry-b"])
        #expect(SearchQuery.filter([a, b], query: "urla").map(\.id) == ["entry-b"])
        #expect(SearchQuery.filter([a, b], query: "xyz").isEmpty)
    }
}
