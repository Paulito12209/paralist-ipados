// Zusammenhang: Sources/ParalistCore/Links/SpotifyLinks.swift
import Testing
@testable import ParalistCore

struct SpotifyLinksTests {
    @Test func readsShareLinks() {
        let item = SpotifyLinks.item("https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC?si=abc")
        #expect(item == SpotifyItem(kind: "track", id: "4uLU6hMCjMI75M1A2tKUQC"))
        #expect(item?.uri == "spotify:track:4uLU6hMCjMI75M1A2tKUQC")
        #expect(SpotifyLinks.item("https://open.spotify.com/intl-de/album/1DFixLWuPkv3KT3TnV35m3")?.kind == "album")
        #expect(SpotifyLinks.item("https://open.spotify.com/embed/playlist/37i9dQZF1DXcBWIGoYBM5M")?.kind == "playlist")
        #expect(SpotifyLinks.item("spotify:episode:512ojhOuo1ktJprKbVcKyQ")?.isTrack == true)
    }

    @Test func ignoresOtherLinks() {
        #expect(SpotifyLinks.item("https://open.spotify.com/user/abc") == nil)
        #expect(SpotifyLinks.item("https://open.spotify.com/track/short") == nil)
        #expect(SpotifyLinks.item("https://example.com/track/4uLU6hMCjMI75M1A2tKUQC") == nil)
        #expect(SpotifyLinks.item("spotify:track") == nil)
    }

    @Test func playerHostsStayOnSpotify() {
        #expect(SpotifyLinks.isPlayerHost("open.spotify.com"))
        #expect(SpotifyLinks.isPlayerHost("i.scdn.co"))
        #expect(!SpotifyLinks.isPlayerHost("spotify.com.evil.org"))
        #expect(!SpotifyLinks.isPlayerHost(nil))
    }
}
