//
//  SteamMetadataTests.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import SteamMetadata

final class SteamMetadataTests: XCTestCase {

    // MARK: - Review filter raw values

    func testReviewFilterRawValuesMatchAPI() {
        XCTAssertEqual(SteamReviewFilter.recent.rawValue, "recent")
        XCTAssertEqual(SteamReviewFilter.updated.rawValue, "updated")
        XCTAssertEqual(SteamReviewFilter.all.rawValue, "all")
        XCTAssertEqual(SteamReviewFilter.allCases.count, 3)
    }

    // MARK: - App details parsing

    func testParseAppDetails() throws {
        let envelope = try json(Fixture.appDetails)
        let inner = try XCTUnwrap(envelope["620"] as? [String: Any])
        XCTAssertEqual(inner["success"] as? Bool, true)
        let data = try XCTUnwrap(inner["data"] as? [String: Any])

        let app = SteamParser.app(data)
        XCTAssertEqual(app.id, 620)
        XCTAssertEqual(app.type, "game")
        XCTAssertEqual(app.name, "Portal 2")
        XCTAssertFalse(app.isFree)
        XCTAssertEqual(app.shortDescription, "The Perpetual Testing Initiative has been expanded.")
        XCTAssertEqual(app.detailedDescription, "<h1>Portal 2</h1>")
        XCTAssertEqual(app.developers, ["Valve"])
        XCTAssertEqual(app.publishers, ["Valve"])
        XCTAssertEqual(app.genres, ["Action", "Adventure"])
        XCTAssertEqual(app.categories, ["Single-player", "Co-op"])
        XCTAssertEqual(app.releaseDate, "Apr 18, 2011")
        XCTAssertFalse(app.comingSoon)
        XCTAssertTrue(app.windows)
        XCTAssertFalse(app.mac)
        XCTAssertTrue(app.linux)
        XCTAssertEqual(app.metacriticScore, 95)
        XCTAssertEqual(app.metacriticURL, "https://www.metacritic.com/game/pc/portal-2")
        XCTAssertEqual(app.recommendationsTotal, 387204)
        XCTAssertEqual(app.headerImageURL, "https://example.com/header.jpg")
        XCTAssertEqual(app.website, "http://www.thinkwithportals.com/")
        XCTAssertEqual(app.screenshots, ["https://example.com/ss0.jpg", "https://example.com/ss1.jpg"])
    }

    func testParseAppPrice() throws {
        let inner = try XCTUnwrap(try json(Fixture.appDetails)["620"] as? [String: Any])
        let data = try XCTUnwrap(inner["data"] as? [String: Any])
        let price = try XCTUnwrap(SteamParser.app(data).price)
        XCTAssertEqual(price.currency, "USD")
        XCTAssertEqual(price.initial, 999)
        XCTAssertEqual(price.final, 999)
        XCTAssertEqual(price.discountPercent, 0)
        XCTAssertEqual(price.finalFormatted, "$9.99")
        XCTAssertEqual(price.finalDollars, 9.99, accuracy: 0.001)
        XCTAssertFalse(price.isDiscounted)
    }

    func testFreeAppHasNoPrice() throws {
        let app = SteamParser.app(try json(Fixture.freeAppData))
        XCTAssertTrue(app.isFree)
        XCTAssertNil(app.price)
        XCTAssertNil(app.metacriticScore)
        XCTAssertNil(app.recommendationsTotal)
        XCTAssertTrue(app.mac)
    }

    // MARK: - Reviews parsing

    func testParseReviews() throws {
        let page = SteamParser.reviewsPage(try json(Fixture.reviews))

        XCTAssertEqual(page.summary.numReviews, 2)
        XCTAssertEqual(page.summary.reviewScore, 9)
        XCTAssertEqual(page.summary.reviewScoreDesc, "Overwhelmingly Positive")
        XCTAssertEqual(page.summary.totalPositive, 382062)
        XCTAssertEqual(page.summary.totalNegative, 4943)
        XCTAssertEqual(page.summary.totalReviews, 387005)
        XCTAssertEqual(page.cursor, "AoJ4noGkrZ8DcOri7gY=")

        XCTAssertEqual(page.reviews.count, 2)
        let first = page.reviews[0]
        XCTAssertEqual(first.id, "230366409")
        XCTAssertEqual(first.body, "Best puzzle game ever made.")
        XCTAssertTrue(first.votedUp)
        XCTAssertEqual(first.votesUp, 12)
        XCTAssertEqual(first.votesFunny, 3)
        XCTAssertEqual(first.language, "english")
        XCTAssertEqual(first.authorSteamID, "76561199026156214")
        XCTAssertEqual(first.authorPlaytimeForever, 665)
        XCTAssertEqual(first.authorPlaytimeAtReview, 665)
        XCTAssertEqual(first.authorGamesOwned, 53)
        XCTAssertNotNil(first.created)
        XCTAssertNotNil(first.updated)

        XCTAssertFalse(page.reviews[1].votedUp)
    }

    // MARK: - Search parsing

    func testParseSearch() throws {
        let results = SteamParser.searchResults(try json(Fixture.search))
        XCTAssertEqual(results.count, 2)

        let paid = results[0]
        XCTAssertEqual(paid.id, 620)
        XCTAssertEqual(paid.type, "app")
        XCTAssertEqual(paid.name, "Portal 2")
        XCTAssertEqual(paid.tinyImageURL, "https://example.com/capsule.jpg")
        XCTAssertEqual(paid.metacriticScore, 95)
        XCTAssertTrue(paid.windows)
        XCTAssertFalse(paid.mac)
        XCTAssertTrue(paid.linux)
        let price = try XCTUnwrap(paid.price)
        XCTAssertEqual(price.currency, "USD")
        XCTAssertEqual(price.final, 999)
        // Search prices carry no discount or formatted string.
        XCTAssertNil(price.finalFormatted)

        // Free game: no price key.
        let free = results[1]
        XCTAssertEqual(free.id, 570)
        XCTAssertEqual(free.name, "Dota 2")
        XCTAssertNil(free.price)
        XCTAssertTrue(free.mac)
    }

    // MARK: - Input validation

    func testEmptySearchThrowsInvalidInput() async {
        do {
            _ = try await SteamMetadata.search("   ")
            XCTFail("Expected invalidInput")
        } catch SteamMetadataError.invalidInput {
            // expected
        } catch {
            XCTFail("Expected invalidInput, got \(error)")
        }
    }

    func testInvalidAppIDThrowsInvalidInput() async {
        do {
            _ = try await SteamMetadata.app(0)
            XCTFail("Expected invalidInput")
        } catch SteamMetadataError.invalidInput {
            // expected
        } catch {
            XCTFail("Expected invalidInput, got \(error)")
        }
    }

    // MARK: - Live tests (opt-in)

    /// Keyless live verification. Gated on network via `STEAM_LIVE_TESTS=1`.
    func testLiveAppReviewsAndSearch() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["STEAM_LIVE_TESTS"] == "1",
                          "Set STEAM_LIVE_TESTS=1 to run live network tests.")

        // Search → discover an app ID.
        let hits = try await SteamMetadata.search("portal 2")
        XCTAssertFalse(hits.isEmpty)
        let portal = try XCTUnwrap(hits.first { $0.id == 620 } ?? hits.first)

        // App details.
        let app = try await SteamMetadata.app(portal.id)
        XCTAssertEqual(app.id, portal.id)
        XCTAssertFalse(app.name.isEmpty)
        XCTAssertFalse(app.developers.isEmpty)

        // Reviews.
        let page = try await SteamMetadata.reviews(appID: app.id, filter: .recent)
        XCTAssertFalse(page.summary.reviewScoreDesc.isEmpty)
        XCTAssertFalse(page.reviews.isEmpty)
        XCTAssertNotNil(page.cursor)

        // Pagination — the next cursor should return a distinct page.
        if let cursor = page.cursor {
            let next = try await SteamMetadata.reviews(appID: app.id, filter: .recent, cursor: cursor)
            XCTAssertFalse(next.reviews.isEmpty)
            XCTAssertNotEqual(next.reviews.first?.id, page.reviews.first?.id)
        }

        if ProcessInfo.processInfo.environment["STEAM_PRINT"] == "1" {
            print("=== app ===")
            print("• \(app.name) by \(app.developers.joined(separator: ", ")) — Metacritic \(app.metacriticScore ?? 0)")
            print("  genres: \(app.genres.joined(separator: ", "))")
            print("  price: \(app.price?.finalFormatted ?? (app.isFree ? "Free" : "?"))")
            print("=== reviews ===")
            print("• score: \(page.summary.reviewScoreDesc) "
                  + "(\(page.summary.totalPositive) 👍 / \(page.summary.totalNegative) 👎)")
            for r in page.reviews.prefix(3) {
                print("  \(r.votedUp ? "👍" : "👎") \(r.body.replacingOccurrences(of: "\n", with: " ").prefix(70))")
            }
            print("=== search ===")
            for r in hits.prefix(4) {
                print("• #\(r.id) \(r.name) — Metacritic \(r.metacriticScore ?? 0)")
            }
        }
    }

    // MARK: - Helpers

    private func json(_ string: String) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(string.utf8)) as? [String: Any])
    }
}

// MARK: - Fixtures (mirror verified Steam store endpoint shapes)

private enum Fixture {

    /// An app-details envelope, keyed by the app ID string (`{ success, data }`).
    static let appDetails = """
    { "620": { "success": true, "data": {
        "type": "game", "name": "Portal 2", "steam_appid": 620, "is_free": false,
        "short_description": "The Perpetual Testing Initiative has been expanded.",
        "detailed_description": "<h1>Portal 2</h1>",
        "header_image": "https://example.com/header.jpg",
        "website": "http://www.thinkwithportals.com/",
        "developers": ["Valve"], "publishers": ["Valve"],
        "price_overview": { "currency": "USD", "initial": 999, "final": 999,
          "discount_percent": 0, "initial_formatted": "", "final_formatted": "$9.99" },
        "categories": [ { "id": 2, "description": "Single-player" },
                        { "id": 9, "description": "Co-op" } ],
        "genres": [ { "id": "1", "description": "Action" },
                    { "id": "25", "description": "Adventure" } ],
        "release_date": { "coming_soon": false, "date": "Apr 18, 2011" },
        "platforms": { "windows": true, "mac": false, "linux": true },
        "metacritic": { "score": 95, "url": "https://www.metacritic.com/game/pc/portal-2" },
        "recommendations": { "total": 387204 },
        "screenshots": [ { "id": 0, "path_thumbnail": "https://example.com/t0.jpg",
                           "path_full": "https://example.com/ss0.jpg" },
                         { "id": 1, "path_thumbnail": "https://example.com/t1.jpg",
                           "path_full": "https://example.com/ss1.jpg" } ]
    } } }
    """

    /// A free-to-play app's `data` object (no `price_overview`, no metacritic).
    static let freeAppData = """
    { "type": "game", "name": "Dota 2", "steam_appid": 570, "is_free": true,
      "short_description": "Every day, millions of players worldwide enter battle.",
      "developers": ["Valve"], "publishers": ["Valve"],
      "release_date": { "coming_soon": false, "date": "Jul 9, 2013" },
      "platforms": { "windows": true, "mac": true, "linux": true } }
    """

    /// A reviews response (`{ success, query_summary, reviews, cursor }`).
    static let reviews = """
    { "success": 1,
      "query_summary": { "num_reviews": 2, "review_score": 9,
        "review_score_desc": "Overwhelmingly Positive", "total_positive": 382062,
        "total_negative": 4943, "total_reviews": 387005 },
      "reviews": [
        { "recommendationid": "230366409",
          "author": { "steamid": "76561199026156214", "num_games_owned": 53,
            "num_reviews": 6, "playtime_forever": 665, "playtime_at_review": 665 },
          "language": "english", "review": "Best puzzle game ever made.",
          "timestamp_created": 1783933021, "timestamp_updated": 1783933021,
          "voted_up": true, "votes_up": 12, "votes_funny": 3 },
        { "recommendationid": "230366000",
          "author": { "steamid": "76561199000000000", "num_games_owned": 20,
            "playtime_forever": 42 },
          "language": "english", "review": "Not for me.",
          "timestamp_created": 1783900000, "timestamp_updated": 1783900000,
          "voted_up": false, "votes_up": 0, "votes_funny": 0 }
      ],
      "cursor": "AoJ4noGkrZ8DcOri7gY=" }
    """

    /// A store-search response (`{ total, items }`); the second item is free
    /// (no `price` key).
    static let search = """
    { "total": 2, "items": [
        { "type": "app", "name": "Portal 2", "id": 620,
          "price": { "currency": "USD", "initial": 999, "final": 999 },
          "tiny_image": "https://example.com/capsule.jpg", "metascore": "95",
          "platforms": { "windows": true, "mac": false, "linux": true },
          "streamingvideo": false, "controller_support": "full" },
        { "type": "app", "name": "Dota 2", "id": 570,
          "tiny_image": "https://example.com/dota.jpg", "metascore": "90",
          "platforms": { "windows": true, "mac": true, "linux": true },
          "streamingvideo": false }
    ] }
    """
}
