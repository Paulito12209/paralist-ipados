// Zusammenhang: Sources/ParalistCore/Library/EntryCaption.swift, Sources/ParalistCore/Links/LinkBrand.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct EntryCaptionTests {
    private func bookmark(_ url: String?) -> Entry {
        Entry("b", .bookmark, "Link", epoch, epoch) { $0.url = url }
    }

    private func file(_ name: String, _ mime: String) -> Entry {
        Entry("f", .file, name, epoch, epoch) { $0.attachment = Attachment(hash: String(repeating: "a", count: 64), name: name, mime: mime, size: 1) }
    }

    @Test func singleCategoryListsHideType() {
        #expect(!ListKind.notes.showsType())
        #expect(!ListKind.tasks.showsType())
        #expect(!ListKind.bookmarks.showsType())
        #expect(!ListKind.flashcards.showsType())
        #expect(ListKind.inbox.showsType())
        #expect(ListKind.marked.showsType())
        #expect(ListKind.pinned.showsType())
        #expect(ListKind.all.showsType())
        #expect(ListKind.resources.showsType())
        #expect(!ListKind.resources.showsType(filter: .notes))
        #expect(!ListKind.archive.showsType(filter: .bookmarks))
    }

    @Test func plainEntriesShowTypeOnlyInMixedLists() {
        let note = Entry("n", .note, "Notiz", epoch, epoch)
        #expect(EntryCaption.of(note, showsType: true) == .type(.note))
        #expect(EntryCaption.of(note, showsType: false) == nil)
    }

    @Test func bookmarksShowBrandOrDomain() {
        let insta = EntryCaption.of(bookmark("https://www.instagram.com/p/xyz"), showsType: false)
        #expect(insta == .brand(name: "Instagram", logos: LinkLogoLibrary.assetNames("https://www.instagram.com/p/xyz")))
        #expect(EntryCaption.of(bookmark("https://open.spotify.com/track/1"), showsType: true).map { if case .brand(let n, _) = $0 { n } else { "" } } == "Spotify")
        #expect(EntryCaption.of(bookmark("https://www.example.org/a"), showsType: true) == .domain("example.org"))
        #expect(EntryCaption.of(bookmark(nil), showsType: true) == .type(.bookmark))
        #expect(EntryCaption.of(bookmark(nil), showsType: false) == nil)
    }

    @Test func filesShowTheirKind() {
        #expect(EntryCaption.of(file("a.jpg", "image/jpeg"), showsType: false) == .file(.photo))
        #expect(EntryCaption.of(file("a.mp4", "video/mp4"), showsType: true) == .file(.video))
        #expect(EntryCaption.of(file("a.m4a", "audio/m4a"), showsType: true) == .file(.audio))
        #expect(EntryCaption.of(file("a.pdf", "application/pdf"), showsType: true) == .file(.pdf))
        #expect(EntryCaption.of(file("a.zip", "application/zip"), showsType: true) == .file(.file))
        #expect(EntryCaption.of(file("a.md", "text/markdown"), showsType: false) == .file(.file))
    }

    @Test func brandNamesFollowDomains() {
        #expect(LinkBrand.name("https://youtu.be/abc") == "YouTube")
        #expect(LinkBrand.name("https://de.linkedin.com/in/x") == "LinkedIn")
        #expect(LinkBrand.name("https://notyoutube.com/") == nil)
    }
}
