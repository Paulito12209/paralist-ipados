// Zusammenhang: Paralist/Entry/EntryPage.swift, Paralist/Entry/CoverStage.swift, Paralist/Entry/EntryHero.swift, Library/EdgePicker.swift, Tests CoverTransitionTests.swift, docs/etappen-cover-uebergang.md
import Foundation

public struct CoverFrame: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var midX: Double { x + width / 2 }
    public var midY: Double { y + height / 2 }
    public var maxY: Double { y + height }

    public static func centered(width: Double, height: Double, at center: (x: Double, y: Double)) -> CoverFrame {
        CoverFrame(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }

    public func mixed(with other: CoverFrame, by t: Double) -> CoverFrame {
        CoverFrame(x: x.mixed(with: other.x, by: t), y: y.mixed(with: other.y, by: t),
                   width: width.mixed(with: other.width, by: t), height: height.mixed(with: other.height, by: t))
    }
}

public enum CoverMotif: Equatable, Sendable {
    case emblem
    case logo
    case image(ratio: Double)
    case video(ratio: Double)
    case youtube
    case spotify
}

public enum CoverEnd: Equatable, Sendable {
    case detail, cover
}

public struct CoverMetrics: Sendable {
    public var mediaRatio: Double = 16.0 / 9
    public var anchor: Double = 3.0 / 7
    public var emblemBand: Double = 64
    public var emblemStage: Double = 128
    public var logo: Double = 96
    public var spotifyBand: Double = 152
    public var spotifyStage: Double = 352
    public var bandInset: Double = 24
    public var rowInset: Double = 24

    public init() {}
    public static let standard = CoverMetrics()
}

public enum CoverTransition {
    public static let snapShare: Double = 0.35
    public static let snapVelocity: Double = 600
    public static let detailChromeEnd: Double = 0.35
    public static let coverChromeStart: Double = 0.65

    public static func band(width: Double, topInset: Double, metrics: CoverMetrics = .standard) -> Double {
        topInset + width / metrics.mediaRatio
    }

    public static func travel(height: Double, band: Double) -> Double {
        max(height - band, 1)
    }

    public static func canvasOffset(t: Double, height: Double, band: Double) -> Double {
        t.clamped() * (height - band)
    }

    public static func detailChrome(t: Double) -> Double {
        1 - (t / detailChromeEnd).clamped()
    }

    public static func coverChrome(t: Double) -> Double {
        ((t - coverChromeStart) / (1 - coverChromeStart)).clamped()
    }

    public static func progress(drag: Double, travel: Double, from end: CoverEnd) -> Double {
        let share = drag / max(travel, 1)
        switch end {
        case .detail: return share.clamped()
        case .cover: return (1 + share).clamped()
        }
    }

    public static func settle(t: Double, velocity: Double, from end: CoverEnd) -> CoverEnd {
        if velocity > snapVelocity { return .cover }
        if velocity < -snapVelocity { return .detail }
        switch end {
        case .detail: return t > snapShare ? .cover : .detail
        case .cover: return t < 1 - snapShare ? .detail : .cover
        }
    }

    public static func bandFrame(motif: CoverMotif, width: Double, topInset: Double, metrics: CoverMetrics = .standard) -> CoverFrame {
        let height = width / metrics.mediaRatio
        let center = (x: width / 2, y: topInset + height / 2)
        switch motif {
        case .emblem:
            return .centered(width: metrics.emblemBand, height: metrics.emblemBand, at: center)
        case .logo:
            return .centered(width: metrics.logo, height: metrics.logo, at: center)
        case .image(let ratio), .video(let ratio):
            let fitted = fit(ratio: ratio, width: width, height: height)
            return .centered(width: fitted.width, height: fitted.height, at: center)
        case .youtube:
            return CoverFrame(x: 0, y: topInset, width: width, height: height)
        case .spotify:
            return .centered(width: width - metrics.bandInset * 2, height: metrics.spotifyBand, at: center)
        }
    }

    public static func stageFrame(motif: CoverMotif, width: Double, height: Double, metrics: CoverMetrics = .standard) -> CoverFrame {
        let anchor = (x: width / 2, y: height * metrics.anchor)
        switch motif {
        case .emblem:
            return .centered(width: metrics.emblemStage, height: metrics.emblemStage, at: anchor)
        case .logo:
            return .centered(width: metrics.logo, height: metrics.logo, at: anchor)
        case .image(let ratio):
            return imagePlacement(ratio: ratio, width: width, height: height, metrics: metrics)
        case .video(let ratio):
            if ratio < 1 {
                return .centered(width: max(width, height * ratio), height: height, at: (width / 2, height / 2))
            }
            return .centered(width: width, height: width / ratio, at: anchor)
        case .youtube:
            return .centered(width: width, height: width / metrics.mediaRatio, at: anchor)
        case .spotify:
            return .centered(width: width - metrics.rowInset * 2, height: metrics.spotifyStage, at: anchor)
        }
    }

    public static func imagePlacement(ratio: Double, width: Double, height: Double, metrics: CoverMetrics = .standard) -> CoverFrame {
        if ratio >= 1 {
            return .centered(width: width, height: width / ratio, at: (width / 2, height * metrics.anchor))
        }
        let fitted = fit(ratio: ratio, width: width, height: height)
        return .centered(width: fitted.width, height: fitted.height, at: (width / 2, height / 2))
    }

    public static func motifFrame(t: Double, motif: CoverMotif, width: Double, height: Double, topInset: Double, metrics: CoverMetrics = .standard) -> CoverFrame {
        let band = bandFrame(motif: motif, width: width, topInset: topInset, metrics: metrics)
        let stage = stageFrame(motif: motif, width: width, height: height, metrics: metrics)
        return band.mixed(with: stage, by: t.clamped())
    }

    static func fit(ratio: Double, width: Double, height: Double) -> (width: Double, height: Double) {
        let safeRatio = max(ratio, 0.0001)
        if width / safeRatio <= height { return (width, width / safeRatio) }
        return (height * safeRatio, height)
    }
}

extension Double {
    func clamped(_ low: Double = 0, _ high: Double = 1) -> Double {
        Swift.min(Swift.max(self, low), high)
    }

    func mixed(with other: Double, by t: Double) -> Double {
        self + (other - self) * t
    }
}
