//
//  SteamPrice.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A Steam store price.
///
/// Steam expresses amounts as integer minor units (cents) — `999` means `9.99`
/// in ``currency``. Use ``finalDollars`` / ``initialDollars`` for the decimal
/// value, or ``finalFormatted`` for Steam's own localized string (e.g. `"$9.99"`).
///
/// The app-details endpoint fills every field; the lighter search endpoint
/// provides only ``currency``, ``initial``, and ``final``, leaving
/// ``discountPercent`` at `0` and ``finalFormatted`` `nil`.
public struct SteamPrice: Sendable, Equatable {

    /// The ISO currency code, e.g. `"USD"`.
    public let currency: String

    /// The full (pre-discount) price in minor units (cents).
    public let initial: Int

    /// The current price in minor units (cents), after any discount.
    public let final: Int

    /// The discount percentage (`0` when not on sale).
    public let discountPercent: Int

    /// Steam's localized formatted price, e.g. `"$9.99"`. `nil` for search
    /// results, which don't carry a formatted string.
    public let finalFormatted: String?

    /// The full (pre-discount) price as a decimal, e.g. `9.99`.
    public var initialDollars: Double { Double(initial) / 100 }

    /// The current price as a decimal, e.g. `9.99`.
    public var finalDollars: Double { Double(final) / 100 }

    /// Whether the item is currently discounted.
    public var isDiscounted: Bool { discountPercent > 0 }

    public init(
        currency: String,
        initial: Int,
        final: Int,
        discountPercent: Int = 0,
        finalFormatted: String? = nil
    ) {
        self.currency = currency
        self.initial = initial
        self.final = final
        self.discountPercent = discountPercent
        self.finalFormatted = finalFormatted
    }
}
