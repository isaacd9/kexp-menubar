//
//  NowPlayingModel.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import Foundation

struct PlayResult: Codable, Sendable {
    let results: [Play]
}

struct Play: Codable, Sendable {
    let song: String?
    let artist: String?
    let album: String?
    let thumbnailUri: String?
    let comment: String?
    let showUri: String?
    let releaseDate: String?
    let playType: String?

    enum CodingKeys: String, CodingKey {
        case song, artist, album, comment
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

struct RecentSong: Sendable {
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
    private var location: Int = 1
    private var timer: Timer?
    private var currentShowUri: String?

    func setLocation(_ newLocation: Int) {
        let clamped = max(1, min(3, newLocation))
        guard location != clamped else { return }
        location = clamped
        currentShowUri = nil
        fetch()
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
        var components = URLComponents(string: "https://api.kexp.org/v2/plays/")
        components?.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "location", value: String(location)),
        ]
        guard let url = components?.url else { return }
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
                self.recentSongs = result.results
                    .compactMap { play in
                        let isAirbreak = play.playType == "airbreak"
                        let songTitle = isAirbreak ? "Airbreak" : (play.song ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        return RecentSong(
                            isAirbreak: isAirbreak,
                            song: songTitle,
                            artist: isAirbreak ? "" : (play.artist ?? ""),
                            album: isAirbreak ? "" : (play.album ?? ""),
                            releaseYear: isAirbreak ? "" : self.releaseYear(from: play.releaseDate),
                            comment: play.comment ?? "",
                            thumbnailURL: isAirbreak ? nil : play.thumbnailUri.flatMap(URL.init(string:))
                        )
                    }
                    .prefix(5)
                    .map { $0 }

                self.isAirbreak = play.playType == "airbreak"
                self.song = self.isAirbreak ? "Airbreak" : (play.song ?? "")
                self.artist = self.isAirbreak ? "" : (play.artist ?? "")
                self.album = self.isAirbreak ? "" : (play.album ?? "")
                self.releaseYear = self.isAirbreak ? "" : self.releaseYear(from: play.releaseDate)
                self.comment = play.comment ?? ""
                let oldThumb = self.thumbnailURL
                if let thumb = play.thumbnailUri, let thumbURL = URL(string: thumb) {
                    self.thumbnailURL = thumbURL
                } else {
                    self.thumbnailURL = nil
                }
                if self.thumbnailURL != oldThumb {
                    print("[NowPlaying] thumbnailURL changed: \(oldThumb?.absoluteString ?? "nil") -> \(self.thumbnailURL?.absoluteString ?? "nil")")
                }
                if let showUri = play.showUri, let showURL = URL(string: showUri) {
                    self.showURL = showURL
                } else {
                    self.showURL = nil
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
                self.programName = show.programName ?? ""
                self.hostNames = show.hostNames?.joined(separator: " and ") ?? ""
                if let imageUri = show.imageUri, let imageURL = URL(string: imageUri) {
                    self.hostImageURL = imageURL
                } else {
                    self.hostImageURL = nil
                }
            }
        }.resume()
    }
}
