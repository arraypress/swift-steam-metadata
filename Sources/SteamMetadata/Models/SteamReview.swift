//
//  SteamReview.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single Steam user review.
///
/// Fetched as part of a ``SteamReviewsPage`` via
/// ``SteamMetadata/reviews(appID:filter:language:cursor:configuration:)``.
public struct SteamReview: Sendable, Identifiable {

    /// The review's `recommendationid`.
    public let id: String

    /// The review body text.
    public let body: String

    /// Whether the reviewer recommends the app (thumbs up).
    public let votedUp: Bool

    /// How many other users marked this review helpful.
    public let votesUp: Int

    /// How many other users marked this review funny.
    public let votesFunny: Int

    /// The review language, e.g. `"english"`.
    public let language: String?

    /// The reviewer's SteamID64.
    public let authorSteamID: String?

    /// The reviewer's total playtime for the app, in minutes.
    public let authorPlaytimeForever: Int?

    /// The reviewer's playtime at the moment the review was written, in minutes.
    public let authorPlaytimeAtReview: Int?

    /// How many games the reviewer owns.
    public let authorGamesOwned: Int?

    /// When the review was first posted.
    public let created: Date?

    /// When the review was last updated.
    public let updated: Date?

    public init(
        id: String,
        body: String,
        votedUp: Bool,
        votesUp: Int,
        votesFunny: Int,
        language: String?,
        authorSteamID: String?,
        authorPlaytimeForever: Int?,
        authorPlaytimeAtReview: Int?,
        authorGamesOwned: Int?,
        created: Date?,
        updated: Date?
    ) {
        self.id = id
        self.body = body
        self.votedUp = votedUp
        self.votesUp = votesUp
        self.votesFunny = votesFunny
        self.language = language
        self.authorSteamID = authorSteamID
        self.authorPlaytimeForever = authorPlaytimeForever
        self.authorPlaytimeAtReview = authorPlaytimeAtReview
        self.authorGamesOwned = authorGamesOwned
        self.created = created
        self.updated = updated
    }
}
