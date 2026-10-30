// Zusammenhang: Pages/MenuPage.swift, Account/AvatarStore.swift, Components/LevelRing.swift (AvatarDisc), Theme/Dimens.swift (MenuDimens), Theme/Palette.swift (rib*)
import ParalistCore
import SwiftUI
import UIKit

struct MenuHead: View {
    let topInset: CGFloat
    let lead: CGFloat
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        let image = model.prefs.avatarStamp > 0 ? AvatarStore.load(stamp: model.prefs.avatarStamp) : nil
        let onImage = image != nil
        let text = onImage ? Color.white : Palette.onSurface
        VStack(spacing: 0) {
            Text(L.s("app_name")).font(Typo.dm(20, .semibold)).tracking(1.6).frame(height: 56)
            avatar.padding(.top, 22)
            Text(model.prefs.profileName.isEmpty ? L.s("account_name_placeholder") : model.prefs.profileName)
                .font(Typo.dm(26, .semibold))
                .foregroundStyle(model.prefs.profileName.isEmpty && !onImage ? Palette.muted : text)
                .padding(.top, 12)
            Text(L.f("menu_since", L.date(model.prefs.joinedDay, .long)))
                .font(Typo.dm(13)).foregroundStyle(text.opacity(0.85))
                .padding(.top, 2)
        }
        .foregroundStyle(text)
        .shadow(color: .black.opacity(onImage ? MenuDimens.textShadow : 0), radius: 4, y: 1)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, topInset)
        .padding(.horizontal, 12)
        .padding(.leading, lead)
        .padding(.bottom, 20 + Dimens.sheetRadius)
        .background {
            if let image { RibbedBackdrop(image: image) } else { Palette.surfaceHigh }
        }
    }

    private var avatar: some View {
        Button { router.accountOpen = true } label: {
            AvatarDisc(name: model.prefs.profileName, stamp: model.prefs.avatarStamp, iconSize: 44, initialSize: 40)
                .frame(width: 104, height: 104)
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 3))
                .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: AppIcons.edit).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.onPrimary)
                        .frame(width: 30, height: 30).background(Palette.primary, in: Circle())
                        .overlay(Circle().stroke(Palette.surfaceHigh, lineWidth: 3)).padding(2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L.s("account_edit_name"))
    }
}

struct RibbedBackdrop: View {
    let image: UIImage

    var body: some View {
        GeometryReader { geo in
            Image(uiImage: image).resizable().scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .scaleEffect(MenuDimens.ribZoom, anchor: .top)
                .blur(radius: MenuDimens.ribBlur)
                .clipped()
        }
        .overlay {
            Canvas { ctx, size in
                var x: CGFloat = 0
                while x < size.width {
                    ctx.fill(Path(CGRect(x: x, y: 0, width: MenuDimens.ribPeriod, height: size.height)),
                             with: .linearGradient(Gradient(stops: Palette.ribStops), startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x + MenuDimens.ribPeriod, y: 0)))
                    x += MenuDimens.ribPeriod
                }
            }
        }
        .overlay { LinearGradient(stops: Palette.ribShade, startPoint: .top, endPoint: .bottom) }
        .accessibilityHidden(true)
    }
}
