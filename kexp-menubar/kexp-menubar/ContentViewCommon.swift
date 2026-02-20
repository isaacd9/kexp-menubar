//
//  ContentViewCommon.swift
//  kexp-menubar
//

import AppKit
import SwiftUI

// MARK: - HeaderView

struct HeaderView: View {
    let programName: String
    let hostNames: String
    let hostImageURL: URL?
    var audioPlayer: AudioPlayer

    @AppStorage("playLocation") private var playLocation = AppDefaults.playLocation
    @AppStorage("autoReconnectSeconds") private var autoReconnectSeconds = AppDefaults.autoReconnectSeconds
    @AppStorage("compactMode") private var isCompact = false
    @State private var programNameHovered = false

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 2) {
                Button {
                    if let url = URL(string: "https://www.kexp.org/playlist/") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text(programName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .underline(programNameHovered)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    programNameHovered = hovering
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }

                if !hostNames.isEmpty {
                    Text("with \(hostNames)")
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

                    if let hostImageURL {
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
    }
}

// MARK: - AlbumArtView

struct AlbumArtView: View {
    let isAirbreak: Bool
    let thumbnailURL: URL?
    var size: CGFloat = 280
    var cornerRadius: CGFloat = 8
    var iconSize: CGFloat = 32

    @State private var retryCount = 0
    private let maxRetries = 2

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.quaternary)

            if isAirbreak {
                Image("AirbreakArt")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let url = thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(let error):
                        let _ = print("[AlbumArt] Failed to load \(url) (attempt \(retryCount + 1)): \(error)")
                        Image(systemName: "music.note")
                            .font(.system(size: iconSize))
                            .foregroundStyle(.secondary)
                            .onAppear {
                                if retryCount < maxRetries {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        retryCount += 1
                                    }
                                }
                            }
                    default:
                        Image(systemName: "music.note")
                            .font(.system(size: iconSize))
                            .foregroundStyle(.secondary)
                    }
                }
                .id(retryCount)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: iconSize))
                    .foregroundStyle(.secondary)
            }
        }
        .id(thumbnailURL)
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onChange(of: thumbnailURL) { retryCount = 0 }
    }
}

// MARK: - KEXPWindowModifier

struct KEXPWindowModifier: ViewModifier {
    var model: NowPlayingModel
    @Bindable var audioPlayer: AudioPlayer
    @AppStorage("playLocation") private var playLocation = AppDefaults.playLocation
    @AppStorage("autoReconnectSeconds") private var autoReconnectSeconds = AppDefaults.autoReconnectSeconds

    func body(content: Content) -> some View {
        content
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
                model.startPolling(interval: 1)
            }
            .onDisappear { model.startPolling(interval: 3) }
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

extension View {
    func kexpWindow(model: NowPlayingModel, audioPlayer: AudioPlayer) -> some View {
        modifier(KEXPWindowModifier(model: model, audioPlayer: audioPlayer))
    }
}
