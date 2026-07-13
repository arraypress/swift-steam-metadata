//
//  SteamMetadata.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Fetch Steam store metadata, user reviews, and search results — **without an
/// API key**.
///
/// Backed by Steam's public store endpoints (`https://store.steampowered.com`),
/// which need no authentication or Web API key:
///
/// - **App details** (`/api/appdetails`) → a full ``SteamApp`` record.
/// - **User reviews** (`/appreviews`) → a cursor-paginated ``SteamReviewsPage``.
/// - **Store search** (`/api/storesearch`) → lightweight ``SteamSearchResult``s.
///
/// Everything you need to identify a title is an app ID (an integer like `620`
/// for Portal 2). Search by name to discover the ID, then fetch its details and
/// reviews.
///
/// ## Quick Start
///
/// ```swift
/// import SteamMetadata
///
/// // 1. Search the store to discover an app ID
/// let hits = try await SteamMetadata.search("portal 2")
/// guard let hit = hits.first else { return }
/// print("\(hit.name) — appID \(hit.id)")
///
/// // 2. Fetch the full detail record
/// let app = try await SteamMetadata.app(hit.id)
/// print("\(app.name) by \(app.developers.joined(separator: ", "))")
/// print("Genres: \(app.genres.joined(separator: ", "))")
/// if let price = app.price {
///     print("Price: \(price.finalFormatted ?? "\(price.finalDollars) \(price.currency)")")
/// } else if app.isFree {
///     print("Free to play")
/// }
/// print("Metacritic: \(app.metacriticScore ?? 0)")
///
/// // 3. Fetch user reviews (paginated)
/// let page = try await SteamMetadata.reviews(appID: app.id, filter: .recent)
/// print("Overall: \(page.summary.reviewScoreDesc) "
///       + "(\(page.summary.totalPositive) positive / \(page.summary.totalNegative) negative)")
/// for review in page.reviews.prefix(3) {
///     let thumb = review.votedUp ? "👍" : "👎"
///     print("\(thumb) \(review.body.prefix(80))")
/// }
///
/// // 4. Page forward with the returned cursor
/// if let cursor = page.cursor {
///     let next = try await SteamMetadata.reviews(appID: app.id, filter: .recent, cursor: cursor)
///     print("Next page: \(next.reviews.count) more reviews")
/// }
/// ```
///
/// ## Storefront
///
/// Pass a `country:` (ISO alpha-2, e.g. `"us"`, `"gb"`) to app details and
/// search to control pricing and currency. It defaults to
/// ``Configuration/default`` (the `STEAM_COUNTRY` environment variable, or
/// `"us"`).
public enum SteamMetadata {

    // MARK: - Configuration

    /// Options for talking to the Steam store endpoints.
    public struct Configuration: Sendable {

        /// The storefront country code (ISO alpha-2, e.g. `"us"`, `"gb"`).
        /// Determines pricing and currency.
        public var country: String

        /// Creates a configuration.
        ///
        /// - Parameter country: The storefront country code. Defaults to `"us"`.
        public init(country: String = "us") {
            self.country = country
        }

        /// Reads `STEAM_COUNTRY` from the environment, defaulting to `"us"`.
        public static var `default`: Configuration {
            Configuration(country: ProcessInfo.processInfo.environment["STEAM_COUNTRY"] ?? "us")
        }
    }

    // MARK: - App details

    /// Fetches the full store detail record for an app.
    ///
    /// ```swift
    /// let app = try await SteamMetadata.app(620) // Portal 2
    /// print(app.name, app.metacriticScore ?? 0)
    /// ```
    ///
    /// - Parameters:
    ///   - appID: The Steam app ID (e.g. `620` for Portal 2).
    ///   - country: The storefront country code. Defaults to `configuration`.
    ///   - configuration: Storefront options. Defaults to ``Configuration/default``.
    /// - Returns: The app's ``SteamApp`` detail record.
    /// - Throws: ``SteamMetadataError/notFound`` if the app ID is unknown or has
    ///   no store page; other ``SteamMetadataError`` cases on network/parse errors.
    public static func app(
        _ appID: Int,
        country: String? = nil,
        configuration: Configuration = .default
    ) async throws -> SteamApp {
        guard appID > 0 else { throw SteamMetadataError.invalidInput }

        let items = [
            URLQueryItem(name: "appids", value: String(appID)),
            URLQueryItem(name: "cc", value: country ?? configuration.country),
            URLQueryItem(name: "l", value: "english")
        ]
        let json = try await SteamClient.get(path: "/api/appdetails", queryItems: items)

        // The response is keyed by the app ID string; `data` is absent when
        // `success` is false (unknown ID, region-locked, or delisted).
        guard let envelope = json[String(appID)] as? [String: Any] else {
            throw SteamMetadataError.parsingError("Missing app envelope")
        }
        guard isSuccess(envelope["success"]), let data = envelope["data"] as? [String: Any] else {
            throw SteamMetadataError.notFound
        }
        return SteamParser.app(data)
    }

    // MARK: - Reviews

    /// Fetches one page of user reviews for an app.
    ///
    /// Reviews are cursor-paginated: pass the returned ``SteamReviewsPage/cursor``
    /// back in as `cursor:` to fetch the next page.
    ///
    /// ```swift
    /// var cursor = "*"
    /// for _ in 0..<3 { // fetch three pages
    ///     let page = try await SteamMetadata.reviews(appID: 620, cursor: cursor)
    ///     for r in page.reviews { print(r.votedUp ? "👍" : "👎", r.body.prefix(60)) }
    ///     guard let next = page.cursor, next != cursor else { break }
    ///     cursor = next
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - appID: The Steam app ID.
    ///   - filter: Review ordering. Defaults to ``SteamReviewFilter/recent``.
    ///   - language: The review language (e.g. `"english"`), or `"all"` for every
    ///     language. Defaults to `"all"`.
    ///   - cursor: The pagination cursor. Start with `"*"` (the default) and pass
    ///     the previous page's ``SteamReviewsPage/cursor`` for subsequent pages.
    ///   - numPerPage: The number of reviews per page (`1...100`). Defaults to `20`.
    ///   - configuration: Storefront options. Defaults to ``Configuration/default``.
    /// - Returns: A ``SteamReviewsPage`` with the summary, reviews, and next cursor.
    public static func reviews(
        appID: Int,
        filter: SteamReviewFilter = .recent,
        language: String = "all",
        cursor: String = "*",
        numPerPage: Int = 20,
        configuration: Configuration = .default
    ) async throws -> SteamReviewsPage {
        guard appID > 0 else { throw SteamMetadataError.invalidInput }

        let items = [
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "filter", value: filter.rawValue),
            URLQueryItem(name: "language", value: language.isEmpty ? "all" : language),
            URLQueryItem(name: "num_per_page", value: String(min(max(numPerPage, 1), 100))),
            URLQueryItem(name: "cursor", value: cursor.isEmpty ? "*" : cursor)
        ]
        let json = try await SteamClient.get(path: "/appreviews/\(appID)", queryItems: items)

        guard isSuccess(json["success"]) else {
            throw SteamMetadataError.notFound
        }
        return SteamParser.reviewsPage(json)
    }

    // MARK: - Search

    /// Searches the Steam store by name.
    ///
    /// ```swift
    /// let results = try await SteamMetadata.search("cyberpunk")
    /// for r in results { print("\(r.name) — appID \(r.id)") }
    /// ```
    ///
    /// - Parameters:
    ///   - query: The free-text search term (URL-encoding is handled for you).
    ///   - country: The storefront country code. Defaults to `configuration`.
    ///   - configuration: Storefront options. Defaults to ``Configuration/default``.
    /// - Returns: The matching ``SteamSearchResult``s (empty if nothing matched).
    /// - Throws: ``SteamMetadataError/invalidInput`` on an empty query; other
    ///   ``SteamMetadataError`` cases on network/parse errors.
    public static func search(
        _ query: String,
        country: String? = nil,
        configuration: Configuration = .default
    ) async throws -> [SteamSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SteamMetadataError.invalidInput
        }

        let items = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "cc", value: country ?? configuration.country),
            URLQueryItem(name: "l", value: "english")
        ]
        let json = try await SteamClient.get(path: "/api/storesearch/", queryItems: items)
        return SteamParser.searchResults(json)
    }

    // MARK: - Helpers

    /// Steam reports success as a JSON `true`/`false` (app details) or `1`/`0`
    /// integer (reviews); accept either.
    private static func isSuccess(_ value: Any?) -> Bool {
        if let b = value as? Bool { return b }
        if let i = value as? Int { return i == 1 }
        return false
    }
}
