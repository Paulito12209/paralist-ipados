// Zusammenhang: Paralist/Entry/YouTubePlayer.swift, Paralist/Entry/EntryHero.swift
import Foundation

public enum VideoLinks {
    private static let hosts: Set<String> = ["youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtube-nocookie.com", "www.youtube-nocookie.com"]
    private static let pathPrefixes = ["/shorts/", "/embed/", "/live/", "/v/"]
    private static let idPattern = Pattern("^[A-Za-z0-9_-]{11}$")

    public static let pageOrigin = "https://paralist.app/"

    public static func youtubeId(_ url: String) -> String? {
        guard let components = URLComponents(string: url.trimmingCharacters(in: .whitespaces)),
              let host = components.host?.lowercased() else { return nil }
        let path = components.percentEncodedPath
        var candidate: String?
        if host == "youtu.be" || host == "www.youtu.be" {
            candidate = path.split(separator: "/").first.map(String.init)
        } else if hosts.contains(host) && path == "/watch" {
            candidate = components.percentEncodedQuery?.split(separator: "&")
                .first { $0.split(separator: "=", maxSplits: 1).first == "v" }
                .map { String($0.split(separator: "=", maxSplits: 1).dropFirst().first ?? "") }
        } else if hosts.contains(host), let prefix = pathPrefixes.first(where: { path.hasPrefix($0) }) {
            candidate = path.dropFirst(prefix.count).split(separator: "/").first.map(String.init)
        }
        guard let id = candidate, idPattern.matches(id) else { return nil }
        return id
    }

    public static func embedUrl(_ id: String) -> String { "https://www.youtube.com/embed/\(id)?rel=0&playsinline=1&fs=0&enablejsapi=1&origin=https://paralist.app" }

    public static func isPlayerHost(_ host: String?) -> Bool {
        guard let h = host?.lowercased() else { return false }
        return h == "youtu.be" || h == "youtube.com" || h.hasSuffix(".youtube.com") || h == "youtube-nocookie.com" ||
            h.hasSuffix(".youtube-nocookie.com") || h.hasSuffix(".google.com") || h.hasSuffix(".googlevideo.com") ||
            h.hasSuffix(".ytimg.com") || h.hasSuffix(".ggpht.com")
    }
}
