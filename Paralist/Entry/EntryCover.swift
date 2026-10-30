// Zusammenhang: Entry/CoverStage.swift, Entry/EntryCanvasPanel.swift (CoverTitleVeil, CanvasSheet), Net/LinkIcons.swift, Entries/TypeLook.swift, Icons/GlyphIcon.swift, Theme/Palette.swift (cover*), Theme/Dimens.swift (cover*)
import SwiftUI

struct CoverTitleVeil: View {
    var body: some View {
        let shade = LinearGradient(
            stops: [
                .init(color: Palette.surface.opacity(0), location: 0),
                .init(color: Palette.surface.opacity(0.08), location: 0.25),
                .init(color: Palette.surface.opacity(0.35), location: 0.5),
                .init(color: Palette.surface.opacity(0.7), location: 0.75),
                .init(color: Palette.surface.opacity(0.9), location: 1),
            ],
            startPoint: .top, endPoint: .bottom
        )
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
                .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .white.opacity(0.4), location: 0.6), .init(color: .white, location: 1)], startPoint: .top, endPoint: .bottom))
            shade
        }
        .padding(.top, -Dimens.entryTitleVeilLead)
        .accessibilityHidden(true)
    }
}

struct CanvasSheet: View {
    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: Dimens.entrySheetRadius, topTrailingRadius: Dimens.entrySheetRadius, style: .continuous)
        shape.fill(Palette.surfaceContainer)
            .background(alignment: .top) { Palette.surface.opacity(0.9).frame(height: Dimens.entrySheetRadius) }
            .overlay(shape.strokeBorder(Palette.cardStroke.opacity(0.6), lineWidth: Dimens.canvasCardStroke))
            .padding(.bottom, -Dimens.canvasRunout)
            .overlay(alignment: .top) {
                Capsule().fill(Palette.entryGrabber)
                    .frame(width: Dimens.entryGrabberWidth, height: Dimens.entryGrabberHeight)
                    .padding(.top, Dimens.entryGrabberTop)
            }
            .accessibilityHidden(true)
    }
}

struct CoverEmblem: View {
    let look: TypeLook

    var body: some View {
        GlyphIcon(look.icon.filled, size: Dimens.coverEmblem, weight: .medium)
            .foregroundStyle(look.color)
            .shadow(color: .black.opacity(0.18), radius: 10, y: 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }
}

struct CoverLogo: View {
    let logo: LinkLogo

    var body: some View {
        RoundedRectangle(cornerRadius: Dimens.coverLogoCorner, style: .continuous)
            .fill(.white)
            .frame(width: Dimens.coverLogo, height: Dimens.coverLogo)
            .overlay {
                picture
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: sharp ? Dimens.coverLogo : Dimens.coverLogoSmall, height: sharp ? Dimens.coverLogo : Dimens.coverLogoSmall)
            }
            .clipShape(RoundedRectangle(cornerRadius: Dimens.coverLogoCorner, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 12, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }

    private var picture: Image {
        switch logo {
        case .bundled(let name): return Image(name)
        case .fetched(let image): return Image(uiImage: image)
        }
    }

    private var sharp: Bool {
        guard case .fetched(let image) = logo else { return true }
        return image.size.width * image.scale >= Dimens.coverLogoSharp
    }
}

struct CoverRatioHint: View {
    @Environment(AppModel.self) private var model
    @State private var asking = false

    var body: some View {
        Button {
            model.prefs.coverHintSeen = true
            asking = true
        } label: {
            Image(systemName: AppIcons.info)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.onSurface)
                .frame(width: Dimens.coverHintCircle, height: Dimens.coverHintCircle)
                .overlay(alignment: .topTrailing) {
                    if !model.prefs.coverHintSeen {
                        Circle().fill(Palette.menuDot).frame(width: Dimens.coverHintDot, height: Dimens.coverHintDot).offset(x: -4, y: 4)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .padding((Dimens.coverHintBox - Dimens.coverHintCircle) / 2)
        .accessibilityLabel(L.s("cover_ratio_info"))
        .confirmationDialog(L.s("cover_ratio_title"), isPresented: $asking, titleVisibility: .visible) {
            Button(L.s("cover_fill_gradient")) { model.prefs.blackMediaBackdrop = false }
            Button(L.s("cover_fill_black")) { model.prefs.blackMediaBackdrop = true }
        } message: {
            Text(L.s("cover_ratio_message"))
        }
    }
}
