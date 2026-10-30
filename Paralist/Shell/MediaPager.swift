// Zusammenhang: Shell/DetailHost.swift, Shell/Router.swift (mediaQueue), Entry/EntryDestination.swift, Files/Thumbnails.swift, Pages/MediaPage.swift, ParalistCore Library/MediaPaging.swift, Library/CoverTransition.swift
import ParalistCore
import SwiftUI

struct MediaPager: View {
    let id: String
    let shift: CGFloat
    let width: CGFloat
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            if shift != 0, let neighbor = MediaPaging.neighbor(of: id, in: router.mediaQueue, step: shift < 0 ? 1 : -1) {
                MediaPreview(id: neighbor).offset(x: shift + (shift < 0 ? width : -width))
            }
            EntryDestination(id: id, cover: true).id(id).offset(x: shift)
        }
    }
}

struct MediaPreview: View {
    let id: String
    @Environment(AppModel.self) private var model
    @State private var frame: UIImage?

    var body: some View {
        GeometryReader { geo in
            if let image = picture ?? frame {
                let ratio = Double(image.size.width / max(image.size.height, 1))
                let place = CoverTransition.stageFrame(motif: isVideo ? .video(ratio: ratio) : .image(ratio: ratio),
                                                       width: geo.size.width, height: geo.size.height)
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: place.width, height: place.height)
                    .position(x: place.midX, y: place.midY)
            }
        }
        .background(Color.black)
        .clipped()
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .task(id: id) {
            guard isVideo, let url = model.entry(id).flatMap(model.attachmentURL) else { return }
            frame = await Thumbnails.videoFrame(url, side: 1600)
        }
    }

    private var isVideo: Bool {
        model.entry(id).flatMap { MediaKind.of($0) } == .video
    }

    private var picture: UIImage? {
        guard let entry = model.entry(id), MediaKind.of(entry) == .image, let url = model.attachmentURL(entry) else { return nil }
        return Thumbnails.image(url, side: 1600)
    }
}
