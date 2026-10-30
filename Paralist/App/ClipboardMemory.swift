// Zusammenhang: ParalistCore Library/ClipboardHint.swift, App/AppPaths.swift, Composer/ComposerSheet.swift, App/AppModel.swift, Entry/EntryTitle.swift, ParalistShare/ShareModel.swift
import Foundation
import ParalistCore
import UIKit

@MainActor
enum ClipboardMemory {
    private static let key = "clipboard_hint"
    private static let legacyKey = "clipboard_dismissed_change"

    static var hint: ClipboardHint {
        get {
            let defaults = AppPaths.defaults
            if let data = defaults.data(forKey: key), let hint = try? JSONDecoder().decode(ClipboardHint.self, from: data) { return hint }
            if let old = defaults.object(forKey: legacyKey) as? Int { return ClipboardHint(change: old, handled: true) }
            return ClipboardHint()
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            AppPaths.defaults.set(data, forKey: key)
        }
    }

    private static var install: String {
        ClipboardHint.install(fromPath: Bundle.main.bundleURL.pathComponents)
    }

    static func observe() -> ClipboardHint {
        let next = hint.observing(UIPasteboard.general.changeCount, install: install, at: Date())
        hint = next
        return next
    }

    static func fresh() -> Bool {
        let board = UIPasteboard.general
        return observe().shows(board.changeCount, hasLink: board.hasURLs, remote: ClipboardHint.isRemote(board.types), at: Date())
    }

    static func markHandled() {
        hint = hint.handling(UIPasteboard.general.changeCount, install: install, at: Date())
    }
}
