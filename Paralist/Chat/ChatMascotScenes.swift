// Zusammenhang: Chat/ChatMascotActor.swift, Chat/ChatMascotProps.swift, ParalistCore Chat/ChatMascot.swift (MascotScene), Theme/Dimens.swift (MascotDimens), docs/chat.md
import ParalistCore
import SwiftUI

extension MascotActor {
    func play(_ scene: MascotScene) async throws {
        switch scene {
        case .cardsTear: try await cards(tear: true)
        case .cardsShove: try await cards(tear: false)
        case .rocketCheer: try await rocket(cheer: true)
        case .rocketRam: try await rocket(cheer: false)
        case .tasksJoy: try await tasksJoy()
        }
    }

    private func pause(_ seconds: Double) async throws {
        try await Task.sleep(for: .seconds(seconds))
    }

    private func makeRoom() async throws {
        let limit = track * 0.35
        guard x > limit else { return }
        walk(to: limit, seconds: 0.8)
        try await pause(0.9)
        gaze = 0
    }

    private var beside: CGFloat { x + MascotDimens.width + MascotDimens.propGap }

    private func cards(tear: Bool) async throws {
        try await makeRoom()
        show(.card)
        withAnimation(.spring(duration: 0.6, bounce: 0.25)) { propX = beside }
        withAnimation(Motion.short) { set(face: .surprised, gaze: 1) }
        try await pause(0.8)
        withAnimation(Motion.short) { set(face: .neutral, gaze: 0) }
        try await pause(0.4)
        withAnimation(Motion.short) { gaze = 1 }
        try await pause(0.5)
        if tear {
            withAnimation(Motion.short) { set(face: .excited) }
            try await lunge(6)
            withAnimation(.easeOut(duration: 0.7)) { propSplit = 1 }
            try await pause(0.35)
            withAnimation(Motion.short) { set(face: .happy) }
            withAnimation(.easeIn(duration: 0.5)) { propOpacity = 0 }
            try await pause(1.0)
        } else {
            withAnimation(Motion.short) { set(face: .angry) }
            try await pause(0.45)
            withAnimation(.easeIn(duration: 0.15)) { x = min(x + 10, track) }
            try await pause(0.12)
            withAnimation(.easeIn(duration: 0.5)) {
                propX = stageEnd + 80
                propRotation = 40
                propY = -12
            }
            withAnimation(.easeOut(duration: 0.3)) { x = max(0, x - 10) }
            try await pause(0.35)
            withAnimation(Motion.short) { set(face: .neutral, gaze: 0) }
            try await pause(0.6)
        }
    }

    private func rocket(cheer: Bool) async throws {
        try await makeRoom()
        show(.rocket)
        propY = -4
        withAnimation(.easeOut(duration: 0.7)) { propX = beside + 4 }
        withAnimation(Motion.short) { set(face: .surprised, gaze: 1) }
        try await pause(0.8)
        for step in 0..<4 {
            withAnimation(Motion.short) { gaze = step % 2 == 0 ? 0 : 1 }
            withAnimation(.easeInOut(duration: 0.45)) { propY = step % 2 == 0 ? -8 : -2 }
            try await pause(0.45)
        }
        if cheer {
            withAnimation(Motion.short) { set(face: .excited, gaze: 1) }
            hops += 1
            try await pause(0.6)
            hops += 1
            try await pause(0.6)
            withAnimation(.easeIn(duration: 0.9)) {
                propY = -MascotDimens.launch
                propX += 40
                propRotation = 12
            }
            withAnimation(Motion.short) { set(face: .happy, gaze: 1) }
            try await pause(1.0)
        } else {
            withAnimation(Motion.short) { set(face: .angry, gaze: 1) }
            try await pause(0.5)
            withAnimation(.easeIn(duration: 0.18)) { x = min(x + 12, track) }
            try await pause(0.18)
            withAnimation(.easeOut(duration: 0.5)) {
                propX += 70
                propY = -60
                propRotation = 40
            }
            withAnimation(.easeOut(duration: 0.3)) { x = max(0, x - 12) }
            try await pause(0.5)
            withAnimation(.easeIn(duration: 0.55)) {
                propX += 170
                propY = 50
                propRotation = 95
            }
            withAnimation(Motion.short) { set(face: .happy, gaze: 0) }
            try await pause(0.7)
        }
    }

    private func tasksJoy() async throws {
        withAnimation(Motion.short) { set(face: .excited, gaze: 0) }
        hops += 1
        try await pause(0.55)
        hops += 1
        try await pause(0.55)
        for degrees in [10.0, -10, 8, -8, 0] {
            withAnimation(.easeInOut(duration: 0.18)) { tilt = degrees }
            try await pause(0.18)
        }
        withAnimation(Motion.short) { set(face: .happy) }
        try await pause(1.0)
    }
}
