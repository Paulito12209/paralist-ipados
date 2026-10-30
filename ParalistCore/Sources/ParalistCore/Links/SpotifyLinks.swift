// Zusammenhang: Links/VideoLinks.swift, Paralist/Entry/SpotifyPlayer.swift, Paralist/Entry/EntryHero.swift, Tests/ParalistCoreTests/SpotifyLinksTests.swift
import Foundation

public struct SpotifyItem: Hashable, Sendable {
    public let kind: String
    public let id: String

    public var uri: String { "spotify:\(kind):\(id)" }
    public var isTrack: Bool { kind == "track" || kind == "episode" }
}

public enum SpotifyLinks {
    private static let kinds: Set<String> = ["track", "album", "playlist", "episode", "show", "artist"]
    private static let idPattern = Pattern("^[A-Za-z0-9]{22}$")

    public static func item(_ url: String) -> SpotifyItem? {
        let text = url.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("spotify:") {
            let parts = text.split(separator: ":").map(String.init)
            guard parts.count == 3 else { return nil }
            return make(parts[1], parts[2])
        }
        guard let components = URLComponents(string: text), components.host?.lowercased() == "open.spotify.com" else { return nil }
        var segments = components.path.split(separator: "/").map(String.init)
        if segments.first?.hasPrefix("intl-") == true { segments.removeFirst() }
        if segments.first == "embed" { segments.removeFirst() }
        guard segments.count >= 2 else { return nil }
        return make(segments[0], segments[1])
    }

    public static func isPlayerHost(_ host: String?) -> Bool {
        guard let h = host?.lowercased() else { return false }
        return h == "spotify.com" || h.hasSuffix(".spotify.com") || h.hasSuffix(".scdn.co") || h == "scdn.co" ||
            h.hasSuffix(".spotifycdn.com") || h.hasSuffix(".spotify.net")
    }

    private static func make(_ kind: String, _ id: String) -> SpotifyItem? {
        guard kinds.contains(kind), idPattern.matches(id) else { return nil }
        return SpotifyItem(kind: kind, id: id)
    }
}
