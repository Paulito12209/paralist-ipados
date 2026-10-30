// Zusammenhang: Paralist/Entry/EdgePicker.swift, Paralist/Entry/EntryPage.swift, Tests EdgePickerTests.swift
import Foundation

public enum EntryCanvas: Int, CaseIterable, Sendable {
    case cover, actions, text, links

    public var label: String {
        switch self {
        case .cover: return "canvas_cover"
        case .actions: return "canvas_actions"
        case .text: return "canvas_text"
        case .links: return "entry_links"
        }
    }
}

public enum EdgePicker {
    public static let shownOnDetail = false

    public static let pill: Double = 46
    public static let pillWide: Double = 96
    public static let pillWidth: Double = 40
    public static let icon: Double = 20
    public static let gap: Double = 12
    public static let dragStart: Double = 8

    public static let visible = 3
    public static let faintest: Double = 0.5

    public static func options(hasText: Bool, hasLinks: Bool = false) -> [EntryCanvas] {
        [.cover, .actions] + (hasText ? [.text] : []) + (hasLinks ? [.links] : [])
    }

    public static func height(count: Int, full: Double) -> Double {
        full - Double(max(0, visible - count)) * (icon + gap) * 1.5
    }

    public static func step(pill: Double = pill) -> Double {
        pill / 2 + gap + icon / 2
    }

    public static func center(of index: Int, selected: Int, pill: Double = pill) -> Double {
        let away = index - selected
        guard away != 0 else { return 0 }
        let sign = Double(away.signum())
        let further = Double(abs(away) - 1) * (icon + gap)
        return sign * (step(pill: pill) + further)
    }

    public static func shift(selected: Int, count: Int, reach: Double, pill: Double = pill) -> Double {
        guard count > 0 else { return 0 }
        func half(_ index: Int) -> Double { (index == selected ? pill : icon) / 2 }
        let top = center(of: 0, selected: selected, pill: pill) - half(0)
        let bottom = center(of: count - 1, selected: selected, pill: pill) + half(count - 1)
        if count < visible { return -(top + bottom) / 2 }
        if count > visible { return 0 }
        if top > -reach && bottom > reach { return -reach - top }
        if bottom < reach && top < -reach { return reach - bottom }
        return 0
    }

    public static func fade(at offset: Double, half: Double) -> Double {
        let start = step()
        guard half > start else { return 1 }
        let t = min(max((abs(offset) - start) / (half - start), 0), 1)
        return 1 - (1 - faintest) * t
    }

    public static func nearest(to offset: Double, selected: Int, count: Int, pill: Double = pill) -> Int {
        guard count > 0 else { return 0 }
        let steps = (offset / step(pill: pill)).rounded()
        let wanted = selected + Int(steps.clamped(to: -Double(count)...Double(count)))
        return min(max(wanted, 0), count - 1)
    }

    public static func spread(_ index: Int, count: Int, reach: Double) -> Double {
        guard count > 1 else { return 0 }
        return -reach + Double(index) * reach * 2 / Double(count - 1)
    }

    public static func spreadSlot(at offset: Double, count: Int, reach: Double) -> Int {
        guard count > 1, reach > 0 else { return 0 }
        let index = ((offset + reach) / (reach * 2 / Double(count - 1))).rounded()
        return min(max(Int(index), 0), count - 1)
    }

    public static func afterDrag(_ translation: Double, selected: Int, count: Int, pill: Double = pill) -> Int {
        nearest(to: -translation, selected: selected, count: count, pill: pill)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
