// Zusammenhang: App/StoreLinks.swift, Net/TitleFetcher.swift, App/AppModel.swift (updateAvailable), ParalistCore Links/StoreVersion.swift
import Foundation
import ParalistCore

enum UpdateChecker {
    static var installedVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    @MainActor
    static func run(_ model: AppModel) async {
        guard StoreLinks.showUpdateButton, StoreLinks.hasAppId else { return }
        guard let json = await TitleFetcher.shared.json(StoreLinks.lookup), let store = StoreVersion.fromLookup(json) else { return }
        model.updateAvailable = StoreVersion.isNewer(store, than: installedVersion)
    }
}
