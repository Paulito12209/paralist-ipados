// Zusammenhang: Icons/AppIcons.swift, Entries/TypeLook.swift, ParalistShare/ShareView.swift, ParalistWidgets/EntryWidgetView.swift, Resources/Assets.xcassets (XoolRocket)
import SwiftUI

struct GlyphIcon: View {
    let name: String
    let size: CGFloat
    var weight: Font.Weight = .regular

    init(_ name: String, size: CGFloat, weight: Font.Weight = .regular) {
        self.name = name
        self.size = size
        self.weight = weight
    }

    var body: some View {
        if let asset = AppIcons.assetName(name) {
            Image(asset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size * 1.1, height: size * 1.1)
        } else {
            Image(systemName: name).font(.system(size: size, weight: weight))
        }
    }
}
