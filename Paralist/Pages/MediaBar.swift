// Zusammenhang: Shell/AppTabBar.swift (Werkzeuge über der Leiste), Pages/MediaPage.swift, Capture/CaptureFlow.swift, Capture/CaptureKind.swift, Shell/SectionChrome.swift (Glas-Knöpfe), Shell/PageBar.swift (MediaAddMenu als Plus)
import SwiftUI

struct MediaBar: View {
    @Binding var importing: Bool
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        HStack(spacing: 12) {
            button(AppIcons.attach, label: "list_files") { importing = true }
                .glassEffect(.regular.interactive(), in: Circle())
            HStack(spacing: 0) {
                button(CaptureKind.video.icon, label: CaptureKind.video.label) { CaptureFlow.start(.video, router: router, model: model) }
                button(CaptureKind.photo.icon, label: CaptureKind.photo.label) { CaptureFlow.start(.photo, router: router, model: model) }
            }
            .glassEffect(.regular.interactive(), in: Capsule())
            button(CaptureKind.audio.icon, label: CaptureKind.audio.label) { CaptureFlow.start(.audio, router: router, model: model) }
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .frame(maxWidth: .infinity)
    }

    private func button(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 20, weight: .regular)).foregroundStyle(Palette.onSurface)
                .frame(width: MediaDimens.barButton, height: MediaDimens.barButton)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L.s(label))
    }
}

struct MediaAddMenu: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        Menu {
            ForEach([CaptureKind.photo, .video, .audio], id: \.self) { kind in
                Button { CaptureFlow.start(kind, router: router, model: model) } label: { Label(L.s(kind.label), systemImage: kind.icon) }
            }
            Button { router.mediaImport = true } label: { Label(L.s("list_files"), systemImage: AppIcons.attach) }
        } label: {
            PageBarGlyph(asset: "XoolPlus", tint: Palette.level)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(L.s("nav_create"))
    }
}
