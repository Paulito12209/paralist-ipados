// Zusammenhang: Links/StoreVersion.swift
import Foundation
import Testing
@testable import ParalistCore

struct StoreVersionTests {
    @Test func readsVersionFromLookup() {
        let json = #"{"resultCount":1,"results":[{"trackId":6824983999,"version":"1.2.0","bundleId":"app.paralist"}]}"#
        #expect(StoreVersion.fromLookup(json) == "1.2.0")
    }

    @Test func emptyLookupMeansNoVersion() {
        #expect(StoreVersion.fromLookup(#"{"resultCount":0,"results":[]}"#) == nil)
        #expect(StoreVersion.fromLookup("kein json") == nil)
        #expect(StoreVersion.fromLookup(#"{"results":[{"version":"  "}]}"#) == nil)
    }

    @Test func comparesNumerically() {
        #expect(StoreVersion.isNewer("1.1", than: "1.0"))
        #expect(StoreVersion.isNewer("1.10", than: "1.9"))
        #expect(StoreVersion.isNewer("2.0.0", than: "1.99.99"))
        #expect(StoreVersion.isNewer("1.0.1", than: "1.0"))
        #expect(!StoreVersion.isNewer("1.0", than: "1.0.0"))
        #expect(!StoreVersion.isNewer("1.0", than: "1.0"))
        #expect(!StoreVersion.isNewer("0.9", than: "1.0"))
    }

    @Test func garbageIsNeverNewer() {
        #expect(!StoreVersion.isNewer("beta", than: "1.0"))
        #expect(!StoreVersion.isNewer("1.1", than: "x"))
        #expect(!StoreVersion.isNewer("", than: "1.0"))
    }
}
