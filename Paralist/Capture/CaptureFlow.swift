// Zusammenhang: Shell/CreateOverlay.swift, Shell/Router.swift, Capture/CameraPicker.swift, Capture/AudioRecorderSheet.swift, Files/AttachmentImporter.swift, Entry/EntryBlocks.swift (saveCreated)
import AVFoundation
import ParalistCore
import UIKit

@MainActor
enum CaptureFlow {
    static func start(_ kind: CaptureKind, router: Router, model: AppModel) {
        switch kind {
        case .photo, .video:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return model.say(L.s("capture_camera_unavailable")) }
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            guard status != .denied && status != .restricted else { return model.say(L.s("capture_camera_denied")) }
            router.closeCreate()
            router.camera = kind
        case .files:
            router.closeCreate()
            router.importing = true
        case .audio:
            guard AVAudioApplication.shared.recordPermission != .denied else { return model.say(L.s("capture_mic_denied")) }
            router.closeCreate()
            router.recording = true
        }
    }

    static func save(_ result: Result<Attachment, ImportFailure>, kind: CaptureKind, link: String?, model: AppModel) {
        switch result {
        case .success(let attachment):
            var draft = ComposerDraft(type: .file)
            draft.attachment = attachment
            if let partner = link.flatMap(model.entry) { draft.linkTo(partner) } else { draft.link = link }
            draft.title = kind == .files ? (attachment.name as NSString).deletingPathExtension : "\(L.s(kind.label)) \(L.dateTime(Date()))"
            guard let entry = draft.build(model.newEntry(.file), zone: .current), model.saveCreated(entry) != nil else {
                return model.say(L.s("save_failed"))
            }
            model.say(L.s("capture_saved"))
        case .failure(let failure):
            model.say(failure.message)
        }
    }
}
