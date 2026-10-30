// Zusammenhang: Links/LinkIcon.swift
import Testing
@testable import ParalistCore

struct LinkIconTests {
    let page = "https://example.org/artikel/eins?x=1"

    @Test func prefersTouchIconOverFavicon() {
        let html = ##"<link rel="icon" sizes="32x32" href="/f32.png"><link rel="apple-touch-icon" href="/touch.png"><link rel="icon" href="/favicon.ico">"##
        #expect(LinkIcon.iconUrl(html: html, page: page) == "https://example.org/touch.png")
    }

    @Test func picksLargestPlainIcon() {
        let html = ##"<link rel="icon" sizes="16x16" href="/f16.png"><link rel="shortcut icon" href="/favicon.ico"><link rel="icon" sizes="192x192" href="https://cdn.example.org/big.png">"##
        #expect(LinkIcon.iconUrl(html: html, page: page) == "https://cdn.example.org/big.png")
    }

    @Test func resolvesRelativeAndEntities() {
        #expect(LinkIcon.iconUrl(html: ##"<link href="logo.png?a=1&amp;b=2" rel="icon">"##, page: page) == "https://example.org/artikel/logo.png?a=1&b=2")
        #expect(LinkIcon.iconUrl(html: ##"<link rel="icon" href="//static.example.org/i.png">"##, page: page) == "https://static.example.org/i.png")
    }

    @Test func skipsSvgStylesheetsAndOddSchemes() {
        #expect(LinkIcon.iconUrl(html: ##"<link rel="icon" href="/logo.svg">"##, page: page) == nil)
        #expect(LinkIcon.iconUrl(html: ##"<link rel="icon" type="image/svg+xml" href="/logo">"##, page: page) == nil)
        #expect(LinkIcon.iconUrl(html: ##"<link rel="stylesheet" href="/a.css"><link rel="icon" href="javascript:alert(1)">"##, page: page) == nil)
        #expect(LinkIcon.iconUrl(html: "<html></html>", page: page) == nil)
    }

    @Test func fallsBackToFavicon() {
        #expect(LinkIcon.fallbackUrl(page: page) == "https://example.org/favicon.ico")
        #expect(LinkIcon.fallbackUrl(page: "kein link") == nil)
    }
}
