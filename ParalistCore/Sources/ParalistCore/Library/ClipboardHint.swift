// Zusammenhang: Paralist/App/ClipboardMemory.swift, Paralist/Composer/ComposerSheet.swift, ParalistShare/ShareModel.swift, Library/LinkHistory.swift, Tests/ClipboardHintTests.swift
import Foundation

public struct ClipboardHint: Codable, Equatable, Sendable {
    public static let lifetime: TimeInterval = 12 * 60 * 60
    public static let remoteMarker = "com.apple.is-remote-clipboard"

    public var change: Int
    public var seen: Date
    public var handled: Bool
    public var install: String

    public init(change: Int = -1, seen: Date = .distantPast, handled: Bool = false, install: String = "") {
        self.change = change
        self.seen = seen
        self.handled = handled
        self.install = install
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        change = try values.decode(Int.self, forKey: .change)
        seen = try values.decode(Date.self, forKey: .seen)
        handled = try values.decode(Bool.self, forKey: .handled)
        install = try values.decodeIfPresent(String.self, forKey: .install) ?? ""
    }

    public func observing(_ change: Int, install: String, at now: Date) -> ClipboardHint {
        if install != self.install || change < self.change { return ClipboardHint(change: change, seen: now, handled: true, install: install) }
        return change == self.change ? self : ClipboardHint(change: change, seen: now, install: install)
    }

    public func handling(_ change: Int, install: String, at now: Date) -> ClipboardHint {
        var next = observing(change, install: install, at: now)
        next.handled = true
        return next
    }

    public func shows(_ change: Int, hasLink: Bool, remote: Bool, at now: Date) -> Bool {
        guard hasLink, !remote, change == self.change, !handled else { return false }
        let age = now.timeIntervalSince(seen)
        return age >= 0 && age < Self.lifetime
    }

    public static func install(fromPath components: [String]) -> String {
        guard let app = components.firstIndex(where: { $0.hasSuffix(".app") }), app > 0 else { return "" }
        return components[app - 1]
    }

    public static func isRemote(_ types: [String]) -> Bool {
        types.contains(remoteMarker)
    }
}
