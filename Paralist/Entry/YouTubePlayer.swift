// Zusammenhang: Entry/EntryHero.swift, Entry/CoverStage.swift, ParalistShare/ShareView.swift, ParalistCore Links/VideoLinks.swift
import ParalistCore
import SwiftUI
import WebKit

struct YouTubePlayer: UIViewRepresentable {
    let videoId: String
    var command = 0
    var onPlaying: (Bool) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
        config.websiteDataStore = .nonPersistent()
        config.userContentController.add(WeakHandler(context.coordinator), name: "yt")
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .black
        view.scrollView.isScrollEnabled = false
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.scrollView.backgroundColor = .black
        load(view)
        context.coordinator.command = command
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.loaded != videoId { load(view) }
        coordinator.loaded = videoId
        coordinator.onPlaying = onPlaying
        if coordinator.command != command {
            coordinator.command = command
            view.evaluateJavaScript("toggle(\(!coordinator.playing))")
        }
    }

    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        view.configuration.userContentController.removeScriptMessageHandler(forName: "yt")
        view.stopLoading()
        view.loadHTMLString("", baseURL: nil)
    }

    private func load(_ view: WKWebView) {
        let src = VideoLinks.embedUrl(videoId)
        let html = """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
        <style>html,body{margin:0;height:100%;background:#000}iframe{position:fixed;inset:0;width:100%;height:100%;border:0}</style></head>
        <body><iframe src="\(src)" referrerpolicy="strict-origin-when-cross-origin" allow="encrypted-media; picture-in-picture; web-share" allowfullscreen></iframe>
        <script>
        var f=document.querySelector('iframe');
        function send(o){f.contentWindow.postMessage(JSON.stringify(o),'*');}
        f.addEventListener('load',function(){send({event:'listening',id:1,channel:'widget'});});
        window.addEventListener('message',function(e){try{var d=JSON.parse(e.data);var s=d.event==='onStateChange'?d.info:(d.info&&d.info.playerState);if(typeof s==='number')webkit.messageHandlers.yt.postMessage(s);}catch(x){}});
        function toggle(play){send({event:'command',func:play?'playVideo':'pauseVideo',args:[]});}
        </script></body></html>
        """
        view.loadHTMLString(html, baseURL: URL(string: VideoLinks.pageOrigin))
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var loaded: String?
        var command = 0
        var playing = false
        var onPlaying: (Bool) -> Void = { _ in }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let state = message.body as? Int, state != -1, state != 3 else { return }
            let now = state == 1
            guard now != playing else { return }
            playing = now
            onPlaying(now)
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = action.request.url else { return .cancel }
            if url.absoluteString == "about:blank" || url.absoluteString == VideoLinks.pageOrigin { return .allow }
            if VideoLinks.isPlayerHost(url.host) {
                if action.targetFrame?.isMainFrame == false { return .allow }
                return action.navigationType == .linkActivated ? .cancel : .allow
            }
            return .cancel
        }
    }
}

final class WeakHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?

    init(_ target: WKScriptMessageHandler) { self.target = target }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}
