// Zusammenhang: Net/UpdateChecker.swift, Pages/MenuPage.swift (Update-Knopf), App/ParalistApp.swift, ParalistCore Links/StoreVersion.swift, tools/asc_api.sh (liest appId)
import Foundation

enum StoreLinks {
    static let showUpdateButton = false
    static let appId = "6828980471"
    static let hasAppId = !appId.isEmpty
    static let page = URL(string: "https://apps.apple.com/app/id\(appId)") ?? URL(string: "https://apps.apple.com")!
    static let lookup = "https://itunes.apple.com/lookup?id=\(appId)"
}
