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
    @State private var expandedPlaylistSongID: RecentSong.ID?
    @State private var isNowPlayingCommentExpanded = false

    var body: some View {
        VStack(spacing: 12) {
            HeaderView(
                programName: model.programName,
                hostNames: model.hostNames,
                hostImageURL: model.hostImageURL,
                audioPlayer: audioPlayer,
                model: model,
                isShowingPlaylist: isShowingPlaylist,
                onPlaylistToggle: togglePlaylist
            )

            if isShowingPlaylist {
                PlaylistScrollView(model: model, expandedPlaylistSongID: $expandedPlaylistSongID)
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
                            releaseYear: model.releaseYear,
                            playedAt: nil
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
                isAirbreak: model.isAirbreak,
                showSongLinks: !isShowingPlaylist
            )
        }
        .onChange(of: model.comment) {
            isNowPlayingCommentExpanded = false
        }
        .kexpWindow(model: model, audioPlayer: audioPlayer)
    }

    private func togglePlaylist() {
        isShowingPlaylist.toggle()
        model.setPlaylistActive(isShowingPlaylist)
        if !isShowingPlaylist {
            expandedPlaylistSongID = nil
        }
    }
}
