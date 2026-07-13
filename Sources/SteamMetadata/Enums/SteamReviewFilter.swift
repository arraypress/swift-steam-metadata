//
//  SteamReviewFilter.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The order in which Steam user reviews are returned.
///
/// The raw value maps directly to the store API `filter` parameter used by
/// ``SteamMetadata/reviews(appID:filter:language:cursor:configuration:)``.
public enum SteamReviewFilter: String, Sendable, CaseIterable {
    /// Newest reviews first, by creation date.
    case recent
    /// Most recently updated reviews first.
    case updated
    /// Steam's "helpfulness" ranking (the default sort on the store page).
    case all
}
