//
//  NowPlayingModel.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import Foundation

struct PlayResult: Codable, Sendable {
    let next: String?
    let results: [Play]
}

struct Play: Codable, Sendable {
    let uri: String?
    let song: String?
    let artist: String?
    let album: String?
    let thumbnailUri: String?
    let comment: String?
    let showUri: String?
    let releaseDate: String?
    let playType: String?

    enum CodingKeys: String, CodingKey {
        case uri, song, artist, album, comment
        case thumbnailUri = "thumbnail_uri"
        case showUri = "show_uri"
        case releaseDate = "release_date"
        case playType = "play_type"
    }
}

struct Show: Codable, Sendable {
    let programName: String?
    let hostNames: [String]?
    let imageUri: String?

    enum CodingKeys: String, CodingKey {
        case programName = "program_name"
        case hostNames = "host_names"
        case imageUri = "image_uri"
    }
}

struct RecentSong: Identifiable, Hashable, Sendable {
    let id: String
    let isAirbreak: Bool
    let song: String
    let artist: String
    let album: String
    let releaseYear: String
    let comment: String
    let thumbnailURL: URL?
}

@Observable
class NowPlayingModel {
    private let playlistInitialPageSize = 20
    private let playlistPageSize = 10
    var song: String = ""
    var artist: String = ""
    var album: String = ""
    var releaseYear: String = ""
    var comment: String = ""
    var isAirbreak: Bool = false
    var thumbnailURL: URL?
    var programName: String = ""
    var hostNames: String = ""
    var hostImageURL: URL?
    var showURL: URL?
    var recentSongs: [RecentSong] = []
    var isLoadingMoreRecentSongs = false
    var hasMoreRecentSongs = false
    private var location: Int = 1
    private var timer: Timer?
    private var currentShowUri: String?
    private var latestRecentSongs: [RecentSong] = []
    private var latestHasMoreRecentSongs = false
    private var nextRecentSongsOffset = 0
    private var isPlaylistActive = false

    func setLocation(_ newLocation: Int) {
        let clamped = max(1, min(3, newLocation))
        guard location != clamped else { return }
        location = clamped
        currentShowUri = nil
        resetPlaylistPagination(useLatestRecentSongs: false)
        fetch()
    }

    func setPlaylistActive(_ isActive: Bool) {
        guard isPlaylistActive != isActive else { return }
        isPlaylistActive = isActive
        resetPlaylistPagination(useLatestRecentSongs: true)
    }

    func loadMoreRecentSongsIfNeeded(currentSong: RecentSong) {
        guard isPlaylistActive,
              hasMoreRecentSongs,
              !isLoadingMoreRecentSongs,
              let triggerSongID = recentSongsLoadMoreTriggerSongID,
              currentSong.id == triggerSongID else { return }
        loadMoreRecentSongs()
    }

    func startPolling(interval: TimeInterval = 1.0) {
        stopPolling()
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.fetch()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func fetch() {
        guard let url = playsURL(limit: playlistInitialPageSize, offset: 0) else { return }
        print("[NowPlaying] Plays request: \(url.absoluteString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("[NowPlaying] Plays fetch error: \(error)")
                return
            }
            guard let data = data else { return }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("[NowPlaying] Plays response: status=\(statusCode), bytes=\(data.count)")
            guard let result = try? JSONDecoder().decode(PlayResult.self, from: data),
                  let play = result.results.first else {
                print("[NowPlaying] Plays decode failed or no results")
                return
            }

            DispatchQueue.main.async {
                let recentSongs = self.makeRecentSongs(from: result.results)
                self.latestRecentSongs = recentSongs
                self.latestHasMoreRecentSongs = result.next != nil

                if self.isPlaylistActive {
                    if self.recentSongs.isEmpty {
                        self.resetPlaylistPagination(useLatestRecentSongs: true)
                    }
                } else {
                    if self.recentSongs != recentSongs {
                        self.recentSongs = recentSongs
                    }
                    self.nextRecentSongsOffset = recentSongs.count
                    self.hasMoreRecentSongs = self.latestHasMoreRecentSongs
                }

                let isAirbreak = play.playType == "airbreak"
                let song = isAirbreak ? "Airbreak" : (play.song ?? "")
                let artist = isAirbreak ? "" : (play.artist ?? "")
                let album = isAirbreak ? "" : (play.album ?? "")
                let releaseYear = isAirbreak ? "" : self.releaseYear(from: play.releaseDate)
                let comment = play.comment ?? ""
                let thumbnailURL = play.thumbnailUri.flatMap(URL.init(string:))
                let showURL = play.showUri.flatMap(URL.init(string:))

                if self.isAirbreak != isAirbreak {
                    self.isAirbreak = isAirbreak
                }
                if self.song != song {
                    self.song = song
                }
                if self.artist != artist {
                    self.artist = artist
                }
                if self.album != album {
                    self.album = album
                }
                if self.releaseYear != releaseYear {
                    self.releaseYear = releaseYear
                }
                if self.comment != comment {
                    self.comment = comment
                }
                if self.thumbnailURL != thumbnailURL {
                    print("[NowPlaying] thumbnailURL changed: \(self.thumbnailURL?.absoluteString ?? "nil") -> \(thumbnailURL?.absoluteString ?? "nil")")
                    self.thumbnailURL = thumbnailURL
                }
                if self.showURL != showURL {
                    self.showURL = showURL
                }

                // Fetch show info only when the show changes.
                // Keep this on the main queue so polling responses cannot race each other.
                if let showUri = play.showUri, showUri != self.currentShowUri {
                    self.currentShowUri = showUri
                    self.fetchShow(uri: showUri)
                }
            }
        }.resume()
    }

    private func releaseYear(from releaseDate: String?) -> String {
        String(releaseDate?.prefix(4) ?? "")
    }

    private func makeRecentSongs(from plays: [Play]) -> [RecentSong] {
        var seenSongIDs: [String: Int] = [:]

        return plays.map { play in
            let isAirbreak = play.playType == "airbreak"
            let songTitle = isAirbreak ? "Airbreak" : (play.song ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let baseID = play.uri ?? [
                play.playType ?? "",
                play.song ?? "",
                play.artist ?? "",
                play.album ?? "",
                play.releaseDate ?? "",
                play.comment ?? "",
                play.thumbnailUri ?? "",
            ].joined(separator: "|")
            let occurrence = seenSongIDs[baseID, default: 0]
            seenSongIDs[baseID] = occurrence + 1
            let songID = occurrence == 0 ? baseID : "\(baseID)#\(occurrence)"

            return RecentSong(
                id: songID,
                isAirbreak: isAirbreak,
                song: songTitle,
                artist: isAirbreak ? "" : (play.artist ?? ""),
                album: isAirbreak ? "" : (play.album ?? ""),
                releaseYear: isAirbreak ? "" : releaseYear(from: play.releaseDate),
                comment: play.comment ?? "",
                thumbnailURL: isAirbreak ? nil : play.thumbnailUri.flatMap(URL.init(string:))
            )
        }
    }

    private var recentSongsLoadMoreTriggerSongID: RecentSong.ID? {
        recentSongs.last?.id
    }

    private func resetPlaylistPagination(useLatestRecentSongs: Bool) {
        isLoadingMoreRecentSongs = false
        nextRecentSongsOffset = latestRecentSongs.count
        hasMoreRecentSongs = latestHasMoreRecentSongs
        if useLatestRecentSongs {
            recentSongs = latestRecentSongs
        } else {
            recentSongs = []
        }
    }

    private func loadMoreRecentSongs() {
        guard !isLoadingMoreRecentSongs,
              hasMoreRecentSongs,
              let url = playsURL(limit: playlistPageSize, offset: nextRecentSongsOffset) else { return }
        isLoadingMoreRecentSongs = true
        print("[NowPlaying] Load more plays request: \(url.absoluteString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("[NowPlaying] Load more plays error: \(error)")
                DispatchQueue.main.async {
                    self.isLoadingMoreRecentSongs = false
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoadingMoreRecentSongs = false
                }
                return
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("[NowPlaying] Load more plays response: status=\(statusCode), bytes=\(data.count)")
            guard let result = try? JSONDecoder().decode(PlayResult.self, from: data) else {
                print("[NowPlaying] Load more plays decode failed")
                DispatchQueue.main.async {
                    self.isLoadingMoreRecentSongs = false
                }
                return
            }

            let newSongs = self.makeRecentSongs(from: result.results)
            DispatchQueue.main.async {
                self.recentSongs = self.mergedRecentSongs(existing: self.recentSongs, additional: newSongs)
                self.nextRecentSongsOffset += result.results.count
                self.hasMoreRecentSongs = result.next != nil
                self.isLoadingMoreRecentSongs = false
            }
        }.resume()
    }

    private func mergedRecentSongs(existing: [RecentSong], additional: [RecentSong]) -> [RecentSong] {
        var merged: [RecentSong] = []
        var seenSongIDs = Set<RecentSong.ID>()

        for song in existing + additional {
            if seenSongIDs.insert(song.id).inserted {
                merged.append(song)
            }
        }

        return merged
    }

    private func playsURL(limit: Int, offset: Int) -> URL? {
        var components = URLComponents(string: "https://api.kexp.org/v2/plays/")
        components?.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "location", value: String(location)),
        ]
        return components?.url
    }

    private func fetchShow(uri: String) {
        guard let url = URL(string: uri) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("[NowPlaying] Show fetch error: \(error)")
                return
            }
            guard let data = data else { return }
            guard let show = try? JSONDecoder().decode(Show.self, from: data) else { return }

            DispatchQueue.main.async {
                guard self.currentShowUri == uri else {
                    print("[NowPlaying] Ignoring stale show response for \(uri)")
                    return
                }
                let programName = show.programName ?? ""
                let hostNames = show.hostNames?.joined(separator: " and ") ?? ""
                let hostImageURL = show.imageUri.flatMap(URL.init(string:))

                if self.programName != programName {
                    self.programName = programName
                }
                if self.hostNames != hostNames {
                    self.hostNames = hostNames
                }
                if self.hostImageURL != hostImageURL {
                    self.hostImageURL = hostImageURL
                }
            }
        }.resume()
    }
}
