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
    @State private var expandedPlaylistIndex: Int?
    @State private var isNowPlayingCommentExpanded = false

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
                            let index = entry.offset
                            let song = entry.element
                            VStack(spacing: 6) {
                                Button {
                                    guard !song.comment.isEmpty else { return }
                                    expandedPlaylistIndex = expandedPlaylistIndex == index ? nil : index
                                } label: {
                                    CompactSongRowView(
                                        isAirbreak: song.isAirbreak,
                                        thumbnailURL: song.thumbnailURL,
                                        song: song.song,
                                        artist: song.artist,
                                        album: song.album,
                                        releaseYear: song.releaseYear
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if expandedPlaylistIndex == index && !song.comment.isEmpty {
                                    CommentView(comment: song.comment, allowCollapse: false)
                                }
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 6) {
                    Button {
                        guard !model.comment.isEmpty else { return }
                        isNowPlayingCommentExpanded.toggle()
                    } label: {
                        CompactSongRowView(
                            isAirbreak: model.isAirbreak,
                            thumbnailURL: model.thumbnailURL,
                            song: model.song,
                            artist: model.artist,
                            album: model.album,
                            releaseYear: model.releaseYear
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if isNowPlayingCommentExpanded && !model.comment.isEmpty {
                        CommentView(comment: model.comment, allowCollapse: false)
                    }
                }
            }

            ControlsView(
                audioPlayer: audioPlayer,
                song: model.song,
                artist: model.artist,
                isAirbreak: model.isAirbreak
            )
        }
        .onChange(of: model.comment) {
            isNowPlayingCommentExpanded = false
        }
        .kexpWindow(model: model, audioPlayer: audioPlayer)
    }
}
