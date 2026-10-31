// Zusammenhang: ParalistCore Library/OverviewInline.swift
import Testing
@testable import ParalistCore

struct OverviewInlineTests {
    @Test func halfOrMoreShowsIcons() {
        #expect(OverviewInline.showsOptions(container: 600, window: 1200))
        #expect(OverviewInline.showsOptions(container: 800, window: 1200))
        #expect(OverviewInline.showsOptions(container: 1200, window: 1200))
    }

    @Test func lessThanHalfKeepsEdge() {
        #expect(!OverviewInline.showsOptions(container: 599, window: 1200))
        #expect(!OverviewInline.showsOptions(container: 400, window: 1200))
    }

    @Test func unknownWindowKeepsEdge() {
        #expect(!OverviewInline.showsOptions(container: 500, window: 0))
    }
}
