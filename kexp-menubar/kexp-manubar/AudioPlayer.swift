//
//  AudioPlayer.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import AVFoundation
import Foundation

@Observable
class AudioPlayer {
    var isPlaying: Bool = false
    var isBuffering: Bool = false

    private var player = AVPlayer(url: URL(string: "https://kexp.streamguys1.com/kexp160.aac")!)
    private var observation: NSKeyValueObservation?

    init() {
        observation = player.observe(\.timeControlStatus) { [weak self] player, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                self.isPlaying = player.timeControlStatus == .playing
            }
        }
    }

    func togglePlayback() {
        if isPlaying || isBuffering {
            player.pause()
        } else {
            // Seek to live edge then play
            if let lastRange = player.currentItem?.loadedTimeRanges.last?.timeRangeValue {
                let liveEdge = CMTimeAdd(lastRange.start, lastRange.duration)
                player.seek(to: liveEdge)
            }
            player.play()
        }
    }
}
