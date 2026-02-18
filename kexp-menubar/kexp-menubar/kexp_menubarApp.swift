//
//  kexp_menubarApp.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class MenuBarPlaybackState: ObservableObject {
    @Published var isLive = false
    private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .kexpPlaybackStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let isPlaying = (note.userInfo?["isPlaying"] as? Bool) ?? false
            let isBuffering = (note.userInfo?["isBuffering"] as? Bool) ?? false
            self?.isLive = isPlaying || isBuffering
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

@main
struct kexp_menubarApp: App {
    @State private var audioPlayer = AudioPlayer()
    @StateObject private var playbackState = MenuBarPlaybackState()
    @AppStorage("compactMode") private var isCompact = false

    var body: some Scene {
        MenuBarExtra {
            if isCompact {
                CompactContentView(audioPlayer: audioPlayer)
            } else {
                ContentView(audioPlayer: audioPlayer)
            }
        } label: {
            if playbackState.isLive {
                Label("KEXP", systemImage: "dot.radiowaves.left.and.right")
            } else {
                Label("KEXP", image: "MenuBarIcon")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
