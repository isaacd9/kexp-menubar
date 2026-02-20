//
//  CompactContentView.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import SwiftUI

struct CompactContentView: View {
    var model: NowPlayingModel
    @Bindable var audioPlayer: AudioPlayer
    @AppStorage("playLocation") private var playLocation = AppDefaults.playLocation
    @AppStorage("autoReconnectSeconds") private var autoReconnectSeconds = AppDefaults.autoReconnectSeconds
    @AppStorage("compactMode") private var isCompact = false
    @State private var programNameHovered = false

    var body: some View {
        VStack(spacing: 12) {
            // Header
            ZStack {
                VStack(alignment: .center, spacing: 2) {
                    Button {
                        if let url = URL(string: "https://www.kexp.org/playlist/") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Text(model.programName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .underline(programNameHovered)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        programNameHovered = hovering
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }

                    if !model.hostNames.isEmpty {
                        Text("with \(model.hostNames)")
                            .font(.headline)
                            .foregroundStyle(.tertiary)
                    }
                }
                .multilineTextAlignment(.center)

                HStack {
                    HStack(spacing: 8) {
                        Image("KEXPLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 30)

                        if let hostImageURL = model.hostImageURL {
                            AsyncImage(url: hostImageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                        }
                    }

                    Spacer()

                    SettingsMenu(
                        audioPlayer: audioPlayer,
                        playLocation: $playLocation,
                        autoReconnectSeconds: $autoReconnectSeconds,
                        isCompact: $isCompact
                    )
                }
            }

            // Small art + song info side by side
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)

                    if model.isAirbreak {
                        Image("AirbreakArt")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let url = model.thumbnailURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(let error):
                                let _ = print("[AlbumArt] Failed to load \(url): \(error)")
                                Image(systemName: "music.note")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                            default:
                                Image(systemName: "music.note")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
                .id(model.thumbnailURL)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.song.isEmpty ? "—" : model.song)
                        .font(.title3.bold())
                        .lineLimit(1)

                    Text(model.artist.isEmpty ? "—" : model.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(model.album.isEmpty ? "—" : model.releaseYear.isEmpty ? model.album : "\(model.album) — \(model.releaseYear)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            ControlsView(
                audioPlayer: audioPlayer,
                song: model.song,
                artist: model.artist,
                isAirbreak: model.isAirbreak
            )
        }
        .padding()
        .foregroundStyle(.white)
        .frame(width: 360, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.kexpBackground)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.space) {
            audioPlayer.togglePlayback()
            return .handled
        }
        .onExitCommand {
            NSApp.keyWindow?.close()
        }
        .onAppear {
            model.setLocation(playLocation)
            audioPlayer.setAutoReconnectInterval(TimeInterval(autoReconnectSeconds))
            model.startPolling()
        }
        .onDisappear { model.stopPolling() }
        .onChange(of: playLocation) {
            model.setLocation(playLocation)
        }
        .onChange(of: autoReconnectSeconds) {
            audioPlayer.setAutoReconnectInterval(TimeInterval(autoReconnectSeconds))
        }
        .onChange(of: model.song) {
            audioPlayer.updateNowPlayingInfo(
                song: model.song,
                artist: model.artist,
                album: model.album,
                artworkURL: model.thumbnailURL
            )
        }
    }
}
