# KEXP Menubar

Unofficial macOS menu bar app for streaming KEXP radio. Displays now playing info (show, song, artist, DJ comments, album art) and provides playback controls, AirPlay, and links to Spotify/Apple Music.

## Build & Run

Use the Justfile — no need to open Xcode.

```
just build          # debug build → build/output/debug/
just run            # debug build + launch
just build-release  # release build → build/output/release/
just release 1.0.0  # release build, zip, create GitHub release — suggest only, never run
just clean          # remove build/
just lsp-config     # regenerate buildServer.json for Zed/SourceKit-LSP (run after just build)
```

No external dependencies — everything uses Apple frameworks. There are no tests.

## Architecture

**Platform:** macOS, Swift, SwiftUI with AppKit bridging via `NSViewRepresentable`

**State management:** `@Observable` macro on model classes (`AudioPlayer`, `NowPlayingModel`), `@AppStorage` for persisted settings, `NotificationCenter` for cross-component events (playback state changes to menu bar icon).

**App entry:** `kexp_menubarApp.swift` — a `MenuBarExtra` with `.window` style. Switches between `ContentView` (full) and `CompactContentView` based on user preference.

### Key components

| File | Role |
|---|---|
| `AudioPlayer.swift` | AVPlayer wrapper. Streams `kexp160.aac`. Soft-pause (mute but keep connection alive), auto-reconnect, MPRemoteCommandCenter integration, Now Playing info publishing. |
| `NowPlayingModel.swift` | Polls `api.kexp.org/v2/plays/` for current song/show. 1s when window visible, 3s in background. Fetches show details on show change only. |
| `ContentView.swift` | Full layout. Also contains `CommentTextView` (NSTextView with URL detection) and `CommentView` (collapsible). |
| `CompactContentView.swift` | Minimal layout — small album art beside song info, no comments. |
| `ContentViewCommon.swift` | Shared views: `HeaderView`, `AlbumArtView` (with retry logic), `KEXPWindowModifier` (window setup, keyboard shortcuts, polling lifecycle). |
| `ControlsView.swift` | Play/pause button, Apple Music/Spotify links, AirPlay picker. |
| `SettingsMenu.swift` | NSButton + NSMenu. Volume slider, compact mode, reconnect, location, auto-reconnect interval, quit. |
| `AirPlayButton.swift` | Wraps `AVRoutePickerView`. |
| `Theme.swift` | Colors (`kexpOrange` #FBAD18, `kexpBackground` #231F20) and `AppDefaults`. |

### Notable patterns

- **Soft pause:** Pausing mutes the player but keeps the stream alive to avoid KEXP's welcome message on reconnect. After a configurable timeout, the next resume does a full reconnect.
- **NSViewRepresentable bridging:** Used for `SettingsMenu` (NSButton/NSMenu), `AirPlayButton` (AVRoutePickerView), and `CommentTextView` (NSTextView) where SwiftUI lacks native equivalents.
- **`allowsExternalPlayback = false`:** Forces local audio rendering so AirPlay routes the app's audio output rather than handing off the stream URL to the remote device.
- **Stale response guarding:** Show fetches check `currentShowUri` hasn't changed before applying results.

## Code style

- No third-party dependencies
- Debug logging uses `print("[Tag] message")` (e.g. `[NowPlaying]`, `[AlbumArt]`)
- Views suffixed with `View`, models with `Model`
- Prefer `guard` for early returns
- `[weak self]` in closures, `DispatchQueue.main.async` for UI updates from background tasks
- Keep files focused — one major component per file
