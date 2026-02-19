# KEXP Menubar

<img width="377" height="592" alt="Screenshot 2026-02-18 at 9 14 02 PM" src="https://github.com/user-attachments/assets/8ca0dc83-870f-42eb-8048-0f4f9b176988" />

This is an unofficial MacOS app for the [KEXP](https://www.kexp.org/) Radio
Station. It sits in the menu bar of MacOS and provides a way to stream the
station's music, view the currently playing show, song, and artist information,
and the DJ's comments.

There's already an iOS app available for KEXP, but this MacOS app offers
provides direct integration with your Mac's menu bar, making the experience
somewhat less obtrusive. It also implements some features not implemented in the
iOS app (which this derives a bunch of icons from) but uses SwiftUI for higher
performance and better user experience.

## Features
- Full display of show, song, and artist information as well as an expandable DJ comment.
- Soft pauses for the stream, to prevent the welcome message from interrupting
  the music when only pausing the stream briefly. The stream will automatically
  reconnect if it has been paused for a long time and the buffer goes stale.
- Airplay support for streaming to your AirPlay devices.
- Links to open the current song in Spotify, and Apple Music.
- Selectable location for show information, to indicate if you're listening to KEXP (Seattle), or KEXC (San Francisco).
- A compact mode, which hides the DJ comment and show information.
