// Zusammenhang: Chat/ChatThreadPage.swift, Chat/ChatMascotActor.swift, Chat/ChatMascotView.swift, Chat/ChatMascotProps.swift, Chat/ChatEngine.swift (ChatFailure), ParalistCore Chat/ChatMascot.swift (MascotTopic), Theme/Dimens.swift (MascotDimens, Motion), docs/chat.md
import ParalistCore
import SwiftUI

struct MascotMotion {
    var y: CGFloat = 0
    var squash: CGFloat = 1
    var tilt: Double = 0
}

struct ChatMascotStage: View {
    let failure: ChatFailure?
    let working: Bool
    let topics: Set<MascotTopic>
    var intro = false
    let retry: () -> Void
    var dismissIntro: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var actor = MascotActor()

    private var phase: MascotPhase { failure != nil ? .failed : (working ? .working : .calm) }
    private var fallen: Bool { failure != nil && failure != .cancelled }

    var body: some View {
        HStack(alignment: .bottom, spacing: MascotDimens.bubbleGap) {
            ZStack(alignment: .bottomLeading) {
                if let prop = actor.prop {
                    propView(prop)
                        .frame(width: prop.size.width, height: prop.size.height)
                        .rotationEffect(.degrees(actor.propRotation))
                        .opacity(actor.propOpacity)
                        .offset(x: actor.propX, y: actor.propY)
                }
                mascot
            }
            .frame(maxWidth: failure == nil && !intro ? .infinity : nil, alignment: .bottomLeading)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { actor.track = max(0, $0 - MascotDimens.width) }
            .accessibilityHidden(phase == .calm)
            .accessibilityLabel(phase == .working ? L.s("chat_mascot_working") : "")
            if let failure {
                bubble(L.s(actor.text(for: failure)), button: L.s("chat_retry"), action: retry)
                    .transition(.scale(scale: 0.6, anchor: .bottomLeading).combined(with: .opacity))
            } else if intro {
                bubble(L.s("chat_intro"), button: L.s("dialog_ok"), action: dismissIntro)
                    .transition(.scale(scale: 0.6, anchor: .bottomLeading).combined(with: .opacity))
            }
        }
        .padding(.horizontal, ComposerDimens.edge + 8)
        .padding(.bottom, MascotDimens.floor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.fall, value: failure)
        .animation(Motion.fall, value: intro)
        .task(id: phase) {
            guard phase != .failed else { return }
            await actor.direct(working: phase == .working)
        }
        .task(id: phase) {
            guard phase != .failed else { return }
            await actor.blink()
        }
        .onChange(of: failure, initial: true) { _, now in actor.pose(for: now) }
        .onChange(of: intro, initial: true) { _, now in if now { actor.greet() } }
        .onChange(of: topics, initial: true) { _, now in actor.topics = now }
        .onChange(of: reduceMotion, initial: true) { _, now in actor.reduceMotion = now }
    }

    @ViewBuilder
    private func propView(_ prop: MascotProp) -> some View {
        switch prop {
        case .card: MascotCardProp(split: actor.propSplit)
        case .rocket: MascotRocketProp()
        }
    }

    private var mascot: some View {
        ChatMascotView(face: actor.face, gaze: actor.gaze, cover: actor.cover, slant: actor.slant)
            .keyframeAnimator(initialValue: MascotMotion(), trigger: actor.hops) { content, value in
                content
                    .scaleEffect(x: 1 + (1 - value.squash) * 0.6, y: value.squash, anchor: .bottom)
                    .offset(y: value.y)
            } keyframes: { _ in
                KeyframeTrack(\.squash) {
                    CubicKeyframe(0.8, duration: 0.1)
                    CubicKeyframe(1.15, duration: 0.12)
                    CubicKeyframe(1.0, duration: 0.2)
                    CubicKeyframe(0.85, duration: 0.1)
                    SpringKeyframe(1.0, duration: 0.3)
                }
                KeyframeTrack(\.y) {
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(-MascotDimens.hop, duration: 0.26)
                    CubicKeyframe(0, duration: 0.24)
                }
            }
            .keyframeAnimator(initialValue: MascotMotion(), trigger: actor.steps) { content, value in
                content
                    .rotationEffect(.degrees(value.tilt), anchor: .bottom)
                    .offset(y: value.y)
            } keyframes: { _ in
                let step = actor.stepSeconds / 3
                KeyframeTrack(\.y) {
                    CubicKeyframe(-3, duration: step / 2)
                    CubicKeyframe(0, duration: step / 2)
                    CubicKeyframe(-3, duration: step / 2)
                    CubicKeyframe(0, duration: step / 2)
                    CubicKeyframe(-3, duration: step / 2)
                    CubicKeyframe(0, duration: step / 2)
                }
                KeyframeTrack(\.tilt) {
                    CubicKeyframe(4, duration: step / 2)
                    CubicKeyframe(-4, duration: step)
                    CubicKeyframe(4, duration: step)
                    CubicKeyframe(0, duration: step / 2)
                }
            }
            .rotationEffect(.degrees(actor.tilt), anchor: .bottom)
            .rotationEffect(.degrees(fallen ? 90 : 0))
            .offset(x: actor.x, y: fallen ? -MascotDimens.lieDown : 0)
    }

    private func bubble(_ text: String, button: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text).font(Typo.bodyMedium).foregroundStyle(Palette.onSurface)
            Button(button, action: action)
                .font(Typo.labelLarge)
                .buttonStyle(.glass)
        }
        .padding(.leading, ChatDimens.bubblePadH + MascotDimens.bubbleTail)
        .padding(.trailing, ChatDimens.bubblePadH)
        .padding(.vertical, ChatDimens.bubblePadV)
        .background(Palette.surfaceContainer, in: SpeechBubble())
    }
}
