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
    private let playlistScrollMaxHeight: CGFloat = 420

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
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if model.recentSongs.isEmpty {
                            Text("No recent songs")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(model.recentSongs) { song in
                                VStack(spacing: 6) {
                                    Button {
                                        guard !song.comment.isEmpty else { return }
                                        expandedPlaylistSongID = expandedPlaylistSongID == song.id ? nil : song.id
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

                                    if expandedPlaylistSongID == song.id && !song.comment.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            CommentView(comment: song.comment, allowCollapse: false)
                                            SongLinkButtonsView(song: song.song, artist: song.artist, isAirbreak: song.isAirbreak)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: playlistScrollMaxHeight, alignment: .top)
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
                isAirbreak: model.isAirbreak,
                showSongLinks: !isShowingPlaylist
            )
        }
        .onChange(of: model.comment) {
            isNowPlayingCommentExpanded = false
        }
        .onChange(of: isShowingPlaylist) {
            guard !isShowingPlaylist else { return }
            expandedPlaylistSongID = nil
        }
        .kexpWindow(model: model, audioPlayer: audioPlayer)
    }
}
