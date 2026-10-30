// Zusammenhang: ParalistCore Links/LinkBrand.swift, Net/TitleFetcher.swift, Entry/EntryHero.swift
import Foundation
import ParalistCore

actor LinkColors {
    static let shared = LinkColors()
    private static let key = "linkThemeColors"
    private var known: [String: Int] = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] ?? [:]
    private var running: Set<String> = []

    func color(_ url: String) async -> UInt32? {
        if let brand = LinkBrand.color(url) { return brand }
        guard let host = LinkBrand.host(url) else { return nil }
        if let stored = known[host] { return stored < 0 ? nil : UInt32(stored) }
        guard !running.contains(host) else { return nil }
        running.insert(host)
        defer { running.remove(host) }
        let found = await TitleFetcher.shared.html(url).flatMap(LinkBrand.themeColor)
        known[host] = found.map { Int($0) } ?? -1
        UserDefaults.standard.set(known, forKey: Self.key)
        return found
    }
}
