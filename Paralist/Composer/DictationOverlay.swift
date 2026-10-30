// Zusammenhang: Composer/ComposerSheet.swift, Composer/ComposerDictation.swift, Capture/SpeechDictation.swift, Composer/DictationSheet.swift (Chat), Theme/Dimens.swift (ComposerDimens), Theme/Typography.swift
import SwiftUI

struct DictationOverlay: View {
    let dictation: ComposerDictation
    let onDiscard: () -> Void
    let onApply: () -> Void
    let onClear: () -> Void
    let onAgain: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ComposerDimens.dictationGap) {
            if dictation.stage != .idle {
                Text(dictation.text.isEmpty ? status : dictation.text)
                    .font(Typo.dm(ComposerDimens.dictationFont, .medium))
                    .foregroundStyle(dictation.text.isEmpty ? Palette.onSurfaceVariant : Palette.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.opacity)
            }
            if dictation.stage == .idle {
                HStack(spacing: ComposerDimens.dictationGap) {
                    secondary(L.s(dictation.intoBody ? "dictation_clear_body" : "dictation_clear_title"), action: onClear)
                    primary(L.s("dictation_again"), action: onAgain)
                }
            } else {
                HStack(spacing: ComposerDimens.dictationGap) {
                    secondary(L.s("dictation_discard"), action: onDiscard)
                    primary(L.s("dictation_apply"), action: onApply, busy: dictation.stage == .checking)
                        .disabled(!dictation.listening)
                        .opacity(dictation.listening || dictation.stage == .checking ? 1 : 0.5)
                }
            }
        }
        .padding(.horizontal, ComposerDimens.textInset)
        .padding(.bottom, ComposerDimens.inset)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L.s("dictation_title"))
    }

    private func secondary(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Typo.labelLarge).foregroundStyle(Palette.onSurface)
                .frame(maxWidth: .infinity, minHeight: ComposerDimens.dictationButton)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
    }

    private func primary(_ label: String, action: @escaping () -> Void, busy: Bool = false) -> some View {
        Button(action: action) {
            ZStack {
                Text(label)
                    .font(Typo.labelLarge).foregroundStyle(Palette.onPrimary)
                    .opacity(busy ? 0 : 1)
                if busy { ProgressView().tint(Palette.onPrimary) }
            }
            .frame(maxWidth: .infinity, minHeight: ComposerDimens.dictationButton)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(Palette.primary).interactive(), in: Capsule())
    }

    private var status: String {
        if dictation.stage == .checking { return L.s("dictation_checking") }
        switch dictation.phase {
        case .idle, .preparing: return L.s("dictation_preparing")
        case .loading(let part): return L.f("dictation_loading", Int(part * 100))
        case .listening: return L.s(dictation.intoBody ? "dictation_body_hint" : "dictation_hint")
        case .failed(let message): return message
        }
    }
}
