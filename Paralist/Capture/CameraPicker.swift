// Zusammenhang: Shell/AppSheets.swift, Shell/Router.swift, Capture/CaptureFlow.swift, Files/AttachmentImporter.swift, Capture/VideoShrinker.swift
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CameraPicker: UIViewControllerRepresentable {
    let kind: CaptureKind
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        if kind == .video {
            picker.mediaTypes = [UTType.movie.identifier]
            picker.cameraCaptureMode = .video
            picker.videoQuality = .typeHigh
            picker.videoMaximumDuration = 120
        } else {
            picker.mediaTypes = [UTType.image.identifier]
            picker.cameraCaptureMode = .photo
        }
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in parent.router.camera = nil }
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let kind = parent.kind
            let video = info[.mediaURL] as? URL
            let photo = (info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.9)
            Task { @MainActor in
                let model = parent.model
                let store = model.library.store
                if kind == .video, let video {
                    let small = await VideoShrinker.shrink(video)
                    CaptureFlow.save(AttachmentImporter.importFile(at: small ?? video, into: store), kind: kind, link: parent.router.createLink, model: model)
                    try? FileManager.default.removeItem(at: video)
                    if let small { try? FileManager.default.removeItem(at: small) }
                } else if let photo {
                    CaptureFlow.save(AttachmentImporter.importData(photo, name: "foto.jpg", into: store), kind: kind, link: parent.router.createLink, model: model)
                }
                parent.router.camera = nil
            }
        }
    }
}
