// Zusammenhang: Search/SearchView.swift, Theme/Typography.swift, Theme/Palette.swift
import SwiftUI
import UIKit

struct SearchTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var focused: Bool
    let placeholder: String
    let onSubmit: () -> Void
    @Environment(\.colorScheme) private var scheme

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ToggleTextField {
        let field = ToggleTextField()
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        field.font = Typo.uiFont(16)
        field.returnKeyType = .search
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.autocapitalizationType = .none
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.smartInsertDeleteType = .no
        field.inlinePredictionType = .no
        field.inputAssistantItem.leadingBarButtonGroups = []
        field.inputAssistantItem.trailingBarButtonGroups = []
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator
        field.addGestureRecognizer(tap)
        return field
    }

    func updateUIView(_ field: ToggleTextField, context: Context) {
        context.coordinator.parent = self
        if field.text != text { field.text = text }
        field.textColor = UIColor(Palette.onSurface)
        field.tintColor = UIColor(Palette.onSurface)
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(Palette.muted), .font: Typo.uiFont(16)]
        )
        if focused, !field.isFirstResponder {
            DispatchQueue.main.async { field.becomeFirstResponder() }
        } else if !focused, field.isFirstResponder {
            DispatchQueue.main.async { field.resignFirstResponder() }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: ToggleTextField, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 120, height: proposal.height ?? uiView.intrinsicContentSize.height)
    }

    final class ToggleTextField: UITextField {
        var focusedAtTouch = false

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            focusedAtTouch = isFirstResponder
            super.touchesBegan(touches, with: event)
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate, UIGestureRecognizerDelegate {
        var parent: SearchTextField

        init(_ parent: SearchTextField) { self.parent = parent }

        @objc func changed(_ field: UITextField) {
            parent.text = field.text ?? ""
        }

        @objc func tapped(_ recognizer: UITapGestureRecognizer) {
            guard let field = recognizer.view as? ToggleTextField, field.focusedAtTouch else { return }
            field.focusedAtTouch = false
            parent.focused = false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }

        func textFieldDidBeginEditing(_ field: UITextField) {
            DispatchQueue.main.async { self.parent.focused = true }
        }

        func textFieldDidEndEditing(_ field: UITextField) {
            DispatchQueue.main.async { self.parent.focused = false }
        }

        func textFieldShouldReturn(_ field: UITextField) -> Bool {
            parent.onSubmit()
            return false
        }
    }
}
