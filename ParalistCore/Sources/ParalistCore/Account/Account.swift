// Zusammenhang: Paralist/Account/AccountSheet.swift, Paralist/Account/AvatarCropSheet.swift, Paralist/Account/AvatarStore.swift
import Foundation

public enum AppLanguage: String, CaseIterable, Sendable, Identifiable {
    case german = "de", english = "en", spanish = "es", french = "fr", chinese = "zh", hindi = "hi", arabic = "ar", bengali = "bn"

    public var id: String { rawValue }
    public var tag: String { rawValue }

    public var nativeName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .chinese: return "中文"
        case .hindi: return "हिन्दी"
        case .arabic: return "العربية"
        case .bengali: return "বাংলা"
        }
    }

    public static func fromTag(_ tag: String?) -> AppLanguage? {
        guard let tag, !tag.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        let language = tag.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map { $0.lowercased() } ?? ""
        return AppLanguage(rawValue: language)
    }
}

public struct SetupProgress: Hashable, Sendable {
    public static let totalSteps = 5
    public let done: Int
    public let total: Int

    public init(done: Int, total: Int) {
        self.done = done
        self.total = total
    }

    public var clampedDone: Int { min(max(done, 0), max(total, 0)) }
    public var fraction: Double { total <= 0 ? 0 : Double(clampedDone) / Double(total) }
    public var isComplete: Bool { total > 0 && clampedDone >= total }

    public static func forProfile(hasName: Bool) -> SetupProgress { SetupProgress(done: hasName ? 1 : 0, total: totalSteps) }
}

public struct AvatarFrame: Sendable {
    public static let minZoom: Double = 1
    public static let maxZoom: Double = 4
    public let imageWidth: Double
    public let imageHeight: Double
    public let viewport: Double
    public let baseScale: Double
    public private(set) var zoom: Double = 1
    public private(set) var offsetX: Double = 0
    public private(set) var offsetY: Double = 0

    public init(imageWidth: Double, imageHeight: Double, viewport: Double) {
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.viewport = viewport
        baseScale = max(viewport / imageWidth, viewport / imageHeight)
    }

    public var scale: Double { baseScale * zoom }
    public var displayWidth: Double { imageWidth * scale }
    public var displayHeight: Double { imageHeight * scale }

    public mutating func transform(zoomFactor: Double, panX: Double, panY: Double) {
        zoom = min(max(zoom * zoomFactor, Self.minZoom), Self.maxZoom)
        offsetX = clamp(offsetX + panX, (displayWidth - viewport) / 2)
        offsetY = clamp(offsetY + panY, (displayHeight - viewport) / 2)
    }

    public var focusX: Double { displayWidth <= 0 ? 0.5 : 0.5 - offsetX / displayWidth }
    public var focusY: Double { displayHeight <= 0 ? 0.5 : 0.5 - offsetY / displayHeight }

    public mutating func setZoom(_ value: Double) {
        zoom = min(max(value, Self.minZoom), Self.maxZoom)
        offsetX = clamp(offsetX, (displayWidth - viewport) / 2)
        offsetY = clamp(offsetY, (displayHeight - viewport) / 2)
    }

    public mutating func setFocus(x: Double, y: Double) {
        offsetX = clamp((0.5 - min(max(x, 0), 1)) * displayWidth, (displayWidth - viewport) / 2)
        offsetY = clamp((0.5 - min(max(y, 0), 1)) * displayHeight, (displayHeight - viewport) / 2)
    }

    public func sourceSide() -> Double { viewport / scale }
    public func sourceLeft() -> Double { imageWidth / 2 - offsetX / scale - sourceSide() / 2 }
    public func sourceTop() -> Double { imageHeight / 2 - offsetY / scale - sourceSide() / 2 }

    private func clamp(_ value: Double, _ limit: Double) -> Double { limit <= 0 ? 0 : min(max(value, -limit), limit) }
}
