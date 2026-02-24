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
    @State private var isShowingPlaylist = false

    var body: some View {
        VStack(spacing: 12) {
            HeaderView(
                programName: model.programName,
                hostNames: model.hostNames,
                hostImageURL: model.hostImageURL,
                audioPlayer: audioPlayer,
                isShowingPlaylist: isShowingPlaylist,
                onPlaylistToggle: { isShowingPlaylist.toggle() }
            )

            if isShowingPlaylist {
                VStack(spacing: 10) {
                    if model.recentSongs.isEmpty {
                        Text("No recent songs")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(Array(model.recentSongs.enumerated()), id: \.offset) { entry in
                            let song = entry.element
                            CompactSongRowView(
                                isAirbreak: song.isAirbreak,
                                thumbnailURL: song.thumbnailURL,
                                song: song.song,
                                artist: song.artist,
                                album: song.album,
                                releaseYear: song.releaseYear
                            )
                        }
                    }
                }
            } else {
                CompactSongRowView(
                    isAirbreak: model.isAirbreak,
                    thumbnailURL: model.thumbnailURL,
                    song: model.song,
                    artist: model.artist,
                    album: model.album,
                    releaseYear: model.releaseYear
                )
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
