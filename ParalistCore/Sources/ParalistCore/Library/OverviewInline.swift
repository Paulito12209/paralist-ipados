// Zusammenhang: Paralist/Pages/OverviewPage.swift (Breite des Containers), Paralist/Pages/OverviewSections.swift (Icon-Knöpfe), Paralist/Pages/OverviewEdge.swift (Edge Picker), Tests OverviewInlineTests.swift
import Foundation

public enum OverviewInline {
    public static func showsOptions(container: Double, window: Double) -> Bool {
        window > 0 && container * 2 >= window
    }
}
