# KEXP Menubar

<img width="377" height="592" alt="Screenshot 2026-02-18 at 9 14 02 PM" src="https://github.com/user-attachments/assets/8ca0dc83-870f-42eb-8048-0f4f9b176988" />

This is an unofficial macOS app for the [KEXP](https://www.kexp.org/) radio
station. It sits in the menu bar and provides a way to stream the station's
music, view the currently playing show, song, and artist information, and the
DJ's comments.

There's already an iOS app available for KEXP, but this macOS app provides
direct integration with your Mac's menu bar, making the experience somewhat
less obtrusive. It also includes a few features not found in the iOS app, and
targets macOS specifically for a better native feel.

## Installation

Download the latest release from the [releases page](https://github.com/isaacd9/kexp-menubar/releases)
and move it to `/Applications`. Because the app is not notarized, macOS will
quarantine it. To remove the quarantine flag, run:

```
xattr -dr com.apple.quarantine /Applications/kexp-menubar.app
```

## Features
- Full display of show, song, and artist information as well as an expandable DJ comment.
- Soft pauses for the stream, to prevent the welcome message from interrupting
  the music when only pausing the stream briefly. The stream will automatically
  reconnect if it has been paused for a long time and the buffer goes stale.
- AirPlay support for streaming to your AirPlay devices.
- Links to open the current song in Spotify and Apple Music.
- Selectable location for show information, to indicate if you're listening to KEXP (Seattle) or KEXC (San Francisco).
- A compact mode, which hides the DJ comment and show information.

## Disclaimer

All images and branding are borrowed from the [official KEXP mobile app](https://www.kexp.org/mobile/). This is an unofficial project with no affiliation with KEXP.
