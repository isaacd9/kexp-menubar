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

extension Notification.Name {
    static let kexpPlaybackStateDidChange = Notification.Name("kexpPlaybackStateDidChange")
}

@Observable
class AudioPlayer {
    var isPlaying: Bool = false
    var isBuffering: Bool = false
    var hasInitializedStream: Bool = false

    private let streamURL = URL(string: "https://kexp.streamguys1.com/kexp160.aac")!
    private var player = AVPlayer()
    private var observation: NSKeyValueObservation?
    private var isSoftPaused = false
    private var softPausedAt: Date?
    private var lastNowPlayingInfo: [String: Any] = [:]
    private var maxSoftPauseBeforeReconnect: TimeInterval = 3600

    init() {
        configurePlayer()
        observePlayer()

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
            softPause()
            return
        }

        if isSoftPaused {
            resumeFromSoftPause()
            return
        }

        if let lastRange = player.currentItem?.loadedTimeRanges.last?.timeRangeValue {
            // Buffer still has data — seek to live edge and resume (skips pre-roll)
            let liveEdge = CMTimeAdd(lastRange.start, lastRange.duration)
            player.seek(to: liveEdge)
            player.play()
        } else {
            // No active item yet — create connection once.
            player.replaceCurrentItem(with: AVPlayerItem(url: streamURL))
            hasInitializedStream = true
            player.play()
        }
        player.isMuted = false
        isSoftPaused = false
        publishNowPlayingInfo()
    }

    func reconnectStream() {
        let shouldKeepWarmPaused = isSoftPaused
        let shouldPlayAudibly = isPlaying || isBuffering

        player.replaceCurrentItem(with: AVPlayerItem(url: streamURL))
        hasInitializedStream = true

        if shouldKeepWarmPaused {
            isSoftPaused = true
            player.isMuted = true
            player.play()
            isPlaying = false
            isBuffering = false
            MPNowPlayingInfoCenter.default().playbackState = .paused
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            notifyPlaybackStateChanged()
            return
        }

        isSoftPaused = false
        player.isMuted = false
        if shouldPlayAudibly {
            player.play()
            publishNowPlayingInfo()
        } else {
            player.pause()
            isPlaying = false
            isBuffering = false
            MPNowPlayingInfoCenter.default().playbackState = .paused
        }
        notifyPlaybackStateChanged()
    }

    func setAutoReconnectInterval(_ seconds: TimeInterval) {
        maxSoftPauseBeforeReconnect = max(0, seconds)
    }

    func updateNowPlayingInfo(song: String, artist: String, album: String, artworkURL: URL?) {
        lastNowPlayingInfo = [
            MPMediaItemPropertyTitle: song,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyAlbumTitle: album,
            MPNowPlayingInfoPropertyIsLiveStream: true,
        ]

        publishNowPlayingInfo()

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
                self.lastNowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                self.publishNowPlayingInfo()
                print("[NowPlaying] Now playing info updated with artwork")
            }
        }.resume()
    }

    private func configurePlayer() {
        // Force local rendering so AirPlay routes app audio instead of remote URL handoff.
        player.allowsExternalPlayback = false
    }

    private func observePlayer() {
        observation = player.observe(\.timeControlStatus) { [weak self] player, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isBuffering = !self.isSoftPaused && player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                self.isPlaying = !self.isSoftPaused && player.timeControlStatus == .playing
                MPNowPlayingInfoCenter.default().playbackState = self.isPlaying ? .playing : .paused
                self.notifyPlaybackStateChanged()
            }
        }
    }

    private func softPause() {
        isSoftPaused = true
        softPausedAt = Date()
        player.isMuted = true
        isPlaying = false
        isBuffering = false
        MPNowPlayingInfoCenter.default().playbackState = .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        notifyPlaybackStateChanged()
    }

    private func resumeFromSoftPause() {
        isSoftPaused = false
        let elapsed = softPausedAt.map { Date().timeIntervalSince($0) } ?? 0
        self.softPausedAt = nil

        let needsReconnect = maxSoftPauseBeforeReconnect > 0 && elapsed > maxSoftPauseBeforeReconnect
        if needsReconnect || player.currentItem?.status == .failed {
            observation = nil
            player.pause()
            player = AVPlayer()
            configurePlayer()
            observePlayer()
            player.replaceCurrentItem(with: AVPlayerItem(url: streamURL))
        } else if player.currentItem == nil {
            player.replaceCurrentItem(with: AVPlayerItem(url: streamURL))
        }

        player.isMuted = false
        player.play()
        publishNowPlayingInfo()
    }

    private func publishNowPlayingInfo() {
        guard !isSoftPaused else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = lastNowPlayingInfo.isEmpty ? nil : lastNowPlayingInfo
    }

    private func notifyPlaybackStateChanged() {
        NotificationCenter.default.post(
            name: .kexpPlaybackStateDidChange,
            object: nil,
            userInfo: [
                "isPlaying": isPlaying,
                "isBuffering": isBuffering,
            ]
        )
    }
}
