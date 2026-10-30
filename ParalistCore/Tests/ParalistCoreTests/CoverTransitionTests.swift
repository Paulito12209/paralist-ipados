// Zusammenhang: Library/CoverTransition.swift
import Testing
@testable import ParalistCore

struct CoverTransitionTests {
    private let width = 400.0
    private let height = 840.0
    private let topInset = 60.0
    private var band: Double { CoverTransition.band(width: width, topInset: topInset) }
    private var travel: Double { CoverTransition.travel(height: height, band: band) }

    private func near(_ frame: CoverFrame, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Bool {
        abs(frame.x - x) < 0.001 && abs(frame.y - y) < 0.001 && abs(frame.width - w) < 0.001 && abs(frame.height - h) < 0.001
    }

    private func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.001 }

    @Test func bandIsTopInsetPlusSixteenToNine() {
        #expect(near(band, 285))
        #expect(near(travel, 555))
        #expect(CoverTransition.travel(height: 100, band: 300) == 1)
    }

    @Test func canvasSlidesFromBandToBottom() {
        #expect(CoverTransition.canvasOffset(t: 0, height: height, band: 285) == 0)
        #expect(CoverTransition.canvasOffset(t: 1, height: height, band: 285) == 555)
        #expect(CoverTransition.canvasOffset(t: 0.5, height: height, band: 285) == 277.5)
        #expect(CoverTransition.canvasOffset(t: 2, height: height, band: 285) == 555)
        #expect(CoverTransition.canvasOffset(t: -1, height: height, band: 285) == 0)
    }

    @Test func detailChromeFadesOutEarly() {
        #expect(CoverTransition.detailChrome(t: 0) == 1)
        #expect(near(CoverTransition.detailChrome(t: 0.175), 0.5))
        #expect(CoverTransition.detailChrome(t: 0.35) == 0)
        #expect(CoverTransition.detailChrome(t: 1) == 0)
    }

    @Test func coverChromeFadesInLate() {
        #expect(CoverTransition.coverChrome(t: 0) == 0)
        #expect(CoverTransition.coverChrome(t: 0.65) == 0)
        #expect(near(CoverTransition.coverChrome(t: 0.825), 0.5))
        #expect(CoverTransition.coverChrome(t: 1) == 1)
    }

    @Test func dragFromDetailGrowsProgress() {
        #expect(CoverTransition.progress(drag: 277.5, travel: 555, from: .detail) == 0.5)
        #expect(CoverTransition.progress(drag: -100, travel: 555, from: .detail) == 0)
        #expect(CoverTransition.progress(drag: 1000, travel: 555, from: .detail) == 1)
    }

    @Test func dragFromCoverShrinksProgress() {
        #expect(CoverTransition.progress(drag: -277.5, travel: 555, from: .cover) == 0.5)
        #expect(CoverTransition.progress(drag: 100, travel: 555, from: .cover) == 1)
        #expect(CoverTransition.progress(drag: -1000, travel: 555, from: .cover) == 0)
    }

    @Test func settleUsesShareOfTheWay() {
        #expect(CoverTransition.settle(t: 0.2, velocity: 0, from: .detail) == .detail)
        #expect(CoverTransition.settle(t: 0.4, velocity: 0, from: .detail) == .cover)
        #expect(CoverTransition.settle(t: 0.8, velocity: 0, from: .cover) == .cover)
        #expect(CoverTransition.settle(t: 0.6, velocity: 0, from: .cover) == .detail)
    }

    @Test func settleFollowsStrongFlicks() {
        #expect(CoverTransition.settle(t: 0.1, velocity: 700, from: .detail) == .cover)
        #expect(CoverTransition.settle(t: 0.9, velocity: -700, from: .detail) == .detail)
        #expect(CoverTransition.settle(t: 0.95, velocity: -700, from: .cover) == .detail)
        #expect(CoverTransition.settle(t: 0.2, velocity: 700, from: .cover) == .cover)
        #expect(CoverTransition.settle(t: 0.2, velocity: 500, from: .detail) == .detail)
    }

    @Test func emblemGrowsFromBandToStage() {
        let bandFrame = CoverTransition.bandFrame(motif: .emblem, width: width, topInset: topInset)
        let stage = CoverTransition.stageFrame(motif: .emblem, width: width, height: height)
        #expect(near(bandFrame, 168, 140.5, 64, 64))
        #expect(near(stage, 136, 296, 128, 128))
        let mid = CoverTransition.motifFrame(t: 0.5, motif: .emblem, width: width, height: height, topInset: topInset)
        #expect(near(mid, 152, 218.25, 96, 96))
    }

    @Test func logoKeepsItsSize() {
        #expect(near(CoverTransition.bandFrame(motif: .logo, width: width, topInset: topInset), 152, 124.5, 96, 96))
        #expect(near(CoverTransition.stageFrame(motif: .logo, width: width, height: height), 152, 312, 96, 96))
    }

    @Test func landscapeImageFillsWidthAtAnchor() {
        #expect(near(CoverTransition.bandFrame(motif: .image(ratio: 2), width: width, topInset: topInset), 0, 72.5, 400, 200))
        #expect(near(CoverTransition.stageFrame(motif: .image(ratio: 2), width: width, height: height), 0, 260, 400, 200))
        #expect(near(CoverTransition.imagePlacement(ratio: 1, width: width, height: height), 0, 160, 400, 400))
    }

    @Test func portraitImageSitsCenteredWithEqualMargins() {
        #expect(near(CoverTransition.bandFrame(motif: .image(ratio: 0.5), width: width, topInset: topInset), 143.75, 60, 112.5, 225))
        let tall = CoverTransition.stageFrame(motif: .image(ratio: 0.5), width: width, height: height)
        #expect(near(tall, 0, 20, 400, 800))
        #expect(near(tall.y, height - tall.maxY))
        let narrow = CoverTransition.imagePlacement(ratio: 0.25, width: width, height: height)
        #expect(near(narrow, 95, 0, 210, 840))
    }

    @Test func portraitVideoFillsHeight() {
        #expect(near(CoverTransition.stageFrame(motif: .video(ratio: 0.5), width: width, height: height), -10, 0, 420, 840))
        #expect(near(CoverTransition.stageFrame(motif: .video(ratio: 16.0 / 9), width: width, height: height), 0, 247.5, 400, 225))
        #expect(near(CoverTransition.bandFrame(motif: .video(ratio: 16.0 / 9), width: width, topInset: topInset), 0, 60, 400, 225))
    }

    @Test func embedsKeepTheirBoxes() {
        #expect(near(CoverTransition.bandFrame(motif: .youtube, width: width, topInset: topInset), 0, 60, 400, 225))
        #expect(near(CoverTransition.stageFrame(motif: .youtube, width: width, height: height), 0, 247.5, 400, 225))
        #expect(near(CoverTransition.bandFrame(motif: .spotify, width: width, topInset: topInset), 24, 96.5, 352, 152))
        #expect(near(CoverTransition.stageFrame(motif: .spotify, width: width, height: height), 24, 184, 352, 352))
    }

    @Test func motifFrameEndsMatchBandAndStage() {
        let motif = CoverMotif.image(ratio: 2)
        let start = CoverTransition.motifFrame(t: 0, motif: motif, width: width, height: height, topInset: topInset)
        let end = CoverTransition.motifFrame(t: 1, motif: motif, width: width, height: height, topInset: topInset)
        #expect(start == CoverTransition.bandFrame(motif: motif, width: width, topInset: topInset))
        #expect(end == CoverTransition.stageFrame(motif: motif, width: width, height: height))
        #expect(CoverTransition.motifFrame(t: 3, motif: motif, width: width, height: height, topInset: topInset) == end)
        #expect(near(CoverTransition.motifFrame(t: 0.5, motif: motif, width: width, height: height, topInset: topInset), 0, 166.25, 400, 200))
    }

    @Test func fitKeepsRatioInsideTheBox() {
        let wide = CoverTransition.fit(ratio: 2, width: 400, height: 225)
        #expect(wide.width == 400 && wide.height == 200)
        let tall = CoverTransition.fit(ratio: 0.5, width: 400, height: 225)
        #expect(tall.width == 112.5 && tall.height == 225)
    }
}
