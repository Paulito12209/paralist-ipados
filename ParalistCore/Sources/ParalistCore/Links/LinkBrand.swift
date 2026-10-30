// Zusammenhang: Paralist/Net/LinkColors.swift, Paralist/Entries/TypeLook.swift, Links/TitleExtractor.swift, Tests LinkBrandTests.swift
import Foundation

public enum LinkBrand {
    private static let brands: [(domain: String, color: UInt32, name: String)] = [
        ("youtube.com", 0xFF0000, "YouTube"), ("youtu.be", 0xFF0000, "YouTube"), ("youtube-nocookie.com", 0xFF0000, "YouTube"),
        ("google.com", 0x4285F4, "Google"), ("google.de", 0x4285F4, "Google"), ("goo.gl", 0x4285F4, "Google"), ("g.co", 0x4285F4, "Google"),
        ("linkedin.com", 0x0A66C2, "LinkedIn"), ("lnkd.in", 0x0A66C2, "LinkedIn"),
        ("facebook.com", 0x1877F2, "Facebook"), ("fb.com", 0x1877F2, "Facebook"), ("fb.me", 0x1877F2, "Facebook"), ("messenger.com", 0x0084FF, "Messenger"),
        ("instagram.com", 0x833AB4, "Instagram"), ("instagr.am", 0x833AB4, "Instagram"),
        ("threads.net", 0x3A3A3C, "Threads"), ("threads.com", 0x3A3A3C, "Threads"),
        ("whatsapp.com", 0x25D366, "WhatsApp"), ("wa.me", 0x25D366, "WhatsApp"),
        ("x.com", 0x3A3A3C, "X"), ("twitter.com", 0x1D9BF0, "X"), ("t.co", 0x1D9BF0, "X"),
        ("bsky.app", 0x0085FF, "Bluesky"),
        ("tiktok.com", 0xFE2C55, "TikTok"),
        ("pinterest.com", 0xE60023, "Pinterest"), ("pinterest.de", 0xE60023, "Pinterest"), ("pin.it", 0xE60023, "Pinterest"),
        ("reddit.com", 0xFF4500, "Reddit"), ("redd.it", 0xFF4500, "Reddit"),
        ("twitch.tv", 0x9146FF, "Twitch"),
        ("vimeo.com", 0x1AB7EA, "Vimeo"),
        ("spotify.com", 0x1DB954, "Spotify"), ("spotify.link", 0x1DB954, "Spotify"),
        ("soundcloud.com", 0xFF5500, "SoundCloud"),
        ("music.apple.com", 0xFA2D48, "Apple Music"), ("podcasts.apple.com", 0x9933CC, "Apple Podcasts"), ("apps.apple.com", 0x0D96F6, "App Store"),
        ("netflix.com", 0xE50914, "Netflix"),
        ("github.com", 0x6E5494, "GitHub"), ("gitlab.com", 0xFC6D26, "GitLab"),
        ("stackoverflow.com", 0xF48024, "Stack Overflow"),
        ("wikipedia.org", 0x3366CC, "Wikipedia"),
        ("amazon.de", 0xFF9900, "Amazon"), ("amazon.com", 0xFF9900, "Amazon"), ("amzn.to", 0xFF9900, "Amazon"), ("amzn.eu", 0xFF9900, "Amazon"),
        ("ebay.de", 0xE53238, "eBay"), ("ebay.com", 0xE53238, "eBay"),
        ("paypal.com", 0x003087, "PayPal"), ("paypal.me", 0x003087, "PayPal"),
        ("airbnb.com", 0xFF5A5F, "Airbnb"), ("airbnb.de", 0xFF5A5F, "Airbnb"),
        ("booking.com", 0x003580, "Booking.com"),
        ("discord.com", 0x5865F2, "Discord"), ("discord.gg", 0x5865F2, "Discord"),
        ("telegram.org", 0x26A5E4, "Telegram"), ("t.me", 0x26A5E4, "Telegram"),
        ("slack.com", 0x4A154B, "Slack"),
        ("notion.so", 0x3A3A3C, "Notion"), ("notion.site", 0x3A3A3C, "Notion"),
        ("figma.com", 0xF24E1E, "Figma"),
        ("dropbox.com", 0x0061FF, "Dropbox"),
        ("medium.com", 0x3A3A3C, "Medium"),
        ("chatgpt.com", 0x10A37F, "ChatGPT"), ("openai.com", 0x10A37F, "OpenAI"),
        ("claude.ai", 0xD97757, "Claude"), ("anthropic.com", 0xD97757, "Anthropic"),
    ]

    public static func color(_ url: String) -> UInt32? {
        brand(url)?.color
    }

    public static func name(_ url: String) -> String? {
        brand(url)?.name
    }

    private static func brand(_ url: String) -> (domain: String, color: UInt32, name: String)? {
        guard let host = host(url) else { return nil }
        return brands.first { host == $0.domain || host.hasSuffix("." + $0.domain) }
    }

    public static func host(_ url: String) -> String? {
        let trimmed = url.trimmingCharacters(in: .whitespaces)
        let withScheme = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let host = URLComponents(string: withScheme)?.host?.lowercased(), !host.isEmpty else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private static let meta = Pattern("<meta[^>]+name\\s*=\\s*[\"']theme-color[\"'][^>]*>", ignoreCase: true)
    private static let metaReversed = Pattern("<meta[^>]+content\\s*=\\s*[\"']([^\"']*)[\"'][^>]+name\\s*=\\s*[\"']theme-color[\"'][^>]*>", ignoreCase: true)
    private static let content = Pattern("content\\s*=\\s*[\"']([^\"']*)[\"']", ignoreCase: true)
    private static let media = Pattern("media\\s*=\\s*[\"'][^\"']*dark[^\"']*[\"']", ignoreCase: true)

    public static func themeColor(_ html: String) -> UInt32? {
        var values: [String] = []
        for m in meta.all(in: html) where media.first(in: m.value) == nil {
            if let c = content.first(in: m.value) { values.append(c.group(1)) }
        }
        if values.isEmpty, let m = metaReversed.first(in: html) { values.append(m.group(1)) }
        for value in values {
            if let color = parseHex(value), isUsable(color) { return color }
        }
        return nil
    }

    public static func parseHex(_ value: String) -> UInt32? {
        var hex = value.trimmingCharacters(in: .whitespaces).lowercased()
        guard hex.hasPrefix("#") else { return nil }
        hex.removeFirst()
        if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
        guard hex.count == 6, let number = UInt32(hex, radix: 16) else { return nil }
        return number
    }

    public static func isUsable(_ color: UInt32) -> Bool {
        let r = Double((color >> 16) & 0xFF) / 255, g = Double((color >> 8) & 0xFF) / 255, b = Double(color & 0xFF) / 255
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance > 0.06 && luminance < 0.85
    }
}
