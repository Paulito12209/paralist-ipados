// Zusammenhang: Paralist/Net/LinkIcons.swift, Paralist/Resources/Assets.xcassets/LinkLogos, Links/LinkBrand.swift, Tests LinkLogoLibraryTests.swift
import Foundation

public enum LinkLogoLibrary {
    public static let folder = "LinkLogos"

    private static let aliases: [String: String] = [
        "youtu.be": "youtube.com", "youtube-nocookie.com": "youtube.com",
        "lnkd.in": "linkedin.com",
        "notion.site": "notion.so",
        "redd.it": "reddit.com",
        "twitter.com": "x.com", "t.co": "x.com",
        "instagr.am": "instagram.com",
        "amzn.to": "amazon.de", "amzn.eu": "amazon.de", "amazon.com": "amazon.de",
        "spotify.link": "spotify.com",
        "goo.gl": "google.com", "g.co": "google.com", "google.de": "google.com",
        "fig.ma": "figma.com",
        "anthropic.com": "claude.ai",
    ]

    public static func candidates(_ url: String) -> [String] {
        guard let host = LinkBrand.host(url) else { return [] }
        var out: [String] = []
        var labels = host.split(separator: ".").map(String.init)
        while labels.count >= 2 {
            let name = labels.joined(separator: ".")
            out.append(name)
            if let alias = aliases[name] { out.append(alias) }
            labels.removeFirst()
        }
        return out
    }

    public static func assetNames(_ url: String) -> [String] {
        candidates(url).map { folder + "/" + $0 }
    }
}
