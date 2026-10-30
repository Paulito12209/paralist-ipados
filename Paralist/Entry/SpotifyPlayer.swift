// Zusammenhang: Entry/EntryHero.swift, Entry/CoverStage.swift, Entry/YouTubePlayer.swift (WeakHandler), ParalistCore Links/SpotifyLinks.swift, Links/VideoLinks.swift (pageOrigin)
import ParalistCore
import SwiftUI
import WebKit

struct SpotifyPlayer: UIViewRepresentable {
    let item: SpotifyItem
    let height: CGFloat
    var command = 0
    var onPlaying: (Bool) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(WeakHandler(context.coordinator), name: "sp")
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.isScrollEnabled = false
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.scrollView.backgroundColor = .clear
        load(view)
        context.coordinator.loaded = item
        context.coordinator.command = command
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.loaded != item {
            coordinator.loaded = item
            load(view)
        }
        coordinator.onPlaying = onPlaying
        if coordinator.command != command {
            coordinator.command = command
            view.evaluateJavaScript("toggle()")
        }
    }

    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        view.configuration.userContentController.removeScriptMessageHandler(forName: "sp")
        view.stopLoading()
        view.loadHTMLString("", baseURL: nil)
    }

    private func load(_ view: WKWebView) {
        let html = """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
        <style>html,body{margin:0;height:100%;background:transparent;overflow:hidden}</style></head>
        <body><div id="e"></div>
        <script>
        var ctl=null,playing=false;
        window.onSpotifyIframeApiReady=function(api){api.createController(document.getElementById('e'),{uri:'\(item.uri)',width:'100%',height:'\(Int(height))'},function(c){ctl=c;c.addListener('playback_update',function(e){var p=!e.data.isPaused;if(p!==playing){playing=p;webkit.messageHandlers.sp.postMessage(p);}});});};
        function toggle(){if(ctl)ctl.togglePlay();}
        </script>
        <script src="https://open.spotify.com/embed/iframe-api/v1" async></script>
        </body></html>
        """
        view.loadHTMLString(html, baseURL: URL(string: VideoLinks.pageOrigin))
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var loaded: SpotifyItem?
        var command = 0
        var onPlaying: (Bool) -> Void = { _ in }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            if let playing = message.body as? Bool { onPlaying(playing) }
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = action.request.url else { return .cancel }
            if url.absoluteString == "about:blank" || url.absoluteString == VideoLinks.pageOrigin { return .allow }
            if SpotifyLinks.isPlayerHost(url.host) {
                if action.targetFrame?.isMainFrame == false { return .allow }
                return action.navigationType == .linkActivated ? .cancel : .allow
            }
            return .cancel
        }
    }
}
