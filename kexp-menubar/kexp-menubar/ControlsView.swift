//
//  ControlsView.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import SwiftUI

struct ControlsView: View {
    @Bindable var audioPlayer: AudioPlayer
    let song: String
    let artist: String
    let isAirbreak: Bool

    var body: some View {
        ZStack {
            Button(action: { audioPlayer.togglePlayback() }) {
                HStack(spacing: 8) {
                    if audioPlayer.isBuffering {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                        Text("Catching up…")
                    } else {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        if audioPlayer.isPlaying {
                            Text("Pause")
                        } else {
                            Text(audioPlayer.hasInitializedStream ? "Listen Live" : "Start Streaming")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(red: 0xfb/255.0, green: 0xad/255.0, blue: 0x18/255.0))
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(audioPlayer.isBuffering)

            HStack {
                if !isAirbreak {
                    Button(action: {
                        let query = "\(song) \(artist)"
                            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "music://music.apple.com/search?term=\(query)") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Image("AppleMusicIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        let query = "\(song), \(artist)"
                            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "spotify:search:\(query)") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Image("SpotifyIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                AirPlayButton()
                    .frame(width: 28, height: 28)
            }
        }
    }
}
