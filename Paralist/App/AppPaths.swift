// Zusammenhang: App/AppModel.swift, App/AppPrefs.swift, ParalistCore Library/PinLimit.swift, ParalistCore Store/StorageMove.swift, ParalistShare/ShareViewController.swift, Paralist.entitlements, tools/deploy_ipad.sh, ParalistWidgets/EntryProvider.swift
import Foundation
import ParalistCore

enum AppPaths {
    static let appGroup = "group.app.paralist.ipad"

    static var isDemo: Bool { ProcessInfo.processInfo.arguments.contains("-demo") }

    private static let localBase = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    private static let groupBase = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)

    static var root: URL {
        if isDemo {
            return FileManager.default.temporaryDirectory.appendingPathComponent("paralist-demo", isDirectory: true)
        }
        let local = localBase.appendingPathComponent("paralist", isDirectory: true)
        guard let groupBase else { return local }
        let shared = groupBase.appendingPathComponent("paralist", isDirectory: true)
        StorageMove.moveIfNeeded(from: local, to: shared)
        return shared
    }

    static var defaults: UserDefaults {
        if isDemo { return UserDefaults(suiteName: "paralist.demo") ?? .standard }
        guard let shared = UserDefaults(suiteName: appGroup) else { return .standard }
        adoptLocalDefaults(into: shared)
        return shared
    }

    private static func adoptLocalDefaults(into shared: UserDefaults) {
        guard groupBase != nil, shared.object(forKey: "joined_epoch_day") == nil else { return }
        let file = localBase.deletingLastPathComponent().appendingPathComponent("Preferences/\(appGroup).plist")
        guard let data = try? Data(contentsOf: file),
              let old = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any] else { return }
        for (key, value) in old { shared.set(value, forKey: key) }
    }

    static var pinLimit: Int {
        let d = defaults
        return d.object(forKey: "pin_limit") == nil ? PinLimit.standard : PinLimit.clamp(d.integer(forKey: "pin_limit"))
    }

    static var avatarFile: URL { root.appendingPathComponent("avatar.jpg") }
}
