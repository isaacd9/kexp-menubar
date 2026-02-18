//
//  SettingsMenu.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import SwiftUI

struct SettingsMenu: View {
    @Bindable var audioPlayer: AudioPlayer
    @Binding var playLocation: Int
    @Binding var autoReconnectSeconds: Int

    var body: some View {
        Menu {
            Button("Reconnect Stream") {
                audioPlayer.reconnectStream()
            }

            Picker("Location", selection: $playLocation) {
                Text("Default").tag(1)
                Text("Bay Area").tag(2)
                Text("Seattle").tag(3)
            }

            Picker("Auto-Reconnect After Pause", selection: $autoReconnectSeconds) {
                Text("Never").tag(0)
                Text("5m").tag(300)
                Text("10m").tag(600)
                Text("30m").tag(1800)
                Text("60m").tag(3600)
            }

            Divider()

            Button("Quit KEXP") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
