//
//  SettingsMenu.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import AppKit
import SwiftUI

struct SettingsMenu: NSViewRepresentable {
    var audioPlayer: AudioPlayer
    @Binding var playLocation: Int
    @Binding var autoReconnectSeconds: Int
    @Binding var isCompact: Bool

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        button.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: "Settings")?
            .withSymbolConfiguration(config)
        button.isBordered = false
        button.imageScaling = .scaleProportionallyUpOrDown
        button.contentTintColor = .secondaryLabelColor
        button.target = context.coordinator
        button.action = #selector(Coordinator.buttonClicked(_:))
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSButton, context: Context) -> CGSize? {
        CGSize(width: 22, height: 22)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var parent: SettingsMenu

        init(_ parent: SettingsMenu) {
            self.parent = parent
        }

        @objc func buttonClicked(_ sender: NSButton) {
            let menu = buildMenu()
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 2), in: sender)
        }

        private func buildMenu() -> NSMenu {
            let menu = NSMenu()
            menu.autoenablesItems = false

            // Volume — submenu containing a slider
            let volumeItem = NSMenuItem(title: "Stream Volume", action: nil, keyEquivalent: "")
            let volumeSubmenu = NSMenu(title: "Stream Volume")
            volumeSubmenu.addItem(makeVolumeSliderItem())
            volumeItem.submenu = volumeSubmenu
            menu.addItem(volumeItem)

            menu.addItem(.separator())

            // Compact Mode
            let compactItem = NSMenuItem(title: "Compact Mode", action: #selector(toggleCompact(_:)), keyEquivalent: "")
            compactItem.target = self
            compactItem.state = parent.isCompact ? .on : .off
            compactItem.isEnabled = true
            menu.addItem(compactItem)

            menu.addItem(.separator())

            // Reconnect Stream
            let reconnectItem = NSMenuItem(title: "Reconnect Stream", action: #selector(reconnectStream(_:)), keyEquivalent: "")
            reconnectItem.target = self
            reconnectItem.isEnabled = true
            menu.addItem(reconnectItem)

            // Location
            let locationItem = NSMenuItem(title: "Location", action: nil, keyEquivalent: "")
            let locationSubmenu = NSMenu(title: "Location")
            for (tag, title) in [(1, "Default"), (2, "Bay Area"), (3, "Seattle")] {
                let item = NSMenuItem(title: title, action: #selector(setLocation(_:)), keyEquivalent: "")
                item.tag = tag
                item.target = self
                item.state = parent.playLocation == tag ? .on : .off
                item.isEnabled = true
                locationSubmenu.addItem(item)
            }
            locationItem.submenu = locationSubmenu
            menu.addItem(locationItem)

            // Auto-Reconnect After Pause
            let autoReconnectItem = NSMenuItem(title: "Auto-Reconnect After Pause", action: nil, keyEquivalent: "")
            let autoReconnectSubmenu = NSMenu(title: "Auto-Reconnect After Pause")
            for (tag, title) in [(0, "Never"), (300, "5m"), (600, "10m"), (1800, "30m"), (3600, "60m")] {
                let item = NSMenuItem(title: title, action: #selector(setAutoReconnect(_:)), keyEquivalent: "")
                item.tag = tag
                item.target = self
                item.state = parent.autoReconnectSeconds == tag ? .on : .off
                item.isEnabled = true
                autoReconnectSubmenu.addItem(item)
            }
            autoReconnectItem.submenu = autoReconnectSubmenu
            menu.addItem(autoReconnectItem)

            menu.addItem(.separator())

            // Quit
            let quitItem = NSMenuItem(title: "Quit KEXP", action: #selector(quitApp(_:)), keyEquivalent: "")
            quitItem.target = self
            quitItem.isEnabled = true
            menu.addItem(quitItem)

            return menu
        }

        private func makeVolumeSliderItem() -> NSMenuItem {
            let item = NSMenuItem()

            let container = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 34))

            let leftIcon = NSImageView(frame: NSRect(x: 10, y: 9, width: 14, height: 16))
            leftIcon.image = NSImage(systemSymbolName: "speaker.fill", accessibilityDescription: nil)
            leftIcon.contentTintColor = .secondaryLabelColor
            container.addSubview(leftIcon)

            let slider = NSSlider(frame: NSRect(x: 30, y: 7, width: 158, height: 20))
            slider.minValue = 0
            slider.maxValue = 1
            slider.doubleValue = Double(parent.audioPlayer.volume)
            slider.isContinuous = true
            slider.target = self
            slider.action = #selector(volumeChanged(_:))
            container.addSubview(slider)

            let rightIcon = NSImageView(frame: NSRect(x: 194, y: 9, width: 18, height: 16))
            rightIcon.image = NSImage(systemSymbolName: "speaker.wave.3.fill", accessibilityDescription: nil)
            rightIcon.contentTintColor = .secondaryLabelColor
            container.addSubview(rightIcon)

            item.view = container
            return item
        }

        @objc private func volumeChanged(_ slider: NSSlider) {
            parent.audioPlayer.setVolume(Float(slider.doubleValue))
        }

        @objc private func toggleCompact(_ sender: NSMenuItem) {
            parent.isCompact = !parent.isCompact
        }

        @objc private func reconnectStream(_ sender: NSMenuItem) {
            parent.audioPlayer.reconnectStream()
        }

        @objc private func setLocation(_ sender: NSMenuItem) {
            parent.playLocation = sender.tag
        }

        @objc private func setAutoReconnect(_ sender: NSMenuItem) {
            parent.autoReconnectSeconds = sender.tag
        }

        @objc private func quitApp(_ sender: NSMenuItem) {
            NSApplication.shared.terminate(nil)
        }
    }
}
