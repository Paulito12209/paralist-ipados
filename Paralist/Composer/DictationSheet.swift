// Zusammenhang: Capture/SpeechDictation.swift, Chat/ChatInputBar.swift (einziger Nutzer), Composer/DictationBar.swift (Gegenstück im Erstellen-Panel)
import SwiftUI

struct DictationSheet: View {
    let onText: (String) -> Void
    @State private var dictation = SpeechDictation()
    @State private var closing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Text(L.s("dictation_title")).font(Typo.titleMedium).foregroundStyle(Palette.onSurfaceVariant)
            Image(systemName: AppIcons.audio)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Palette.primary)
                .symbolEffect(.variableColor.iterative, isActive: dictation.phase == .listening)
            ScrollView {
                Text(dictation.text.isEmpty ? status : dictation.text)
                    .font(Typo.dm(20, .medium))
                    .foregroundStyle(dictation.text.isEmpty ? Palette.onSurfaceVariant : Palette.onSurface)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 120)
            .defaultScrollAnchor(.bottom)
            HStack(spacing: 28) {
                Button { close() } label: {
                    Image(systemName: AppIcons.close).font(.system(size: 20, weight: .medium)).foregroundStyle(Palette.onSurface)
                        .frame(width: 56, height: 56)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel(L.s("dialog_cancel"))
                Button { done() } label: {
                    Image(systemName: AppIcons.check).font(.system(size: 24, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(Palette.primary).interactive(), in: Circle())
                .disabled(dictation.phase != .listening || closing)
                .accessibilityLabel(L.s("dialog_ok"))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .presentationDetents([.height(380)])
        .task { await dictation.start() }
        .onDisappear { if !closing { dictation.cancel() } }
    }

    private var status: String {
        switch dictation.phase {
        case .idle, .preparing: return L.s("dictation_preparing")
        case .loading(let part): return L.f("dictation_loading", Int(part * 100))
        case .listening: return L.s("dictation_hint")
        case .failed(let message): return message
        }
    }

    private func close() {
        dictation.cancel()
        dismiss()
    }

    private func done() {
        closing = true
        Task {
            let text = await dictation.finish()
            if !text.isEmpty { onText(text) }
            dismiss()
        }
    }
}
