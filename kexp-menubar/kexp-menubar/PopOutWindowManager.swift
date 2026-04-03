//
//  PopOutWindowManager.swift
//  kexp-menubar
//

import AppKit
import Combine
import SwiftUI

extension Notification.Name {
    static let kexpPopOutStateDidChange = Notification.Name("kexpPopOutStateDidChange")
}

@MainActor
final class PopOutState: ObservableObject {
    @Published var isPoppedOut = false
    private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .kexpPopOutStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.isPoppedOut = (note.userInfo?["isPoppedOut"] as? Bool) ?? false
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

@MainActor
class PopOutWindowManager: NSObject, NSWindowDelegate {
    static let shared = PopOutWindowManager()
    private var window: NSWindow?
    private var statusItem: NSStatusItem?
    private var playbackObserver: NSObjectProtocol?

    var isPopped: Bool { window != nil }

    func toggle(model: NowPlayingModel, audioPlayer: AudioPlayer) {
        if let window, window.isVisible {
            window.close()
            return
        }
        popOut(model: model, audioPlayer: audioPlayer)
    }

    private func popOut(model: NowPlayingModel, audioPlayer: AudioPlayer) {
        let content = PopOutContentView(model: model, audioPlayer: audioPlayer)
        let hostingView = NSHostingView(rootView: content)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 392, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "KEXP"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.level = .normal
        window.collectionBehavior = [.managed, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.backgroundColor = .kexpBackground
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()

        self.window = window

        // Show in Dock
        NSApp.setActivationPolicy(.regular)

        // Replace MenuBarExtra with a simple status item that focuses the window
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.target = self
            button.action = #selector(statusItemClicked(_:))
        }
        statusItem = item
        updateStatusItemIcon(isLive: audioPlayer.isPlaying || audioPlayer.isBuffering)

        // Mirror playback state on the status item icon
        playbackObserver = NotificationCenter.default.addObserver(
            forName: .kexpPlaybackStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let isPlaying = (note.userInfo?["isPlaying"] as? Bool) ?? false
            let isBuffering = (note.userInfo?["isBuffering"] as? Bool) ?? false
            self?.updateStatusItemIcon(isLive: isPlaying || isBuffering)
        }

        // Notify app to hide SwiftUI MenuBarExtra
        NotificationCenter.default.post(
            name: .kexpPopOutStateDidChange,
            object: nil,
            userInfo: ["isPoppedOut": true]
        )

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func tearDown() {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil

        if let playbackObserver {
            NotificationCenter.default.removeObserver(playbackObserver)
        }
        playbackObserver = nil

        NSApp.setActivationPolicy(.accessory)

        NotificationCenter.default.post(
            name: .kexpPopOutStateDidChange,
            object: nil,
            userInfo: ["isPoppedOut": false]
        )
    }

    private func updateStatusItemIcon(isLive: Bool) {
        guard let button = statusItem?.button else { return }
        if isLive {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            button.image = NSImage(systemSymbolName: "dot.radiowaves.left.and.right", accessibilityDescription: "KEXP")?
                .withSymbolConfiguration(config)
        } else {
            button.image = NSImage(named: "MenuBarIcon")
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let window else { return }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        window = nil
        tearDown()
    }
}

private struct PopOutContentView: View {
    var model: NowPlayingModel
    @Bindable var audioPlayer: AudioPlayer
    @AppStorage("compactMode") private var isCompact = false

    var body: some View {
        if isCompact {
            CompactContentView(model: model, audioPlayer: audioPlayer)
        } else {
            ContentView(model: model, audioPlayer: audioPlayer)
        }
    }
}
