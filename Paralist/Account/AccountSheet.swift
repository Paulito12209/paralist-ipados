// Zusammenhang: Account/AvatarStore.swift, Account/AvatarCropSheet.swift, Components/LevelRing.swift (AvatarDisc), ParalistCore Account/Account.swift
import ParalistCore
import PhotosUI
import SwiftUI

struct AccountSheet: View {
    @Environment(AppModel.self) private var model
    @State private var naming = false
    @State private var name = ""
    @State private var item: PhotosPickerItem?
    @State private var crop: UIImage?

    var body: some View {
        let prefs = model.prefs
        let progress = SetupProgress.forProfile(hasName: !prefs.profileName.isEmpty)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Button { name = prefs.profileName; naming = true } label: {
                        HStack(spacing: 16) {
                            AvatarDisc(name: prefs.profileName, stamp: prefs.avatarStamp, iconSize: 28, initialSize: 22).frame(width: 56, height: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(prefs.profileName.isEmpty ? L.s("account_name_placeholder") : prefs.profileName)
                                    .font(Typo.titleMedium).foregroundStyle(prefs.profileName.isEmpty ? Palette.muted : Palette.onSurface)
                                Label(L.s("account_local_only"), systemImage: AppIcons.phone).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                            }
                            Spacer()
                            Image(systemName: AppIcons.chevronRight).foregroundStyle(Palette.outline)
                        }
                        .padding(16)
                        .background(Palette.surfaceContainer, in: RoundedRectangle(cornerRadius: Dimens.cardRadius))
                    }
                    .buttonStyle(.plain)
                    HStack {
                        PhotosPicker(selection: $item, matching: .images) { Label(L.s("account_photo_pick"), systemImage: AppIcons.image) }
                        if prefs.avatarStamp > 0 {
                            Button(role: .destructive) {
                                AvatarStore.remove()
                                prefs.avatarStamp = 0
                            } label: { Label(L.s("account_photo_remove"), systemImage: AppIcons.delete) }
                        }
                    }
                    .font(Typo.labelLarge)
                    .padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L.s("account_setup")).font(Typo.titleSmall)
                        ProgressView(value: progress.fraction).tint(Palette.primary)
                        Text(progress.isComplete ? L.s("account_setup_done") : L.f("account_setup_progress", progress.clampedDone, progress.total))
                            .font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                        HStack {
                            Spacer()
                            Button { name = prefs.profileName; naming = true } label: {
                                Label(L.s("account_setup_continue"), systemImage: AppIcons.chevronRight).labelStyle(.titleAndIcon)
                            }
                        }
                    }
                    .padding(16)
                    .background(Palette.surfaceContainer, in: RoundedRectangle(cornerRadius: Dimens.cardRadius))
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle(L.s("account_title"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(L.s("account_edit_name"), isPresented: $naming) {
                TextField(L.s("account_name_placeholder"), text: $name).textInputAutocapitalization(.words)
                Button(L.s("dialog_save")) { prefs.setName(name) }
                Button(L.s("dialog_cancel"), role: .cancel) {}
            }
            .onChange(of: item) { _, picked in
                guard let picked else { return }
                Task {
                    if let data = try? await picked.loadTransferable(type: Data.self), let image = UIImage(data: data) { crop = image }
                    item = nil
                }
            }
            .sheet(item: Binding(get: { crop.map(CropImage.init) }, set: { crop = $0?.image })) { wrapped in
                AvatarCropSheet(image: wrapped.image) { prefs.avatarStamp = Date().timeIntervalSince1970 }
            }
        }
    }
}

struct CropImage: Identifiable {
    let image: UIImage
    var id: ObjectIdentifier { ObjectIdentifier(image) }
}
