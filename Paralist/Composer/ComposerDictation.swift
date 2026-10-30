// Zusammenhang: Composer/ComposerSheet.swift, Composer/DictationOverlay.swift, Capture/SpeechDictation.swift, Capture/SpokenRefiner.swift, ParalistCore Library/ComposerDraft.swift, ParalistCore Planning/SpokenEvent.swift, ParalistCore Planning/SpokenRefinement.swift
import Foundation
import Observation
import ParalistCore

@MainActor
@Observable
final class ComposerDictation {
    enum Stage: Equatable { case listening, checking, idle }
    enum Target: Equatable { case auto, title, body }

    let base: ComposerDraft
    let periods: DayPeriods
    let target: Target
    private(set) var stage: Stage = .listening
    private let speech = SpeechDictation()
    private let refiner = SpokenRefiner()

    init(base: ComposerDraft, periods: DayPeriods, target: Target = .auto) {
        self.base = base
        self.periods = periods
        self.target = target
    }

    var text: String { speech.text }
    var phase: SpeechDictation.Phase { speech.phase }
    var listening: Bool { speech.phase == .listening && stage == .listening }

    var intoBody: Bool { target == .body }

    func start() async {
        if base.hasDate, target == .auto { refiner.prewarm(now: Date(), zone: .current) }
        await speech.start()
    }

    func cancel() { speech.cancel() }

    func discard() {
        speech.cancel()
        stage = .idle
    }

    func preview(_ text: String) -> ComposerDraft {
        var draft = base
        guard !text.isEmpty else { return draft }
        if target == .body {
            draft.showBody = true
            draft.body = base.body.isEmpty ? text : base.body + "\n" + text
        } else if target == .title, !draft.hasDate {
            draft.title = String(text.prefix(Limits.maxInputTitleChars))
        } else if draft.type == .bookmark && !draft.urlConfirmed {
            draft.dictateUrl(text)
        } else if draft.hasDate {
            let event = spoken(text)
            draft.apply(event)
            _ = draft.remind(event, periods: periods, zone: .current)
        } else if draft.title.trimmingCharacters(in: .whitespaces).isEmpty {
            draft.title = String(text.prefix(Limits.maxInputTitleChars))
        } else {
            draft.showBody = true
            draft.body = draft.body.isEmpty ? text : draft.body + " " + text
        }
        return draft
    }

    func finish() async -> (ComposerDraft, Date?) {
        stage = .checking
        let text = await speech.finish()
        var draft = preview(text)
        guard target != .body, base.hasDate, !text.isEmpty, !(base.type == .bookmark && !base.urlConfirmed) else { return (draft, nil) }
        var event = spoken(text)
        if let refinement = await refiner.refine(text, guess: event) {
            event = event.refined(by: refinement, today: Day.of(Date(), in: .current))
            draft = base
            draft.apply(event)
        }
        let reminder = draft.remind(event, periods: periods, zone: .current)
        return (draft, reminder)
    }

    private func spoken(_ text: String) -> SpokenEvent {
        SpokenEvent.parse(text, now: Date(), zone: .current, periods: periods, baseDay: base.date, baseMinute: base.minute)
    }
}
