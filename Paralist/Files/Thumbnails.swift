// Zusammenhang: Pages/MediaCell.swift, Entry/EntryHero.swift, ParalistShare/ShareFileViews.swift
import AVFoundation
import ImageIO
import UIKit

enum Thumbnails {
    @MainActor private static let cache = NSCache<NSString, UIImage>()

    @MainActor
    static func image(_ url: URL, side: CGFloat) -> UIImage? {
        let key = "\(url.path)@\(Int(side))" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: side,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cg)
        cache.setObject(image, forKey: key)
        return image
    }

    @MainActor
    static func videoFrame(_ url: URL, side: CGFloat) async -> UIImage? {
        let key = "\(url.path)@\(Int(side))v" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: side, height: side)
        guard let result = try? await generator.image(at: .zero) else { return nil }
        let image = UIImage(cgImage: result.image)
        cache.setObject(image, forKey: key)
        return image
    }
}
