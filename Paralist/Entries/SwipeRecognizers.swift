// Zusammenhang: Entries/RowSwipe.swift (RowSwipeState, RowSwipeGesture für ScrollView, RowSwipeHost für List), Pages/ListPage.swift (Reiter wischen, ContentPopGate), Pages/OverviewPage.swift, Theme/Dimens.swift (SwipeDimens)
import SwiftUI
import UIKit

@MainActor
enum RowHold {
    static var active = false
}

final class HoldPanRecognizer: UIGestureRecognizer {
    var hold: Double = 0.25
    var slop: CGFloat = 10
    var canArm: (CGPoint) -> Bool = { _ in false }
    var onArm: (CGPoint) -> Void = { _ in }
    var onDisarm: () -> Void = {}
    private(set) var dx: CGFloat = 0
    private var start: CGPoint = .zero
    private var armed = false
    private var timer: Timer?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard touches.count == 1, let touch = touches.first, numberOfTouches <= 1 else { state = .failed; return }
        start = touch.location(in: nil)
        guard canArm(start) else { state = .failed; return }
        timer = Timer.scheduledTimer(withTimeInterval: hold, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.state == .possible else { return }
                self.armed = true
                RowHold.active = true
                self.onArm(self.start)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let point = touches.first?.location(in: nil) else { return }
        dx = point.x - start.x
        let moved = max(abs(dx), abs(point.y - start.y))
        if !armed {
            if moved > slop { state = .failed }
        } else if state == .possible {
            if abs(dx) > slop / 2 { state = .began }
        } else {
            state = .changed
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .began || state == .changed {
            state = .ended
        } else {
            if armed { onDisarm() }
            state = .failed
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .began || state == .changed {
            state = .cancelled
        } else {
            if armed { onDisarm() }
            state = .failed
        }
    }

    override func reset() {
        timer?.invalidate()
        timer = nil
        armed = false
        dx = 0
        RowHold.active = false
        super.reset()
    }
}

struct HoldDragRecognizer: UIGestureRecognizerRepresentable {
    let hold: Double
    let canBegin: (CGPoint) -> Bool
    let onBegin: (CGPoint) -> Void
    let onChange: (CGFloat) -> Void
    let onEnd: (CGFloat?) -> Void

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> HoldPanRecognizer {
        let recognizer = HoldPanRecognizer()
        recognizer.delegate = context.coordinator
        recognizer.cancelsTouchesInView = true
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: HoldPanRecognizer, context: Context) {
        recognizer.hold = hold
        recognizer.slop = SwipeDimens.slop
        recognizer.canArm = canBegin
        recognizer.onArm = onBegin
        recognizer.onDisarm = { onEnd(nil) }
    }

    func handleUIGestureRecognizerAction(_ recognizer: HoldPanRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed: onChange(recognizer.dx)
        case .ended: onEnd(recognizer.dx)
        case .cancelled: onEnd(nil)
        default: break
        }
    }
}

struct HoldDragInstaller: UIViewRepresentable {
    let hold: Double
    let canBegin: (CGPoint) -> Bool
    let onBegin: (CGPoint) -> Void
    let onChange: (CGFloat) -> Void
    let onEnd: (CGFloat?) -> Void

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: HoldDragInstaller
        weak var attached: UIScrollView?
        let recognizer = HoldPanRecognizer()

        init(_ parent: HoldDragInstaller) {
            self.parent = parent
            super.init()
            recognizer.addTarget(self, action: #selector(handle(_:)))
            recognizer.delegate = self
        }

        func attach(from view: UIView) {
            recognizer.hold = parent.hold
            recognizer.slop = SwipeDimens.slop
            recognizer.canArm = { [weak self] in self?.parent.canBegin($0) ?? false }
            recognizer.onArm = { [weak self] in self?.parent.onBegin($0) }
            recognizer.onDisarm = { [weak self] in self?.parent.onEnd(nil) }
            var current: UIView? = view
            while let next = current, !(next is UIScrollView) { current = next.superview }
            guard let scroll = current as? UIScrollView, scroll !== attached else { return }
            attached?.removeGestureRecognizer(recognizer)
            scroll.addGestureRecognizer(recognizer)
            attached = scroll
        }

        @objc func handle(_ recognizer: HoldPanRecognizer) {
            switch recognizer.state {
            case .began, .changed: parent.onChange(recognizer.dx)
            case .ended: parent.onEnd(recognizer.dx)
            case .cancelled: parent.onEnd(nil)
            default: break
            }
        }

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.parent = self
        DispatchQueue.main.async { context.coordinator.attach(from: view) }
    }

    static func dismantleUIView(_ view: UIView, coordinator: Coordinator) {
        coordinator.attached?.removeGestureRecognizer(coordinator.recognizer)
    }
}

struct SidePanRecognizer: UIGestureRecognizerRepresentable {
    let edge: CGFloat
    var skip: (CGPoint) -> Bool = { _ in false }
    let onMove: () -> Void
    let onEnd: (CGSize, CGFloat, CGFloat) -> Void

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var edge: CGFloat = 0
        var skip: (CGPoint) -> Bool = { _ in false }

        func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
            guard !RowHold.active, let pan = g as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            let start = pan.location(in: nil)
            return start.x > edge && abs(velocity.x) > abs(velocity.y) && !skip(start)
        }

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        context.coordinator.edge = edge
        context.coordinator.skip = skip
        recognizer.delegate = context.coordinator
        recognizer.cancelsTouchesInView = false
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.skip = skip
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let t = recognizer.translation(in: nil)
        switch recognizer.state {
        case .began, .changed:
            if RowHold.active { recognizer.state = .cancelled } else { onMove() }
        case .ended: onEnd(CGSize(width: t.x, height: t.y), recognizer.velocity(in: nil).x, recognizer.location(in: nil).x - t.x)
        default: break
        }
    }
}

struct ContentPopGate: UIViewControllerRepresentable {
    let enabled: Bool

    func makeUIViewController(context: Context) -> Host { Host() }

    func updateUIViewController(_ controller: Host, context: Context) {
        controller.enabled = enabled
        controller.apply()
    }

    final class Host: UIViewController {
        var enabled = true

        func apply() {
            navigationController?.interactiveContentPopGestureRecognizer?.isEnabled = enabled
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            apply()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            navigationController?.interactiveContentPopGestureRecognizer?.isEnabled = true
        }
    }
}
