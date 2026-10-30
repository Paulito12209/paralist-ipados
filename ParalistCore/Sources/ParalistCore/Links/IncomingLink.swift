// Zusammenhang: Paralist/App/ParalistApp.swift, ParalistWidgets/EntryWidgetView.swift, Library/WidgetPicks.swift, Links/SharedText.swift, Model/EntryCodec.swift, Paralist/Paralist.entitlements
import Foundation

public enum IncomingLink: Hashable, Sendable {
    case entry(String)
    case briefing
    case share(text: String?, title: String?)

    public static let scheme = "paralist-ipad"
    public static let acceptedSchemes: Set<String> = [scheme, "paralist"]
    public static let webHost = "xool-app.de"
    public static let webPrefix = "p"

    public static func entryURL(_ id: String) -> URL? {
        guard EntryCodec.isValidId(id) else { return nil }
        return URL(string: "\(scheme)://eintrag/\(id)")
    }

    public static func parse(_ url: URL) -> IncomingLink? {
        guard let route = route(for: url) else { return nil }
        switch route.kind {
        case "eintrag":
            guard let id = route.rest.first, EntryCodec.isValidId(id) else { return nil }
            return .entry(id)
        case "briefing":
            return .briefing
        case "teilen":
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            return .share(text: items.first { $0.name == "text" }?.value, title: items.first { $0.name == "titel" }?.value)
        default:
            return nil
        }
    }

    private static func route(for url: URL) -> (kind: String, rest: [String])? {
        let parts = url.pathComponents.filter { $0 != "/" }
        let scheme = url.scheme?.lowercased()
        let host = url.host?.lowercased()
        if let scheme, Self.acceptedSchemes.contains(scheme) {
            guard let host else { return nil }
            return (host, parts)
        }
        guard scheme == "https", host == webHost, parts.first == webPrefix, parts.count >= 2 else { return nil }
        return (parts[1].lowercased(), Array(parts.dropFirst(2)))
    }
}
