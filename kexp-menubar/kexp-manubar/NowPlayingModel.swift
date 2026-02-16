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

    enum CodingKeys: String, CodingKey {
        case song, artist, album, comment
        case thumbnailUri = "thumbnail_uri"
        case showUri = "show_uri"
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
    var comment: String = ""
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
            guard let data = data, error == nil else { return }
            guard let result = try? JSONDecoder().decode(PlayResult.self, from: data),
                  let play = result.results.first else { return }

            DispatchQueue.main.async {
                self.song = play.song ?? ""
                self.artist = play.artist ?? ""
                self.album = play.album ?? ""
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
            guard let data = data, error == nil else { return }
            guard let show = try? JSONDecoder().decode(Show.self, from: data) else { return }

            DispatchQueue.main.async {
                self.programName = show.programName ?? ""
                self.hostNames = show.hostNames?.joined(separator: ", ") ?? ""
            }
        }.resume()
    }
}
