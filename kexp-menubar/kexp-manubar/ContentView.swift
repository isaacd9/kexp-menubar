//
//  ContentView.swift
//  kexp-manubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var model = NowPlayingModel()

    var body: some View {
        VStack(spacing: 12) {
            // Show name
            VStack(spacing: 2) {
                Text(model.programName.isEmpty ? "KEXP" : model.programName)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if !model.hostNames.isEmpty {
                    Text("with \(model.hostNames)")
                        .font(.caption)
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
                    .font(.headline)

                Text(model.artist.isEmpty ? "—" : model.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(model.album.isEmpty ? "—" : model.album)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Host comment
            if !model.comment.isEmpty {
                Text(model.comment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 280, alignment: .leading)
            }

            // Controls area
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Listen Live")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .onAppear { model.startPolling() }
        .onDisappear { model.stopPolling() }
    }
}

#Preview {
    ContentView()
}
