// Zusammenhang: Pages/OverviewPage.swift, Pages/OverviewParts.swift (FillZone, EmptyInfoButton), Pages/ListPage.swift, Pages/MediaPage.swift, Pages/TasksPage.swift, Chat/ChatListPage.swift, Chat/ChatThreadPage.swift, Entries/ListAdd.swift, App/AppPrefs.swift (emptyInfoHidden), Theme/Dimens.swift (EmptyDimens)
import SwiftUI

struct EmptyHint: View {
    let icon: String
    let info: String
    var action: (() -> Void)?

    var body: some View {
        GlyphIcon(icon, size: EmptyDimens.glyph)
            .foregroundStyle(Palette.onSecondaryContainer)
            .frame(width: EmptyDimens.emblem, height: EmptyDimens.emblem)
            .background(Palette.secondaryContainer, in: Circle())
            .grayscale(1)
            .opacity(EmptyDimens.fade)
            .accessibilityHidden(true)
            .overlay(alignment: .bottomTrailing) {
                EmptyInfoButton(info: info)
                    .padding(.trailing, -EmptyDimens.infoShift)
                    .padding(.bottom, -EmptyDimens.infoShift)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { action?() }
    }
}

struct EmptyInfoButton: View {
    let info: String
    @Environment(AppModel.self) private var model
    @State private var showsInfo = false

    var body: some View {
        if !model.prefs.emptyInfoHidden {
            Button { showsInfo = true } label: {
                Image(systemName: AppIcons.info)
                    .font(.system(size: EmptyDimens.infoGlyph, weight: .semibold))
                    .foregroundStyle(Palette.onSurface)
                    .frame(width: EmptyDimens.info, height: EmptyDimens.info)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(L.s("empty_info"))
            .alert(L.s("empty_info"), isPresented: $showsInfo) {
                Button(L.s("empty_info_ok"), role: .cancel) {}
                Button(L.s("empty_info_never")) { model.prefs.emptyInfoHidden = true }
            } message: {
                Text(info)
            }
        }
    }
}

struct EmptyState: View {
    let text: String
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            EmptyIllustration().frame(width: 168, height: 128)
            Text(text).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .onTapGesture { action?() }
    }
}

struct EmptyIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let cw = w * 0.62, ch = h * 0.68
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20).fill(Palette.surfaceHigh)
                    .frame(width: cw, height: ch).rotationEffect(.degrees(8)).offset(x: w * 0.27, y: h * 0.06)
                RoundedRectangle(cornerRadius: 20).fill(Palette.surfaceContainer)
                    .frame(width: cw, height: ch).offset(x: w * 0.12, y: h * 0.22)
                ForEach(Array([0.62, 0.46, 0.54].enumerated()), id: \.offset) { item in
                    Capsule().fill(Palette.outlineVariant)
                        .frame(width: cw * item.element, height: 6)
                        .offset(x: w * 0.12 + 18, y: h * 0.22 + 22 + CGFloat(item.offset) * 16)
                }
                Circle().fill(Palette.primary).frame(width: 20, height: 20)
                    .offset(x: w * 0.12 + cw - 6 - 10, y: h * 0.22 + ch - 8 - 10)
            }
        }
        .accessibilityHidden(true)
    }
}
