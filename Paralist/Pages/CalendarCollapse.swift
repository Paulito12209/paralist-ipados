// Zusammenhang: Pages/CalendarParts.swift (CalendarGrid), Pages/CalendarPage.swift (Titelhöhe), ParalistCore Planning/NestedCollapse.swift, Entries/SwipeRecognizers.swift (gleiche Suche nach der UIScrollView)
import ParalistCore
import SwiftUI
import UIKit

struct CalendarCollapse: UIViewRepresentable {
    let collapse: CGFloat
    let limit: CGFloat
    let onCollapse: (CGFloat) -> Void

    @MainActor
    final class Coordinator: NSObject {
        var parent: CalendarCollapse
        var collapse: CGFloat = 0
        weak var attached: UIScrollView?
        var observation: NSKeyValueObservation?
        var adjusting = false

        init(_ parent: CalendarCollapse) {
            self.parent = parent
            self.collapse = parent.collapse
        }

        func attach(from view: UIView) {
            var current: UIView? = view
            while let next = current, !(next is UIScrollView) { current = next.superview }
            guard let scroll = current as? UIScrollView, scroll !== attached else { return }
            attached = scroll
            observation = scroll.observe(\.contentOffset, options: [.old, .new]) { [weak self] scroll, change in
                MainActor.assumeIsolated { self?.moved(scroll, change.oldValue, change.newValue) }
            }
        }

        func moved(_ scroll: UIScrollView, _ old: CGPoint?, _ new: CGPoint?) {
            guard !adjusting, let old, let new, scroll.isTracking || scroll.isDecelerating, parent.limit > 0 else { return }
            let next = NestedCollapse.step(collapse: collapse, limit: parent.limit, top: -scroll.adjustedContentInset.top, old: old.y, new: new.y)
            guard next.collapse != collapse else { return }
            collapse = next.collapse
            adjusting = true
            scroll.contentOffset.y = next.offset
            adjusting = false
            parent.onCollapse(collapse)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.collapse = collapse
        DispatchQueue.main.async { context.coordinator.attach(from: view) }
    }

    static func dismantleUIView(_ view: UIView, coordinator: Coordinator) {
        coordinator.observation?.invalidate()
    }
}
