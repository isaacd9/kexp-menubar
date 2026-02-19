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
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.linkTextAttributes = [
            .foregroundColor: NSColor(red: 0xfb/255.0, green: 0xad/255.0, blue: 0x18/255.0, alpha: 1.0),
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        return textView
    }

    func updateNSView(_ textView: TappableTextView, context: Context) {
        textView.textStorage?.setAttributedString(makeAttributedString())
        textView.onTap = onTap
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: TappableTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        let bounds = makeAttributedString().boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        return CGSize(width: width, height: ceil(bounds.height))
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
            .foregroundColor: NSColor(red: 0xfb/255.0, green: 0xad/255.0, blue: 0x18/255.0, alpha: 1.0),
            .link: url,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
    }
}

struct CommentView: View {
    let comment: String
    @State private var expanded = false
    private let collapsedHeight: CGFloat = 80

    var body: some View {
        let isCollapsible = shouldCollapseComment(comment)
        VStack(spacing: 0) {
            let textView = CommentTextView(comment: comment, onTap: isCollapsible ? { expanded.toggle() } : nil)
                .frame(maxWidth: .infinity, maxHeight: !expanded && isCollapsible ? collapsedHeight : nil, alignment: .topLeading)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 4)
            if !expanded && isCollapsible {
                textView.mask {
                    VStack(spacing: 0) {
                        Color.white
                        LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
                            .frame(height: 30)
                    }
                }
            } else {
                textView
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
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(let error):
                            let _ = print("[AlbumArt] Failed to load \(url): \(error)")
                            Image(systemName: "music.note")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                        default:
                            Image(systemName: "music.note")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                }
            }
            .id(model.thumbnailURL)
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
