//
//  ContentView.swift
//  kexp-manubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import AVKit
import SwiftUI

struct ContentView: View {
    @State private var model = NowPlayingModel()
    @State private var audioPlayer = AudioPlayer()
    @State private var commentExpanded = false
    @AppStorage("playLocation") private var playLocation = 1

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image("KEXPLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.programName.isEmpty ? "" : model.programName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if !model.hostNames.isEmpty {
                        Text("with \(model.hostNames)")
                            .font(.headline)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Menu {
                    Picker("Location", selection: $playLocation) {
                        Text("Default").tag(1)
                        Text("Bay Area").tag(2)
                        Text("Seattle").tag(3)
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

            // Album art area
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
                VStack(spacing: 0) {
                    if commentExpanded {
                        Text(markdownWithLinks(model.comment))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .tint(Color(red: 0xfb/255.0, green: 0xad/255.0, blue: 0x18/255.0))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                    } else {
                        Text(model.comment)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, maxHeight: 80, alignment: .topLeading)
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

                    Image(systemName: commentExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 6)
                }
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture { commentExpanded.toggle() }
            }

            // Controls area
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
                            Text(audioPlayer.isPlaying ? "Pause" : "Listen Live")
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
                    if !model.isAirbreak {
                        Button(action: {
                            let query = "\(model.song) \(model.artist)"
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
                            let query = "\(model.song), \(model.artist)"
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
            model.startPolling()
        }
        .onDisappear { model.stopPolling() }
        .onChange(of: playLocation) {
            model.setLocation(playLocation)
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

struct AirPlayButton: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.isRoutePickerButtonBordered = false
        return picker
    }

    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
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
        // Add text before the URL
        if match.range.location > lastEnd {
            let plain = nsText.substring(with: NSRange(location: lastEnd, length: match.range.location - lastEnd))
            result.append(AttributedString(plain))
        }
        // Add the URL as a link
        let urlString = nsText.substring(with: match.range)
        if let url = URL(string: urlString) {
            var link = AttributedString(urlString)
            link.link = url
            result.append(link)
        } else {
            result.append(AttributedString(urlString))
        }
        lastEnd = match.range.location + match.range.length
    }

    // Add remaining text
    if lastEnd < nsText.length {
        let remaining = nsText.substring(from: lastEnd)
        result.append(AttributedString(remaining))
    }

    return result
}

#Preview {
    ContentView()
}
