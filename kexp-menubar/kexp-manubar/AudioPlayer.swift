//
//  AudioPlayer.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import AppKit
import AVFoundation
import Foundation
import MediaPlayer

@Observable
class AudioPlayer {
    var isPlaying: Bool = false
    var isBuffering: Bool = false

    private let streamURL = URL(string: "https://kexp.streamguys1.com/kexp160.aac")!
    private var player = AVPlayer()
    private var observation: NSKeyValueObservation?

    init() {
        observation = player.observe(\.timeControlStatus) { [weak self] player, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                self.isPlaying = player.timeControlStatus == .playing
                MPNowPlayingInfoCenter.default().playbackState = self.isPlaying ? .playing : .paused
            }
        }

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self, !self.isPlaying else { return .success }
            self.togglePlayback()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self, self.isPlaying || self.isBuffering else { return .success }
            self.togglePlayback()
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayback()
            return .success
        }
    }

    func togglePlayback() {
        if isPlaying || isBuffering {
            player.pause()
        } else if let lastRange = player.currentItem?.loadedTimeRanges.last?.timeRangeValue {
            // Buffer still has data — seek to live edge and resume (skips pre-roll)
            let liveEdge = CMTimeAdd(lastRange.start, lastRange.duration)
            player.seek(to: liveEdge)
            player.play()
        } else {
            // Buffer is stale/empty — need a fresh connection
            player.replaceCurrentItem(with: AVPlayerItem(url: streamURL))
            player.play()
        }
    }

    func updateNowPlayingInfo(song: String, artist: String, album: String, artworkURL: URL?) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyAlbumTitle: album,
            MPNowPlayingInfoPropertyIsLiveStream: true,
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        guard let artworkURL = artworkURL else { return }
        print("[NowPlaying] Fetching artwork from: \(artworkURL)")
        URLSession.shared.dataTask(with: artworkURL) { data, response, error in
            if let error = error {
                print("[NowPlaying] Artwork fetch error: \(error)")
                return
            }
            guard let data = data else {
                print("[NowPlaying] Artwork fetch returned no data")
                return
            }
            print("[NowPlaying] Artwork fetched \(data.count) bytes")
            guard let image = NSImage(data: data) else {
                print("[NowPlaying] Failed to create NSImage from data")
                return
            }
            print("[NowPlaying] Artwork image created: \(image.size)")
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            DispatchQueue.main.async {
                info[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                print("[NowPlaying] Now playing info updated with artwork")
            }
        }.resume()
    }
}
