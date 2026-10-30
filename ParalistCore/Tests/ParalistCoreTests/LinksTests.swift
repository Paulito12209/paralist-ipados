// Zusammenhang: Links/UrlGuard.swift, Links/TitleExtractor.swift, Links/VideoLinks.swift, Links/SharedText.swift, Links/FileKind.swift, Links/IncomingLink.swift
import Foundation
import Testing
@testable import ParalistCore

struct UrlGuardTests {
    @Test func blocksPrivateAndLocalTargets() {
        for url in [
            "http://192.168.0.1", "http://10.0.0.5/x", "http://172.16.3.4", "http://127.0.0.1:8080", "http://localhost",
            "http://[::1]/", "http://169.254.169.254/latest", "http://0.0.0.0", "http://100.64.1.1", "http://router.local",
            "javascript:alert(1)", "file:///etc/passwd", "ftp://example.org", "http://user:pw@example.org", "nicht-url",
        ] {
            #expect(!UrlGuard.isAllowedUrl(url), "\(url)")
        }
    }

    @Test func allowsPublicHosts() {
        #expect(UrlGuard.isAllowedUrl("https://example.org/pfad?x=1"))
        #expect(UrlGuard.isAllowedUrl("http://93.184.216.34/"))
    }

    @Test func resolvedAddressesAreCheckedToo() throws {
        #expect(!UrlGuard.isPublicAddress(try #require(UrlGuard.literalBytes("10.1.2.3"))))
        #expect(!UrlGuard.isPublicAddress(try #require(UrlGuard.literalBytes("::ffff:192.168.1.1"))))
        #expect(!UrlGuard.isPublicAddress(try #require(UrlGuard.literalBytes("fd00::1"))))
        #expect(UrlGuard.isPublicAddress(try #require(UrlGuard.literalBytes("93.184.216.34"))))
    }

    @Test func extractsAndCleansTitles() {
        #expect(TitleExtractor.extract("<html><head><title> Hallo &amp; <b>Welt</b> </title></head></html>") == "Hallo & Welt")
        #expect(TitleExtractor.extract("<title>x</title><meta property=\"og:title\" content=\"OG zuerst\">") == "OG zuerst")
        #expect(TitleExtractor.extract("<meta content='Umgekehrt' property='og:title'>") == "Umgekehrt")
        #expect(TitleExtractor.extract("<html><body>kein titel</body></html>") == nil)
        #expect(TitleExtractor.extract("<title><script>alert(1)</script></title>") == "alert(1)")
        #expect(TitleExtractor.extract("<title>\(String(repeating: "a", count: 1000))</title>")?.count == 300)
    }

    @Test func youtubeUsesOEmbedAndParsesJsonTitle() {
        #expect(TitleExtractor.oEmbedUrl("https://youtu.be/abc") == "https://www.youtube.com/oembed?format=json&url=https%3A%2F%2Fyoutu.be%2Fabc")
        #expect(TitleExtractor.oEmbedUrl("https://example.org/watch") == nil)
        #expect(TitleExtractor.oEmbedUrl("https://youtube.com.evil.org/x") == nil)
        let json = "{\"title\":\"Rick Astley - Never Gonna Give You Up (Official Video) \\u0026 mehr \\\"live\\\"\",\"author_name\":\"x\"}"
        #expect(TitleExtractor.fromOEmbed(json) == "Rick Astley - Never Gonna Give You Up (Official Video) & mehr \"live\"")
        #expect(TitleExtractor.fromOEmbed("{\"author\":\"x\"}") == nil)
        #expect(TitleExtractor.fromOEmbed("{\"title\":\"<script>alert(1)</script>\"}") == "alert(1)")
    }
}

struct VideoLinksTests {
    @Test func readsWatchLinks() {
        #expect(VideoLinks.youtubeId("https://www.youtube.com/watch?v=dQw4w9WgXcQ") == "dQw4w9WgXcQ")
        #expect(VideoLinks.youtubeId("https://m.youtube.com/watch?t=42&v=dQw4w9WgXcQ&list=PL1") == "dQw4w9WgXcQ")
    }

    @Test func readsShortAndEmbedLinks() {
        #expect(VideoLinks.youtubeId("https://youtu.be/dQw4w9WgXcQ?si=abc") == "dQw4w9WgXcQ")
        #expect(VideoLinks.youtubeId("https://www.youtube.com/shorts/dQw4w9WgXcQ") == "dQw4w9WgXcQ")
        #expect(VideoLinks.youtubeId("https://www.youtube.com/embed/dQw4w9WgXcQ/") == "dQw4w9WgXcQ")
    }

    @Test func rejectsOtherLinks() {
        #expect(VideoLinks.youtubeId("https://example.org/watch?v=dQw4w9WgXcQ") == nil)
        #expect(VideoLinks.youtubeId("https://www.youtube.com/feed/subscriptions") == nil)
        #expect(VideoLinks.youtubeId("https://www.youtube.com/watch?v=zu-kurz") == nil)
        #expect(VideoLinks.youtubeId("kein link") == nil)
        #expect(VideoLinks.youtubeId("") == nil)
    }

    @Test func embedStaysOnYoutube() {
        #expect(VideoLinks.embedUrl("dQw4w9WgXcQ") == "https://www.youtube.com/embed/dQw4w9WgXcQ?rel=0&playsinline=1&fs=0&enablejsapi=1&origin=https://paralist.app")
        #expect(VideoLinks.isPlayerHost("www.youtube-nocookie.com"))
        #expect(VideoLinks.isPlayerHost("accounts.google.com"))
        #expect(!VideoLinks.isPlayerHost("example.org"))
        #expect(!VideoLinks.isPlayerHost(nil))
    }
}

struct SharedTextTests {
    @Test func youtubeShareGivesLinkAndSubjectTitle() {
        let shared = SharedText.parse("https://youtu.be/dQw4w9WgXcQ?si=x", subject: "Rick Astley - Never Gonna Give You Up")
        #expect(shared.url == "https://youtu.be/dQw4w9WgXcQ?si=x")
        #expect(shared.title == "Rick Astley - Never Gonna Give You Up")
    }

    @Test func textWithLinkUsesRemainingTextAsTitle() {
        let shared = SharedText.parse("Schau dir das an: https://example.org/seite.")
        #expect(shared.url == "https://example.org/seite")
        #expect(shared.title == "Schau dir das an:")
    }

    @Test func plainTextHasNoLink() {
        let shared = SharedText.parse("Nur ein Gedanke\nzweite Zeile", subject: "https://nicht-als-titel.de")
        #expect(shared.url == nil)
        #expect(shared.title == "Nur ein Gedanke")
        #expect(SharedText.parse(nil) == SharedText(url: nil, title: ""))
    }
}

struct FileKindTests {
    private func latin1(_ text: String) -> [UInt8] { text.unicodeScalars.map { UInt8($0.value) } }

    @Test func detectsByBytesNotByName() {
        #expect(FileKind.detect([0x50, 0x4B, 0x03, 0x04, 0x14, 0, 0, 0]) == nil)
        #expect(FileKind.detect(latin1("dex\n035\u{0}")) == nil)
        #expect(FileKind.detectSafe(Array("<!DOCTYPE html><html>".utf8)) == nil)
        #expect(FileKind.detectSafe(Array("  #!/bin/sh\nrm -rf /".utf8)) == nil)
        #expect(FileKind.detectSafe(Array("<svg onload=alert(1)>".utf8)) == nil)
        #expect(FileKind.detectSafe(Array("Einkaufsliste\n- Milch".utf8)) == .text)
        #expect(FileKind.detect([0xFF, 0xD8, 0xFF, 0xE0]) == .jpeg)
        #expect(FileKind.detect(latin1("\u{89}PNG\r\n\u{1A}\n")) == .png)
        #expect(FileKind.detect(Array("%PDF-1.7".utf8)) == .pdf)
        #expect(FileKind.detect(latin1("\u{0}\u{0}\u{0}\u{18}ftypmp42")) == .mp4)
        #expect(FileKind.detect([0x7F, 0x45, 0x4C, 0x46, 0, 1]) == nil)
    }

    @Test func sanitizesNames() {
        #expect(FileKind.sanitizeName("../../evil.apk", kind: .jpeg) == "evil.jpg")
        #expect(FileKind.sanitizeName("", kind: .pdf) == "datei.pdf")
        #expect(FileKind.sanitizeName("C:\\Users\\x\\Bericht 2026.PNG\u{7}", kind: .png) == "Bericht 2026.png")
    }
}

struct IncomingLinkTests {
    private func parse(_ s: String) -> IncomingLink? { IncomingLink.parse(URL(string: s)!) }

    @Test func schemeLinks() {
        #expect(parse("paralist-ipad://briefing") == .briefing)
        #expect(parse("paralist-ipad://eintrag/mein-eintrag") == .entry("mein-eintrag"))
        #expect(parse("paralist-ipad://teilen?text=https://example.org&titel=Hallo") == .share(text: "https://example.org", title: "Hallo"))
        #expect(parse("PARALIST-IPAD://briefing") == .briefing)
    }

    @Test func legacySchemeStillParses() {
        #expect(parse("paralist://briefing") == .briefing)
        #expect(parse("paralist://eintrag/mein-eintrag") == .entry("mein-eintrag"))
    }

    @Test func builtLinksUseIpadScheme() {
        #expect(IncomingLink.scheme == "paralist-ipad")
        #expect(IncomingLink.entryURL("mein-eintrag")?.scheme == "paralist-ipad")
    }

    @Test func webLinksUnderPrefix() {
        #expect(parse("https://xool-app.de/p/briefing") == .briefing)
        #expect(parse("https://XOOL-APP.de/p/Briefing") == .briefing)
        #expect(parse("https://xool-app.de/p/eintrag/mein-eintrag") == .entry("mein-eintrag"))
        #expect(parse("https://xool-app.de/p/teilen?text=Notiz") == .share(text: "Notiz", title: nil))
    }

    @Test func rejectsForeignAndMalformedLinks() {
        for s in [
            "https://xool-app.de/", "https://xool-app.de/briefing", "https://xool-app.de/p/", "https://xool-app.de/p/unbekannt",
            "http://xool-app.de/p/briefing", "https://evil.example/p/briefing", "https://xool-app.de/p/eintrag/",
            "https://xool-app.de/p/eintrag/Ungültig!", "paralist-ipad://unbekannt", "paralist-ipad://eintrag/", "paralist://unbekannt", "paralist-iphone://briefing",
        ] {
            #expect(parse(s) == nil, "\(s)")
        }
    }
}
