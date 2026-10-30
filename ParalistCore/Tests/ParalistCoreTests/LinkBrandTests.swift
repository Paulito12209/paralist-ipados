// Zusammenhang: Links/LinkBrand.swift
import Testing
@testable import ParalistCore

struct LinkBrandTests {
    @Test func knowsBrandsBySubdomain() {
        #expect(LinkBrand.color("https://www.youtube.com/watch?v=abc") == 0xFF0000)
        #expect(LinkBrand.color("https://de.linkedin.com/in/someone") == 0x0A66C2)
        #expect(LinkBrand.color("https://docs.google.com/document/d/1") == 0x4285F4)
        #expect(LinkBrand.color("instagram.com/p/xyz") == 0x833AB4)
        #expect(LinkBrand.color("https://m.facebook.com/") == 0x1877F2)
    }

    @Test func ignoresLookalikeHosts() {
        #expect(LinkBrand.color("https://notyoutube.com/") == nil)
        #expect(LinkBrand.color("https://example.org/") == nil)
        #expect(LinkBrand.color("kein link") == nil)
    }

    @Test func readsThemeColor() {
        #expect(LinkBrand.themeColor(##"<head><meta name="theme-color" content="#1a73e8"></head>"##) == 0x1A73E8)
        #expect(LinkBrand.themeColor(##"<meta content="#c00" name="theme-color">"##) == 0xCC0000)
        #expect(LinkBrand.themeColor(##"<meta name="theme-color" media="(prefers-color-scheme: dark)" content="#202124"><meta name="theme-color" content="#d93025">"##) == 0xD93025)
    }

    @Test func rejectsWhiteBlackAndInvalid() {
        #expect(LinkBrand.themeColor(##"<meta name="theme-color" content="#ffffff">"##) == nil)
        #expect(LinkBrand.themeColor(##"<meta name="theme-color" content="#000">"##) == nil)
        #expect(LinkBrand.themeColor(##"<meta name="theme-color" content="red">"##) == nil)
        #expect(LinkBrand.themeColor("<html></html>") == nil)
    }
}
