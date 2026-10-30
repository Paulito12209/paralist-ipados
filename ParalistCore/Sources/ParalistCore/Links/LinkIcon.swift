// Zusammenhang: Paralist/Net/LinkIcons.swift, Links/LinkBrand.swift, Links/TitleExtractor.swift, Tests LinkIconTests.swift
import Foundation

public enum LinkIcon {
    private static let link = Pattern("<link\\b[^>]*>", ignoreCase: true)
    private static let rel = Pattern("\\brel\\s*=\\s*[\"']([^\"']*)[\"']", ignoreCase: true)
    private static let href = Pattern("\\bhref\\s*=\\s*[\"']([^\"']*)[\"']", ignoreCase: true)
    private static let sizes = Pattern("\\bsizes\\s*=\\s*[\"']([^\"']*)[\"']", ignoreCase: true)
    private static let type = Pattern("\\btype\\s*=\\s*[\"']([^\"']*)[\"']", ignoreCase: true)
    private static let touchRels: Set<String> = ["apple-touch-icon", "apple-touch-icon-precomposed"]
    private static let plainRels: Set<String> = ["icon", "shortcut"]

    public static func iconUrl(html: String, page: String) -> String? {
        guard let base = URL(string: page) else { return nil }
        var best: (score: Int, url: String)?
        for tag in link.all(in: html) {
            let text = tag.value
            guard let r = rel.first(in: text), let h = href.first(in: text) else { continue }
            let rels = Set(r.group(1).lowercased().split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init))
            let touch = !rels.isDisjoint(with: touchRels)
            guard touch || !rels.isDisjoint(with: plainRels) else { continue }
            let raw = TitleExtractor.clean(h.group(1))
            if raw.lowercased().hasSuffix(".svg") || (type.first(in: text)?.group(1).lowercased().contains("svg") ?? false) { continue }
            guard let resolved = URL(string: raw, relativeTo: base)?.absoluteURL, let scheme = resolved.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else { continue }
            let score = (touch ? 1000 : 0) + size(sizes.first(in: text)?.group(1))
            if best == nil || score > best!.score { best = (score, resolved.absoluteString) }
        }
        return best?.url
    }

    public static func fallbackUrl(page: String) -> String? {
        guard let c = URLComponents(string: page), let scheme = c.scheme, let host = c.host, !host.isEmpty else { return nil }
        return "\(scheme)://\(host)/favicon.ico"
    }

    private static func size(_ value: String?) -> Int {
        guard let value else { return 0 }
        return value.lowercased().split(separator: " ").compactMap { Int($0.split(separator: "x").first ?? "") }.max() ?? 0
    }
}
