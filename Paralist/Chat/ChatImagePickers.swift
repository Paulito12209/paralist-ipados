// Zusammenhang: Chat/ChatInputBar.swift, Chat/ChatImageParts.swift, Capture/CameraPicker.swift (gleiche Kamera für Einträge), Files/AttachmentImporter.swift
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import VisionKit

enum ChatCapture: String, Identifiable {
    case camera, scan
    var id: String { rawValue }

    @MainActor
    var available: Bool {
        switch self {
        case .camera: return UIImagePickerController.isSourceTypeAvailable(.camera)
        case .scan: return VNDocumentCameraViewController.isSupported
        }
    }
}

struct ChatCameraPicker: UIViewControllerRepresentable {
    let finish: (Data?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier]
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(finish) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let finish: (Data?) -> Void

        init(_ finish: @escaping (Data?) -> Void) { self.finish = finish }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { finish(nil) }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            finish((info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.9))
        }
    }
}

struct ChatDocumentScanner: UIViewControllerRepresentable {
    let finish: (Data?) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(finish) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let finish: (Data?) -> Void

        init(_ finish: @escaping (Data?) -> Void) { self.finish = finish }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) { finish(nil) }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) { finish(nil) }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            finish(scan.pageCount > 0 ? scan.imageOfPage(at: 0).jpegData(compressionQuality: 0.9) : nil)
        }
    }
}
