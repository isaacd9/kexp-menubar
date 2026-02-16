//
//  NowPlayingModel.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import Foundation

nonisolated struct PlayResult: Codable, Sendable {
    let results: [Play]
}

nonisolated struct Play: Codable, Sendable {
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

nonisolated struct Show: Codable, Sendable {
    let programName: String?
    let hostNames: [String]?

    enum CodingKeys: String, CodingKey {
        case programName = "program_name"
        case hostNames = "host_names"
    }
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
    private var timer: Timer?
    private var currentShowUri: String?

    func startPolling() {
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.fetch()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func fetch() {
        guard let url = URL(string: "https://api.kexp.org/v2/plays/?format=json&limit=1") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("[NowPlaying] Plays fetch error: \(error)")
                return
            }
            guard let data = data else { return }
            guard let result = try? JSONDecoder().decode(PlayResult.self, from: data),
                  let play = result.results.first else { return }

            DispatchQueue.main.async {
                self.isAirbreak = play.playType == "airbreak"
                self.song = self.isAirbreak ? "Airbreak" : (play.song ?? "")
                self.artist = self.isAirbreak ? "" : (play.artist ?? "")
                self.album = self.isAirbreak ? "" : (play.album ?? "")
                self.releaseYear = self.isAirbreak ? "" : String(play.releaseDate?.prefix(4) ?? "")
                self.comment = play.comment ?? ""
                if let thumb = play.thumbnailUri, let thumbURL = URL(string: thumb) {
                    self.thumbnailURL = thumbURL
                } else {
                    self.thumbnailURL = nil
                }
            }

            // Fetch show info if the show changed
            if let showUri = play.showUri, showUri != self.currentShowUri {
                self.currentShowUri = showUri
                self.fetchShow(uri: showUri)
            }
        }.resume()
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
                self.programName = show.programName ?? ""
                self.hostNames = show.hostNames?.joined(separator: ", ") ?? ""
            }
        }.resume()
    }
}
