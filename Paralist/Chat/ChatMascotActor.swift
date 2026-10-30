// Zusammenhang: Chat/ChatMascotStage.swift, Chat/ChatMascotScenes.swift (Szenen), Chat/ChatMascotView.swift (MascotFace), Chat/ChatMascotProps.swift (MascotProp), Chat/ChatEngine.swift (ChatFailure), ParalistCore Chat/ChatMascot.swift (MascotScript, MascotScenes), Theme/Dimens.swift (MascotDimens, Motion)
import Observation
import ParalistCore
import SwiftUI

enum MascotPhase: Equatable {
    case calm, working, failed
}

@MainActor
@Observable
final class MascotActor {
    var face = MascotFace.neutral
    var gaze: CGFloat = 0
    var cover: CGFloat = 0
    var slant: CGFloat = 0
    var x: CGFloat = 0
    var tilt: Double = 0
    var hops = 0
    var steps = 0
    var stepSeconds = 1.0
    var track: CGFloat = 0
    var prop: MascotProp?
    var propX: CGFloat = 0
    var propY: CGFloat = 0
    var propRotation: Double = 0
    var propSplit: CGFloat = 0
    var propOpacity: Double = 1
    var quip: Int?
    var topics: Set<MascotTopic> = []
    var reduceMotion = false

    static let quips = ["chat_mascot_quip_1", "chat_mascot_quip_2", "chat_mascot_quip_3", "chat_mascot_quip_4"]

    var stageEnd: CGFloat { track + MascotDimens.width }

    func pose(for failure: ChatFailure?) {
        guard let failure else {
            withAnimation(Motion.fall) { set(face: .neutral, gaze: 0) }
            return
        }
        var rng = SystemRandomNumberGenerator()
        quip = MascotScript.quip(count: Self.quips.count, avoiding: quip, using: &rng)
        clearProp()
        withAnimation(Motion.fall) {
            set(face: failure == .cancelled ? .tired : .dead, gaze: 0)
            tilt = 0
            x = 0
        }
    }

    func greet() {
        withAnimation(Motion.fall) {
            set(face: .excited, gaze: 0)
            x = 0
        }
        hops += 1
    }

    func text(for failure: ChatFailure) -> String {
        failure == .generic ? Self.quips[quip ?? 0] : ChatFailureText.key(failure)
    }

    func set(face: MascotFace? = nil, gaze: CGFloat? = nil) {
        if let face {
            self.face = face
            cover = face.cover
            slant = face.slant
        }
        if let gaze { self.gaze = gaze }
    }

    func clearProp() {
        prop = nil
        propSplit = 0
        propOpacity = 1
        propRotation = 0
        propY = 0
    }

    func show(_ prop: MascotProp) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            propX = stageEnd + 40
            propY = 0
            propRotation = 0
            propSplit = 0
            propOpacity = 1
            self.prop = prop
        }
    }

    func walk(to target: CGFloat, seconds: Double) {
        let clamped = min(max(0, target), track)
        guard clamped != x else { return }
        gaze = clamped > x ? 1 : -1
        stepSeconds = seconds
        withAnimation(.easeInOut(duration: seconds)) { x = clamped }
        steps += 1
    }

    func lunge(_ distance: CGFloat) async throws {
        let back = x
        withAnimation(.easeIn(duration: 0.15)) { x = min(max(0, x + distance), track) }
        try await Task.sleep(for: .milliseconds(220))
        withAnimation(.easeOut(duration: 0.3)) { x = back }
    }

    func direct(working: Bool) async {
        var previous: MascotMood?
        var previousScene: MascotScene?
        var rng = SystemRandomNumberGenerator()
        var untilScene = MascotScenes.beatsUntilScene(using: &rng)
        defer { clearProp() }
        while !Task.isCancelled {
            if !working {
                untilScene -= 1
                if untilScene <= 0, !reduceMotion, let scene = MascotScenes.pick(topics: topics, avoiding: previousScene, using: &rng) {
                    untilScene = MascotScenes.beatsUntilScene(using: &rng)
                    previousScene = scene
                    do { try await play(scene) } catch { return }
                    clearProp()
                    continue
                }
            }
            let beat = MascotScript.next(after: previous, calm: !working, using: &rng)
            previous = beat.mood
            perform(beat)
            try? await Task.sleep(for: .seconds(beat.seconds))
        }
    }

    private func perform(_ beat: MascotBeat) {
        let tired = beat.mood == .tired
        withAnimation(Motion.short) {
            set(face: beat.mood == .happy ? .happy : (tired ? .tired : .neutral))
        }
        withAnimation(.easeInOut(duration: tired ? beat.seconds : 0.3)) { tilt = tired ? beat.direction * 8 : 0 }
        switch beat.mood {
        case .glance:
            gaze = beat.direction
        case .idle, .happy, .tired:
            gaze = 0
        case .hop:
            gaze = 0
            if !reduceMotion { hops += 1 }
        case .walk:
            gaze = beat.direction
            guard !reduceMotion else { return }
            var target = x + beat.direction * MascotDimens.walk
            if target < 0 || target > track { target = x - beat.direction * MascotDimens.walk }
            walk(to: target, seconds: beat.seconds * 0.9)
        }
    }

    func blink() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 1.6...4.0)))
            guard !Task.isCancelled, face != .happy, face != .excited, face != .dead else { continue }
            let rest = cover
            cover = 1
            try? await Task.sleep(for: .milliseconds(110))
            if cover == 1 { cover = rest }
        }
    }
}
