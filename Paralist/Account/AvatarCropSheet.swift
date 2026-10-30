// Zusammenhang: ParalistCore Account/Account.swift (AvatarFrame), Account/AvatarStore.swift, Account/AccountSheet.swift
import ParalistCore
import SwiftUI

struct AvatarCropSheet: View {
    let image: UIImage
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var frame: AvatarFrame?
    @State private var lastZoom: CGFloat = 1
    @State private var lastPan: CGSize = .zero
    private let viewport: CGFloat = 300

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(L.s("avatar_crop_hint")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                ZStack {
                    if let frame {
                        Image(uiImage: image).resizable()
                            .frame(width: frame.displayWidth, height: frame.displayHeight)
                            .offset(x: frame.offsetX, y: frame.offsetY)
                    }
                    Rectangle().fill(Color.black.opacity(0.55))
                        .mask { Rectangle().overlay(Circle().blendMode(.destinationOut)).compositingGroup() }
                    Circle().stroke(Palette.surface, lineWidth: 2).padding(1)
                }
                .frame(width: viewport, height: viewport)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(maxWidth: .infinity)
                .gesture(SimultaneousGesture(
                    MagnifyGesture().onChanged { value in
                        frame?.transform(zoomFactor: value.magnification / lastZoom, panX: 0, panY: 0)
                        lastZoom = value.magnification
                    }.onEnded { _ in lastZoom = 1 },
                    DragGesture().onChanged { value in
                        frame?.transform(zoomFactor: 1, panX: value.translation.width - lastPan.width, panY: value.translation.height - lastPan.height)
                        lastPan = value.translation
                    }.onEnded { _ in lastPan = .zero }
                ))
                VStack(alignment: .leading, spacing: 12) {
                    Text(L.s("avatar_zoom")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                    Slider(value: Binding(get: { frame?.zoom ?? AvatarFrame.minZoom }, set: { frame?.setZoom($0) }),
                           in: AvatarFrame.minZoom...AvatarFrame.maxZoom)
                    Text(L.s("avatar_focus_x")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                    Slider(value: Binding(get: { frame?.focusX ?? 0.5 }, set: { frame?.setFocus(x: $0, y: frame?.focusY ?? 0.5) }), in: 0...1)
                    Text(L.s("avatar_focus_y")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                    Slider(value: Binding(get: { frame?.focusY ?? 0.5 }, set: { frame?.setFocus(x: frame?.focusX ?? 0.5, y: $0) }), in: 0...1)
                }
                .tint(Palette.primary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle(L.s("avatar_crop_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L.s("dialog_cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.s("action_apply")) {
                        if let frame, AvatarStore.save(normalized, frame: frame) { onSaved() }
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(frame == nil)
                }
            }
        }
        .onAppear { frame = AvatarFrame(imageWidth: normalized.size.width, imageHeight: normalized.size.height, viewport: viewport) }
    }

    private var normalized: UIImage {
        if image.imageOrientation == .up { return image }
        return UIGraphicsImageRenderer(size: image.size).image { _ in image.draw(at: .zero) }
    }
}
