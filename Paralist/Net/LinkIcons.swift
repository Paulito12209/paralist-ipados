// Zusammenhang: ParalistCore Links/LinkIcon.swift, ParalistCore Links/LinkLogoLibrary.swift, Resources/Assets.xcassets/LinkLogos, Net/TitleFetcher.swift, Net/LinkColors.swift, Entry/EntryHero.swift, Entry/EntryCover.swift
import Foundation
import ParalistCore
import UIKit

enum LinkLogo: Equatable {
    case bundled(String)
    case fetched(UIImage)
}

actor LinkIcons {
    static let shared = LinkIcons()
    private static let missingKey = "linkIconsMissing"
    private static let maxSide: CGFloat = 512
    private let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("linkicons", isDirectory: true)
    private var missing = Set(UserDefaults.standard.stringArray(forKey: missingKey) ?? [])
    private var loaded: [String: UIImage] = [:]
    private var running: Set<String> = []

    func icon(_ url: String) async -> LinkLogo? {
        if let name = LinkLogoLibrary.assetNames(url).first(where: { UIImage(named: $0) != nil }) { return .bundled(name) }
        guard let host = LinkBrand.host(url) else { return nil }
        if let image = loaded[host] { return .fetched(image) }
        let file = folder.appendingPathComponent(Self.fileName(host))
        if let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            loaded[host] = image
            return .fetched(image)
        }
        guard !missing.contains(host), !running.contains(host) else { return nil }
        running.insert(host)
        defer { running.remove(host) }
        guard let image = await download(url) else {
            missing.insert(host)
            UserDefaults.standard.set(Array(missing), forKey: Self.missingKey)
            return nil
        }
        loaded[host] = image
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? image.pngData()?.write(to: file, options: .atomic)
        return .fetched(image)
    }

    private func download(_ url: String) async -> UIImage? {
        let html = await TitleFetcher.shared.html(url)
        var candidates: [String] = []
        if let html, let found = LinkIcon.iconUrl(html: html, page: url) { candidates.append(found) }
        if let fallback = LinkIcon.fallbackUrl(page: url), !candidates.contains(fallback) { candidates.append(fallback) }
        for candidate in candidates {
            if let data = await TitleFetcher.shared.image(candidate), let image = UIImage(data: data), image.size.width >= 16 {
                return Self.shrink(image)
            }
        }
        return nil
    }

    private static func shrink(_ image: UIImage) -> UIImage {
        let side = max(image.size.width, image.size.height) * image.scale
        guard side > maxSide else { return image }
        let factor = maxSide / side
        let size = CGSize(width: image.size.width * image.scale * factor, height: image.size.height * image.scale * factor)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }

    private static func fileName(_ host: String) -> String {
        String(host.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) || $0 == "." || $0 == "-" ? Character($0) : "_" }) + ".png"
    }
}
