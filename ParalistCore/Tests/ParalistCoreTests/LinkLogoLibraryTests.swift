// Zusammenhang: Links/LinkLogoLibrary.swift
import Testing
@testable import ParalistCore

struct LinkLogoLibraryTests {
    @Test func walksSubdomainsDownToTheRegisteredDomain() {
        #expect(LinkLogoLibrary.candidates("https://open.spotify.com/track/1") == ["open.spotify.com", "spotify.com"])
        #expect(LinkLogoLibrary.candidates("https://www.linkedin.com/in/x") == ["linkedin.com"])
    }

    @Test func addsAliasesAfterTheHostItself() {
        #expect(LinkLogoLibrary.candidates("https://youtu.be/abc") == ["youtu.be", "youtube.com"])
        #expect(LinkLogoLibrary.candidates("https://lnkd.in/xyz") == ["lnkd.in", "linkedin.com"])
        #expect(LinkLogoLibrary.candidates("https://paul.notion.site/seite") == ["paul.notion.site", "notion.site", "notion.so"])
    }

    @Test func prefixesTheCatalogFolder() {
        #expect(LinkLogoLibrary.assetNames("https://github.com/a/b") == ["LinkLogos/github.com"])
        #expect(LinkLogoLibrary.assetNames("kein link").isEmpty)
    }
}
