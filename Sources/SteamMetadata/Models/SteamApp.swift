//
//  SteamApp.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A Steam store app (game, DLC, demo, soundtrack…) with its full detail record.
///
/// Fetched from the keyless app-details endpoint via
/// ``SteamMetadata/app(_:country:configuration:)``. Fields that Steam omits for
/// a given app are optional: free games carry no ``price``, and not every title
/// has a ``metacriticScore`` or ``recommendationsTotal``.
public struct SteamApp: Sendable, Identifiable {

    // MARK: - Identity

    /// The Steam app ID (`steam_appid`).
    public let id: Int

    /// The store type, e.g. `"game"`, `"dlc"`, `"demo"`, `"music"`.
    public let type: String

    /// The app's display name.
    public let name: String

    // MARK: - Descriptions

    /// A one-line summary suitable for lists.
    public let shortDescription: String

    /// The full store description (may contain HTML markup).
    public let detailedDescription: String?

    // MARK: - Pricing & availability

    /// Whether the app is free-to-play.
    public let isFree: Bool

    /// The current price, or `nil` for free or unreleased apps.
    public let price: SteamPrice?

    /// The human-readable release date, e.g. `"Apr 18, 2011"`.
    public let releaseDate: String?

    /// Whether the app has not yet been released.
    public let comingSoon: Bool

    // MARK: - People

    /// The developer studio(s).
    public let developers: [String]

    /// The publisher(s).
    public let publishers: [String]

    // MARK: - Classification

    /// The store genres, e.g. `["Action", "Adventure"]`.
    public let genres: [String]

    /// The store categories/features, e.g. `["Single-player", "Co-op"]`.
    public let categories: [String]

    // MARK: - Platforms

    /// Whether a Windows build is available.
    public let windows: Bool

    /// Whether a macOS build is available.
    public let mac: Bool

    /// Whether a Linux build is available.
    public let linux: Bool

    // MARK: - Ratings & media

    /// The Metacritic score (`0...100`), when Steam provides one.
    public let metacriticScore: Int?

    /// The Metacritic review page URL, when available.
    public let metacriticURL: String?

    /// The total number of user recommendations (positive votes), when available.
    public let recommendationsTotal: Int?

    /// The store header image URL (the wide capsule shown at the top of a page).
    public let headerImageURL: String?

    /// The official website URL, when the developer supplied one.
    public let website: String?

    /// Full-resolution screenshot URLs.
    public let screenshots: [String]

    public init(
        id: Int,
        type: String,
        name: String,
        shortDescription: String,
        detailedDescription: String?,
        isFree: Bool,
        price: SteamPrice?,
        releaseDate: String?,
        comingSoon: Bool,
        developers: [String],
        publishers: [String],
        genres: [String],
        categories: [String],
        windows: Bool,
        mac: Bool,
        linux: Bool,
        metacriticScore: Int?,
        metacriticURL: String?,
        recommendationsTotal: Int?,
        headerImageURL: String?,
        website: String?,
        screenshots: [String]
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.shortDescription = shortDescription
        self.detailedDescription = detailedDescription
        self.isFree = isFree
        self.price = price
        self.releaseDate = releaseDate
        self.comingSoon = comingSoon
        self.developers = developers
        self.publishers = publishers
        self.genres = genres
        self.categories = categories
        self.windows = windows
        self.mac = mac
        self.linux = linux
        self.metacriticScore = metacriticScore
        self.metacriticURL = metacriticURL
        self.recommendationsTotal = recommendationsTotal
        self.headerImageURL = headerImageURL
        self.website = website
        self.screenshots = screenshots
    }
}
