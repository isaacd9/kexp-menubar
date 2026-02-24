//
//  ContentView.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import AppKit
import SwiftUI

class TappableTextView: NSTextView {
    var onTap: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        guard let layoutManager = layoutManager,
              let textContainer = textContainer,
              let textStorage = textStorage else {
            onTap?()
            return
        }

        let charIndex = layoutManager.characterIndex(
            for: point,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        guard charIndex < textStorage.length else {
            onTap?()
            return
        }

        let linkAttr = textStorage.attribute(.link, at: charIndex, effectiveRange: nil)
        let url: URL? = (linkAttr as? URL)
            ?? (linkAttr as? NSURL as URL?)
            ?? (linkAttr as? String).flatMap(URL.init(string:))

        if let url {
            NSWorkspace.shared.open(url)
        } else {
            onTap?()
        }
        // Never call super — NSTextView's mouseDown enters a blocking tracking loop
        // in MenuBarExtra context that hangs the app.
    }
}

struct CommentTextView: NSViewRepresentable {
    let comment: String
    var onTap: (() -> Void)?

    func makeNSView(context: Context) -> TappableTextView {
        let textView = TappableTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.linkTextAttributes = [
            .foregroundColor: NSColor.kexpOrange,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        return textView
    }

    func updateNSView(_ textView: TappableTextView, context: Context) {
        textView.textStorage?.setAttributedString(makeAttributedString())
        textView.onTap = onTap
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: TappableTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0,
              let textContainer = nsView.textContainer,
              let layoutManager = nsView.layoutManager else { return nil }
        textContainer.containerSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        return CGSize(width: width, height: ceil(usedRect.height))
    }

    private static let urlRegex = try? NSRegularExpression(pattern: #"https?://[^\s\)\]>]+"#)

    private func makeAttributedString() -> NSAttributedString {
        guard let regex = Self.urlRegex else {
            return NSAttributedString(string: comment, attributes: defaultAttrs)
        }

        let result = NSMutableAttributedString()
        let nsText = comment as NSString
        var lastEnd = 0

        for match in regex.matches(in: comment, range: NSRange(location: 0, length: nsText.length)) {
            if match.range.location > lastEnd {
                let plain = nsText.substring(with: NSRange(location: lastEnd, length: match.range.location - lastEnd))
                result.append(NSAttributedString(string: plain, attributes: defaultAttrs))
            }
            let urlString = nsText.substring(with: match.range)
            if let url = URL(string: urlString) {
                result.append(NSAttributedString(string: urlString, attributes: linkAttrs(url: url)))
            } else {
                result.append(NSAttributedString(string: urlString, attributes: defaultAttrs))
            }
            lastEnd = match.range.location + match.range.length
        }

        if lastEnd < nsText.length {
            result.append(NSAttributedString(string: nsText.substring(from: lastEnd), attributes: defaultAttrs))
        }

        return result
    }

    private var defaultAttrs: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor(white: 1.0, alpha: 0.6),
        ]
    }

    private func linkAttrs(url: URL) -> [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.kexpOrange,
            .link: url,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
    }
}

struct CommentView: View {
    let comment: String
    var allowCollapse: Bool = true
    @State private var expanded = false
    private let collapsedHeight: CGFloat = 80

    var body: some View {
        let isCollapsible = allowCollapse && shouldCollapseComment(comment)
        let isCollapsed = !expanded && isCollapsible
        VStack(spacing: 0) {
            CommentTextView(comment: comment, onTap: isCollapsible ? { expanded.toggle() } : nil)
                .frame(maxWidth: .infinity, maxHeight: isCollapsed ? collapsedHeight : nil, alignment: .topLeading)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 4)
                .mask {
                    if isCollapsed {
                        VStack(spacing: 0) {
                            Color.white
                            LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
                                .frame(height: 30)
                        }
                    } else {
                        Color.white
                    }
                }

            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)
                .opacity(isCollapsible ? 1 : 0)
                .onTapGesture {
                    guard isCollapsible else { return }
                    expanded.toggle()
                }
        }
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func shouldCollapseComment(_ comment: String) -> Bool {
        comment.count >= 220 || comment.split(whereSeparator: \.isNewline).count >= 5
    }
}

struct ContentView: View {
    var model: NowPlayingModel
    @Bindable var audioPlayer: AudioPlayer
    @State private var isShowingPlaylist = false
    @State private var expandedPlaylistIndex: Int?

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
                AlbumArtView(
                    isAirbreak: model.isAirbreak,
                    thumbnailURL: model.thumbnailURL
                )

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

                if !model.comment.isEmpty {
                    CommentView(comment: model.comment)
                }
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


#Preview {
    ContentView(model: NowPlayingModel(), audioPlayer: AudioPlayer())
}
