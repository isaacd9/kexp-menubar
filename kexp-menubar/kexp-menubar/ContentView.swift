//
//  ContentView.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import SwiftUI

struct CommentView: View {
    let comment: String
    @State private var expanded = false
    private let collapsedHeight: CGFloat = 80

    var body: some View {
        let isCollapsible = shouldCollapseComment(comment)
        VStack(spacing: 0) {
            if expanded || !isCollapsible {
                Text(markdownWithLinks(comment))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .tint(Color(red: 0xfb/255.0, green: 0xad/255.0, blue: 0x18/255.0))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            } else {
                Text(comment)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, maxHeight: collapsedHeight, alignment: .topLeading)
                    .mask(
                        VStack(spacing: 0) {
                            Color.white
                            LinearGradient(
                                colors: [.white, .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 30)
                        }
                    )
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            }

            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)
                .opacity(isCollapsible ? 1 : 0)
        }
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            guard isCollapsible else { return }
            expanded.toggle()
        }
    }

    private func shouldCollapseComment(_ comment: String) -> Bool {
        comment.count >= 220 || comment.split(whereSeparator: \.isNewline).count >= 5
    }

    private func markdownWithLinks(_ text: String) -> AttributedString {
        let pattern = #"https?://[^\s\)\]>]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return AttributedString(text)
        }

        var result = AttributedString()
        let nsText = text as NSString
        var lastEnd = 0

        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        for match in matches {
            if match.range.location > lastEnd {
                let plain = nsText.substring(with: NSRange(location: lastEnd, length: match.range.location - lastEnd))
                result.append(AttributedString(plain))
            }
            let urlString = nsText.substring(with: match.range)
            if let url = URL(string: urlString) {
                var link = AttributedString(urlString)
                link.link = url
                link.underlineStyle = .single
                result.append(link)
            } else {
                result.append(AttributedString(urlString))
            }
            lastEnd = match.range.location + match.range.length
        }

        if lastEnd < nsText.length {
            result.append(AttributedString(nsText.substring(from: lastEnd)))
        }

        return result
    }
}

struct ContentView: View {
    var model: NowPlayingModel
    @Bindable var audioPlayer: AudioPlayer
    @AppStorage("playLocation") private var playLocation = 1
    @AppStorage("autoReconnectSeconds") private var autoReconnectSeconds = 3600
    @AppStorage("compactMode") private var isCompact = false  // passed to SettingsMenu only
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

            // Album art
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)

                if model.isAirbreak {
                    Image("AirbreakArt")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let url = model.thumbnailURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 280, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Song info
            VStack(spacing: 4) {
                Text(model.song.isEmpty ? "—" : model.song)
                    .font(.title2.bold())

                Text(model.artist.isEmpty ? "—" : model.artist)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text(model.album.isEmpty ? "—" : model.releaseYear.isEmpty ? model.album : "\(model.album) — \(model.releaseYear)")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }

            // Host comment
            if !model.comment.isEmpty {
                CommentView(comment: model.comment)
            }

            // Controls area
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
        .background(Color(red: 0x23/255.0, green: 0x1f/255.0, blue: 0x20/255.0))
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.space) {
            audioPlayer.togglePlayback()
            return .handled
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


#Preview {
    ContentView(model: NowPlayingModel(), audioPlayer: AudioPlayer())
}
