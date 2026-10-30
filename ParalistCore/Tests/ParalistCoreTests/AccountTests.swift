// Zusammenhang: Account/Account.swift
import Foundation
import Testing
@testable import ParalistCore

struct SetupProgressTests {
    @Test func clampsOutOfRangeValues() {
        #expect(SetupProgress(done: -3, total: 5).clampedDone == 0)
        #expect(SetupProgress(done: 9, total: 5).clampedDone == 5)
        #expect(SetupProgress(done: 2, total: 0).fraction == 0)
    }

    @Test func fractionAndCompletion() {
        let half = SetupProgress(done: 2, total: 4)
        #expect(half.fraction == 0.5)
        #expect(!half.isComplete)
        #expect(SetupProgress(done: 4, total: 4).isComplete)
    }

    @Test func profileWithNameCountsOneStep() {
        #expect(SetupProgress.forProfile(hasName: true).done == 1)
        #expect(SetupProgress.forProfile(hasName: false).done == 0)
        #expect(SetupProgress.forProfile(hasName: true).total == SetupProgress.totalSteps)
    }
}

struct AvatarFrameTests {
    @Test func coversTheViewportWithTheShorterSide() {
        let frame = AvatarFrame(imageWidth: 400, imageHeight: 200, viewport: 100)
        #expect(frame.baseScale == 0.5)
        #expect(frame.displayWidth == 200)
        #expect(frame.displayHeight == 100)
    }

    @Test func centeredCropAtZoomOne() {
        let frame = AvatarFrame(imageWidth: 400, imageHeight: 200, viewport: 100)
        #expect(frame.sourceLeft() == 100)
        #expect(frame.sourceTop() == 0)
        #expect(frame.sourceSide() == 200)
    }

    @Test func panIsClampedToTheImageEdge() {
        var frame = AvatarFrame(imageWidth: 400, imageHeight: 200, viewport: 100)
        frame.transform(zoomFactor: 1, panX: -500, panY: -500)
        #expect(frame.offsetX == -50)
        #expect(frame.offsetY == 0)
        #expect(frame.sourceLeft() == 200)
    }

    @Test func zoomShrinksTheSourceAndKeepsBounds() {
        var frame = AvatarFrame(imageWidth: 400, imageHeight: 200, viewport: 100)
        frame.transform(zoomFactor: 2, panX: 0, panY: 0)
        #expect(frame.zoom == 2)
        #expect(frame.sourceSide() == 100)
        frame.transform(zoomFactor: 1, panX: 0, panY: 1000)
        #expect(frame.offsetY == 50)
        #expect(frame.sourceTop() == 0)
        frame.transform(zoomFactor: 10, panX: 0, panY: 0)
        #expect(frame.zoom == AvatarFrame.maxZoom)
        frame.transform(zoomFactor: 0.01, panX: 0, panY: 0)
        #expect(frame.zoom == AvatarFrame.minZoom)
        #expect(frame.offsetY == 0)
    }

    @Test func focusMovesTheSourceCenter() {
        var frame = AvatarFrame(imageWidth: 400, imageHeight: 200, viewport: 100)
        frame.setZoom(2)
        frame.setFocus(x: 0.25, y: 0.5)
        #expect(frame.focusX == 0.25)
        #expect(frame.sourceLeft() == 50)
        frame.setFocus(x: 1, y: 0.5)
        #expect(frame.focusX == 0.875)
        #expect(frame.sourceLeft() == 300)
    }

    @Test func focusAndZoomStayInsideTheImage() {
        var frame = AvatarFrame(imageWidth: 400, imageHeight: 200, viewport: 100)
        frame.setZoom(4)
        frame.setFocus(x: -5, y: 9)
        #expect(frame.focusX == 0.0625)
        #expect(frame.focusY == 0.875)
        #expect(frame.sourceLeft() == 0)
        #expect(frame.sourceTop() + frame.sourceSide() == 200)
        frame.setZoom(0.1)
        #expect(frame.zoom == AvatarFrame.minZoom)
        #expect(frame.offsetX == 50)
    }
}

struct AppLanguageTests {
    @Test func hasEightUniqueLanguages() {
        #expect(AppLanguage.allCases.count == 8)
        #expect(Set(AppLanguage.allCases.map(\.tag)).count == 8)
    }

    @Test func matchesRegionalTags() {
        #expect(AppLanguage.fromTag("de-AT") == .german)
        #expect(AppLanguage.fromTag("zh-Hans-CN") == .chinese)
        #expect(AppLanguage.fromTag("es_MX") == .spanish)
    }

    @Test func unknownTagsReturnNull() {
        #expect(AppLanguage.fromTag(nil) == nil)
        #expect(AppLanguage.fromTag("") == nil)
        #expect(AppLanguage.fromTag("tlh") == nil)
    }
}
