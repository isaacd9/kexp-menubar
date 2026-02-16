//
//  ContentView.swift
//  kexp-manubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var model = NowPlayingModel()
    @State private var audioPlayer = AudioPlayer()

    var body: some View {
        VStack(spacing: 12) {
            // Show name
            VStack(spacing: 2) {
                Text(model.programName.isEmpty ? "KEXP" : model.programName)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                if !model.hostNames.isEmpty {
                    Text("with \(model.hostNames)")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }

            // Album art area
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)

                if let url = model.thumbnailURL {
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
                    .font(.title3.bold())

                Text(model.artist.isEmpty ? "—" : model.artist)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(model.album.isEmpty ? "—" : model.releaseYear.isEmpty ? model.album : "\(model.album) — \(model.releaseYear)")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }

            // Host comment
            if !model.comment.isEmpty {
                Text(markdownWithLinks(model.comment))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .tint(Color(red: 0xfb/255.0, green: 0xad/255.0, blue: 0x18/255.0))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 260)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Controls area
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
        }
        .padding()
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0x23/255.0, green: 0x1f/255.0, blue: 0x20/255.0))
        .onAppear { model.startPolling() }
        .onDisappear { model.stopPolling() }
    }
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
