// Zusammenhang: Components/LevelRing.swift, Account/AvatarCropSheet.swift, App/AppPaths.swift, ParalistCore Account/Account.swift
import ParalistCore
import UIKit

enum AvatarStore {
    @MainActor private static var cache: (Double, UIImage)?

    @MainActor
    static func load(stamp: Double) -> UIImage? {
        if let cache, cache.0 == stamp { return cache.1 }
        guard let image = UIImage(contentsOfFile: AppPaths.avatarFile.path) else { return nil }
        cache = (stamp, image)
        return image
    }

    static func save(_ source: UIImage, frame: AvatarFrame) -> Bool {
        let side = frame.sourceSide()
        let crop = CGRect(x: frame.sourceLeft(), y: frame.sourceTop(), width: side, height: side)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let output = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 640), format: format).image { _ in
            let scale = 640 / side
            source.draw(in: CGRect(x: -crop.minX * scale, y: -crop.minY * scale, width: source.size.width * scale, height: source.size.height * scale))
        }
        guard let data = output.jpegData(compressionQuality: 0.9) else { return false }
        return (try? data.write(to: AppPaths.avatarFile, options: .atomic)) != nil
    }

    static func remove() { try? FileManager.default.removeItem(at: AppPaths.avatarFile) }
}
