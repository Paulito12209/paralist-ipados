// Zusammenhang: Composer/CreatePanel.swift, Capture/CaptureFlow.swift, Capture/CameraPicker.swift, Shell/Router.swift
import Foundation

enum CaptureKind: String, CaseIterable, Identifiable {
    case photo, video, audio, files

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .photo: return AppIcons.camera
        case .video: return AppIcons.recordVideo
        case .audio: return AppIcons.mic
        case .files: return AppIcons.attach
        }
    }

    var label: String {
        switch self {
        case .photo: return "create_photo"
        case .video: return "create_video"
        case .audio: return "create_audio"
        case .files: return "list_files"
        }
    }
}
