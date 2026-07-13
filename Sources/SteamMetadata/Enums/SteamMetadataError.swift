//
//  SteamMetadataError.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Errors that can occur when calling Steam's keyless store endpoints.
public enum SteamMetadataError: Error, LocalizedError, Equatable, Sendable {

    /// The supplied query or identifier was empty or invalid.
    case invalidInput

    /// The requested app was not found, or Steam reported `success: false`
    /// (an unknown app ID, or one with no store page — e.g. a delisted title).
    case notFound

    /// Steam is rate-limiting requests (`429`). The store endpoints are
    /// unauthenticated but throttled per IP.
    case rateLimited

    /// Steam returned an error payload or a non-success status.
    case apiError(String)

    /// A network request failed.
    case networkError(String)

    /// Failed to parse the response.
    case parsingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "The query or app identifier was empty or invalid."
        case .notFound:
            return "The requested Steam app was not found."
        case .rateLimited:
            return "Steam is rate-limiting requests. Try again shortly."
        case .apiError(let message):
            return "Steam API error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
