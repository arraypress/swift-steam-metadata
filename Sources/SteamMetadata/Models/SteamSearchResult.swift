//
//  SteamSearchResult.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single result from a Steam store search.
///
/// Returned by ``SteamMetadata/search(_:country:configuration:)``. Pass ``id``
/// to ``SteamMetadata/app(_:country:configuration:)`` to fetch the full detail
/// record.
public struct SteamSearchResult: Sendable, Identifiable {

    /// The Steam app ID.
    public let id: Int

    /// The store type, e.g. `"app"`.
    public let type: String

    /// The app's display name.
    public let name: String

    /// A small capsule image URL.
    public let tinyImageURL: String?

    /// The price, or `nil` for free apps. Search prices carry only currency and
    /// amounts — no discount or formatted string.
    public let price: SteamPrice?

    /// The Metacritic score (`0...100`), when Steam provides one.
    public let metacriticScore: Int?

    /// Whether a Windows build is available.
    public let windows: Bool

    /// Whether a macOS build is available.
    public let mac: Bool

    /// Whether a Linux build is available.
    public let linux: Bool

    public init(
        id: Int,
        type: String,
        name: String,
        tinyImageURL: String?,
        price: SteamPrice?,
        metacriticScore: Int?,
        windows: Bool,
        mac: Bool,
        linux: Bool
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.tinyImageURL = tinyImageURL
        self.price = price
        self.metacriticScore = metacriticScore
        self.windows = windows
        self.mac = mac
        self.linux = linux
    }
}
