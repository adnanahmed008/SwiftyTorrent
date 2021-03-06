//
//  EZTVDataProvider.swift
//  SwiftyTorrent
//
//  Created by Danylo Kostyshyn on 30.06.2020.
//  Copyright © 2020 Danylo Kostyshyn. All rights reserved.
//

import Foundation
import Combine

protocol SearchDataItem {
    
    var title: String { get }
    var sizeBytes: UInt64 { get }
    var size: String { get }
    var status: String { get }
    var magnetURL: URL { get }
    
}

extension EZTVDataProvider.Response.Torrent: SearchDataItem {
    
    private static var byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter
    }()

    var size: String {
        return EZTVDataProvider.Response.Torrent.byteCountFormatter.string(fromByteCount: Int64(sizeBytes))
    }

    var status: String {
        return "seeds: \(seeds), peers: \(peers)"
    }
    
}

final class EZTVDataProvider {
    
    static let shared = EZTVDataProvider()
    
    private let urlSession: URLSession = URLSession.shared
    private let endpointURL = URL(string: "https://eztv.io/api/")!
    
    func fetchTorrents(imdbId: String, limit: Int = 100, page: Int = 1) -> AnyPublisher<[SearchDataItem], Error> {
        let requestURL = URL(string: endpointURL.absoluteString +
            "get-torrents?limit=\(limit)&page=\(page)&imdb_id=\(imdbId)"
            )!
        return urlSession
            .dataTaskPublisher(for: requestURL)
            .tryMap({ data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                }
                return data
            })
            .decode(type: Response.self, decoder: JSONDecoder())
            .map({ (response) -> [SearchDataItem] in
                print("torrentsCount: \(response.torrentsCount)")
                return response.torrents
            })
            .eraseToAnyPublisher()
    }
}

extension EZTVDataProvider {
    
    struct Response: Decodable {
        
        //swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case imdbId = "imdb_id"
            case torrentsCount = "torrents_count"
            case limit
            case page
            case torrents
        }
        
        let imdbId: String
        let torrentsCount: Int
        let limit: Int
        let page: Int
        let torrents: [Torrent]
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            imdbId = try values.decode(String.self, forKey: .imdbId)
            torrentsCount = try values.decode(Int.self, forKey: .torrentsCount)
            limit = try values.decode(Int.self, forKey: .limit)
            page = try values.decode(Int.self, forKey: .page)
            torrents = try values.decode([Torrent].self, forKey: .torrents)
        }
        
        //swiftlint:disable:next nesting
        struct Torrent: Decodable, CustomDebugStringConvertible {
            
            //swiftlint:disable:next nesting
            enum CodingKeys: String, CodingKey {
                case id
                case hash
                case fileName = "filename"
                case episodeURL = "episode_url"
                case torrentURL = "torrent_url"
                case magnetURL = "magnet_url"
                case title
                case imdbId = "imdb_id"
                case season
                case episode
                case smallThumb = "small_screenshot"
                case largeThumb = "large_screenshot"
                case seeds
                case peers
                case releaseDate = "date_released_unix"
                case sizeBytes = "size_bytes"
            }
            
//            let id: Int
//            let hash: String
//            let fileName: String
//            let episodeURL: URL
            let torrentURL: URL
            let magnetURL: URL
            let title: String
//            let imdbId: String
            let season: String
            let episode: String
//            let smallThumb: URL
//            let largeThumb: URL
            let seeds: Int
            let peers: Int
//            let releaseDate: TimeInterval
            let sizeBytes: UInt64
            
            var se: String {
                return String(format: "s%2de%2d", Int(season) ?? 0, Int(episode) ?? 0)
            }
            
            var debugDescription: String {
                return title
            }
            
            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                if let rawValue = try? values.decode(String.self, forKey: .torrentURL),
                    let encodedValue = rawValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                    let URL = URL(string: encodedValue) {
                    torrentURL = URL
                } else {
                    throw "Bad torrentURL"
                }
                magnetURL = try values.decode(URL.self, forKey: .magnetURL)
                title = try values.decode(String.self, forKey: .title)
                season = try values.decode(String.self, forKey: .season)
                episode = try values.decode(String.self, forKey: .episode)
                seeds = try values.decode(Int.self, forKey: .seeds)
                peers = try values.decode(Int.self, forKey: .peers)
                if let rawValue = try? values.decode(String.self, forKey: .sizeBytes),
                    let value = UInt64(rawValue) {
                    sizeBytes = value
                } else {
                    throw "Bad sizeBytes"
                }
            }
            
        }
    }
}
