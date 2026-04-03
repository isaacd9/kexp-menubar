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
    private var panel: NSPanel?
    private var statusItem: NSStatusItem?
    private var playbackObserver: NSObjectProtocol?

    var isPopped: Bool { panel != nil }

    func toggle(model: NowPlayingModel, audioPlayer: AudioPlayer) {
        if let panel, panel.isVisible {
            panel.close()
            return
        }
        popOut(model: model, audioPlayer: audioPlayer)
    }

    private func popOut(model: NowPlayingModel, audioPlayer: AudioPlayer) {
        let content = PopOutContentView(model: model, audioPlayer: audioPlayer)
        let hostingView = NSHostingView(rootView: content)
        hostingView.sizingOptions = [.intrinsicContentSize]

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 392, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "KEXP"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .kexpBackground
        panel.contentView = hostingView
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.center()

        self.panel = panel

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
        panel.makeKeyAndOrderFront(nil)
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
            button.image = NSImage(systemSymbolName: "dot.radiowaves.left.and.right", accessibilityDescription: "KEXP")
        } else {
            button.image = NSImage(named: "MenuBarIcon")
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let panel else { return }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        panel = nil
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
