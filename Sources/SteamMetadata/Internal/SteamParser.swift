//
//  SteamParser.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses Steam store API response objects into typed models.
enum SteamParser {

    // MARK: - App details

    /// Parses an app-details `data` object into a ``SteamApp``.
    ///
    /// Expects the inner `data` dictionary — the caller is responsible for
    /// unwrapping the id-keyed `{ success, data }` envelope first.
    static func app(_ d: [String: Any]) -> SteamApp {
        let platforms = d["platforms"] as? [String: Any] ?? [:]
        let releaseDate = d["release_date"] as? [String: Any] ?? [:]
        let metacritic = d["metacritic"] as? [String: Any]
        let recommendations = d["recommendations"] as? [String: Any]

        return SteamApp(
            id: intValue(d["steam_appid"]) ?? 0,
            type: nonEmpty(d["type"]) ?? "",
            name: nonEmpty(d["name"]) ?? "",
            shortDescription: nonEmpty(d["short_description"]) ?? "",
            detailedDescription: nonEmpty(d["detailed_description"]),
            isFree: boolValue(d["is_free"]) ?? false,
            price: price(d["price_overview"]),
            releaseDate: nonEmpty(releaseDate["date"]),
            comingSoon: boolValue(releaseDate["coming_soon"]) ?? false,
            developers: stringList(d["developers"]),
            publishers: stringList(d["publishers"]),
            genres: descriptions(d["genres"]),
            categories: descriptions(d["categories"]),
            windows: boolValue(platforms["windows"]) ?? false,
            mac: boolValue(platforms["mac"]) ?? false,
            linux: boolValue(platforms["linux"]) ?? false,
            metacriticScore: intValue(metacritic?["score"]),
            metacriticURL: nonEmpty(metacritic?["url"]),
            recommendationsTotal: intValue(recommendations?["total"]),
            headerImageURL: nonEmpty(d["header_image"]),
            website: nonEmpty(d["website"]),
            screenshots: (d["screenshots"] as? [[String: Any]] ?? []).compactMap { nonEmpty($0["path_full"]) }
        )
    }

    // MARK: - Reviews

    /// Parses a reviews response (`{ query_summary, reviews, cursor }`).
    static func reviewsPage(_ d: [String: Any]) -> SteamReviewsPage {
        let summaryDict = d["query_summary"] as? [String: Any] ?? [:]
        let summary = SteamReviewSummary(
            numReviews: intValue(summaryDict["num_reviews"]) ?? 0,
            reviewScore: intValue(summaryDict["review_score"]) ?? 0,
            reviewScoreDesc: nonEmpty(summaryDict["review_score_desc"]) ?? "",
            totalPositive: intValue(summaryDict["total_positive"]) ?? 0,
            totalNegative: intValue(summaryDict["total_negative"]) ?? 0,
            totalReviews: intValue(summaryDict["total_reviews"]) ?? 0
        )

        let reviews = (d["reviews"] as? [[String: Any]] ?? []).map(review)

        return SteamReviewsPage(
            summary: summary,
            reviews: reviews,
            cursor: nonEmpty(d["cursor"])
        )
    }

    /// Parses a single review object.
    static func review(_ d: [String: Any]) -> SteamReview {
        let author = d["author"] as? [String: Any] ?? [:]
        return SteamReview(
            id: nonEmpty(d["recommendationid"]) ?? "",
            body: nonEmpty(d["review"]) ?? "",
            votedUp: boolValue(d["voted_up"]) ?? false,
            votesUp: intValue(d["votes_up"]) ?? 0,
            votesFunny: intValue(d["votes_funny"]) ?? 0,
            language: nonEmpty(d["language"]),
            authorSteamID: nonEmpty(author["steamid"]),
            authorPlaytimeForever: intValue(author["playtime_forever"]),
            authorPlaytimeAtReview: intValue(author["playtime_at_review"]),
            authorGamesOwned: intValue(author["num_games_owned"]),
            created: epochDate(d["timestamp_created"]),
            updated: epochDate(d["timestamp_updated"])
        )
    }

    // MARK: - Search

    /// Parses a store-search response (`{ total, items }`).
    static func searchResults(_ d: [String: Any]) -> [SteamSearchResult] {
        (d["items"] as? [[String: Any]] ?? []).map(searchResult)
    }

    /// Parses a single search item.
    static func searchResult(_ d: [String: Any]) -> SteamSearchResult {
        let platforms = d["platforms"] as? [String: Any] ?? [:]
        return SteamSearchResult(
            id: intValue(d["id"]) ?? 0,
            type: nonEmpty(d["type"]) ?? "",
            name: nonEmpty(d["name"]) ?? "",
            tinyImageURL: nonEmpty(d["tiny_image"]),
            price: price(d["price"]),
            metacriticScore: intValue(d["metascore"]),
            windows: boolValue(platforms["windows"]) ?? false,
            mac: boolValue(platforms["mac"]) ?? false,
            linux: boolValue(platforms["linux"]) ?? false
        )
    }

    // MARK: - Helpers

    /// Parses a price object (`price_overview` or a search item's `price`).
    private static func price(_ value: Any?) -> SteamPrice? {
        guard let d = value as? [String: Any],
              let currency = nonEmpty(d["currency"]),
              let final = intValue(d["final"]) else { return nil }
        return SteamPrice(
            currency: currency,
            initial: intValue(d["initial"]) ?? final,
            final: final,
            discountPercent: intValue(d["discount_percent"]) ?? 0,
            finalFormatted: nonEmpty(d["final_formatted"])
        )
    }

    /// The `description` field of each element in an array (genres/categories).
    private static func descriptions(_ value: Any?) -> [String] {
        (value as? [[String: Any]] ?? []).compactMap { nonEmpty($0["description"]) }
    }

    /// A plain string array (developers/publishers).
    private static func stringList(_ value: Any?) -> [String] {
        (value as? [String])?.filter { !$0.isEmpty } ?? []
    }

    /// Returns the string if non-empty, else `nil`. Accepts non-string values as `nil`.
    private static func nonEmpty(_ value: Any?) -> String? {
        guard let s = value as? String, !s.isEmpty else { return nil }
        return s
    }

    /// Parses a Unix epoch-seconds timestamp into a `Date`.
    private static func epochDate(_ value: Any?) -> Date? {
        guard let seconds = intValue(value), seconds > 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let s = value as? String { return Int(s) }
        return nil
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        if let b = value as? Bool { return b }
        if let i = value as? Int { return i != 0 }
        if let s = value as? String { return s == "true" || s == "1" }
        return nil
    }
}
