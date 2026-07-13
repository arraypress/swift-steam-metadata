//
//  SteamReviewsPage.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One page of Steam user reviews: the overall summary, this page's reviews,
/// and a cursor for fetching the next page.
///
/// Returned by ``SteamMetadata/reviews(appID:filter:language:cursor:configuration:)``.
/// Pass ``cursor`` back in as the next call's `cursor:` argument to paginate;
/// a page shorter than the requested count (or a repeated cursor) means you've
/// reached the end.
public struct SteamReviewsPage: Sendable {

    /// The catalog-wide review summary for the app.
    public let summary: SteamReviewSummary

    /// The reviews on this page.
    public let reviews: [SteamReview]

    /// The cursor to pass as `cursor:` to fetch the next page.
    public let cursor: String?

    public init(summary: SteamReviewSummary, reviews: [SteamReview], cursor: String?) {
        self.summary = summary
        self.reviews = reviews
        self.cursor = cursor
    }
}

// MARK: - Summary

/// Aggregate review statistics for a Steam app (from a reviews query's
/// `query_summary`).
public struct SteamReviewSummary: Sendable {

    /// The number of reviews returned on the current page.
    public let numReviews: Int

    /// Steam's numeric review score bucket (`0...9`).
    public let reviewScore: Int

    /// The human-readable score, e.g. `"Overwhelmingly Positive"`.
    public let reviewScoreDesc: String

    /// The total number of positive reviews across all time.
    public let totalPositive: Int

    /// The total number of negative reviews across all time.
    public let totalNegative: Int

    /// The total number of reviews across all time.
    public let totalReviews: Int

    public init(
        numReviews: Int,
        reviewScore: Int,
        reviewScoreDesc: String,
        totalPositive: Int,
        totalNegative: Int,
        totalReviews: Int
    ) {
        self.numReviews = numReviews
        self.reviewScore = reviewScore
        self.reviewScoreDesc = reviewScoreDesc
        self.totalPositive = totalPositive
        self.totalNegative = totalNegative
        self.totalReviews = totalReviews
    }
}
