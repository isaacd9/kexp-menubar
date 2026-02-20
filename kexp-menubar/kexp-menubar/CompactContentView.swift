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

    var body: some View {
        VStack(spacing: 12) {
            HeaderView(
                programName: model.programName,
                hostNames: model.hostNames,
                hostImageURL: model.hostImageURL,
                audioPlayer: audioPlayer
            )

            // Small art + song info side by side
            HStack(alignment: .center, spacing: 12) {
                AlbumArtView(
                    isAirbreak: model.isAirbreak,
                    thumbnailURL: model.thumbnailURL,
                    size: 72,
                    cornerRadius: 6,
                    iconSize: 16
                )

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
        .kexpWindow(model: model, audioPlayer: audioPlayer)
    }
}
