// Zusammenhang: ParalistShare/ShareModel.swift, ParalistShare/ShareView.swift, ParalistShare/Info.plist
import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
    private let model = ShareModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        let model = model
        let host = UIHostingController(rootView: ShareView(model: model) { [weak self] in
            model.cleanUp()
            self?.extensionContext?.completeRequest(returningItems: nil)
        })
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
        Task { await model.load(extensionContext?.inputItems as? [NSExtensionItem] ?? []) }
    }
}
