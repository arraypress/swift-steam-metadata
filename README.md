# Swift Steam Metadata

A Swift library for fetching **Steam** game metadata, user reviews, and store search results using Steam's public store endpoints.

**No API key. No authentication.** Just call and go.

## Features

- 🔓 **Keyless** — Steam's store endpoints need no Web API key or login
- 🎮 **App details** — type, descriptions, developers, publishers, genres, categories, platforms, release date, header image, and screenshots
- 💰 **Typed pricing** — `SteamPrice` with currency, cents, discount, and Steam's own formatted string (`"$9.99"`)
- ⭐ **User reviews** — the overall score summary plus cursor-paginated reviews (body, thumbs up/down, helpful/funny votes, author playtime, dates)
- 🔎 **Store search** — discover an app ID by name, with Metacritic score and platforms
- 🍎 **Cross-platform** — macOS, iOS, tvOS, watchOS · Swift 6 · async/await
- 🛡️ **Typed error handling**

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-steam-metadata", from: "1.0.0")
]
```

## Usage

Everything hangs off an integer **app ID** (e.g. `620` for Portal 2). Search by name to discover it, then fetch details and reviews.

```swift
import SteamMetadata

// 1. Search the store to discover an app ID
let hits = try await SteamMetadata.search("portal 2")
guard let hit = hits.first else { return }
print("\(hit.name) — appID \(hit.id)")

// 2. Fetch the full detail record
let app = try await SteamMetadata.app(hit.id)
print("\(app.name) by \(app.developers.joined(separator: ", "))")
print("Genres: \(app.genres.joined(separator: ", "))")
if let price = app.price {
    print("Price: \(price.finalFormatted ?? "\(price.finalDollars) \(price.currency)")")
} else if app.isFree {
    print("Free to play")
}
print("Metacritic: \(app.metacriticScore ?? 0)")
```

### Reviews

Reviews are cursor-paginated. Start with `"*"`, then pass the returned `cursor` back in for the next page:

```swift
let page = try await SteamMetadata.reviews(appID: 620, filter: .recent)
print("Overall: \(page.summary.reviewScoreDesc) "
      + "(\(page.summary.totalPositive) positive / \(page.summary.totalNegative) negative)")

for review in page.reviews {
    let thumb = review.votedUp ? "👍" : "👎"
    print("\(thumb) \(review.body)  — \((review.authorPlaytimeForever ?? 0) / 60)h played")
}

// Page forward
if let cursor = page.cursor {
    let next = try await SteamMetadata.reviews(appID: 620, filter: .recent, cursor: cursor)
    print("Next page: \(next.reviews.count) more reviews")
}
```

Pass `filter:` a `SteamReviewFilter` — `.recent` (newest first), `.updated` (recently edited), or `.all` (Steam's helpfulness ranking) — and `language:` a language name (e.g. `"english"`) or `"all"`.

### Storefront

Pass a `country:` (ISO alpha-2, e.g. `"us"`, `"gb"`) to `app(_:)` and `search(_:)` to control pricing and currency. It defaults to the `STEAM_COUNTRY` environment variable, or `"us"`.

```swift
let uk = try await SteamMetadata.app(620, country: "gb")
print(uk.price?.finalFormatted ?? "?")   // → "£7.19"
```

## Models

| Type | Description |
|------|-------------|
| `SteamApp` | Full detail record: `id`, `type`, `name`, `shortDescription`, `detailedDescription`, `isFree`, `price`, `releaseDate`, `comingSoon`, `developers`, `publishers`, `genres`, `categories`, `windows`/`mac`/`linux`, `metacriticScore`, `metacriticURL`, `recommendationsTotal`, `headerImageURL`, `website`, `screenshots` |
| `SteamPrice` | `currency`, `initial`/`final` (cents), `discountPercent`, `finalFormatted`, plus `initialDollars`/`finalDollars`/`isDiscounted` conveniences |
| `SteamReviewsPage` | `summary` + `[SteamReview]` + next `cursor` |
| `SteamReviewSummary` | `numReviews`, `reviewScore`, `reviewScoreDesc`, `totalPositive`, `totalNegative`, `totalReviews` |
| `SteamReview` | `id`, `body`, `votedUp`, `votesUp`, `votesFunny`, `language`, `authorSteamID`, `authorPlaytimeForever`, `authorPlaytimeAtReview`, `authorGamesOwned`, `created`, `updated` |
| `SteamSearchResult` | `id`, `type`, `name`, `tinyImageURL`, `price`, `metacriticScore`, `windows`/`mac`/`linux` |
| `SteamReviewFilter` | `recent`, `updated`, `all` (raw values match the API) |
| `SteamMetadata.Configuration` | Storefront `country` (defaults to `us` / `STEAM_COUNTRY`) |
| `SteamMetadataError` | Typed errors with `errorDescription` |

Free games carry no `price`, and not every title has a `metacriticScore` or `recommendationsTotal`, so those fields are optional.

## Endpoints

All keyless, on `https://store.steampowered.com`:

- `GET /api/appdetails?appids={id}&cc={country}&l=english` — app details
- `GET /appreviews/{id}?json=1&filter={filter}&language={lang}&num_per_page={n}&cursor={cursor}` — user reviews
- `GET /api/storesearch/?term={query}&cc={country}&l=english` — store search

## Testing

```bash
swift test                          # offline unit tests (fixtures)
STEAM_LIVE_TESTS=1 swift test       # + keyless live app + reviews + search
STEAM_LIVE_TESTS=1 STEAM_PRINT=1 swift test   # + print live output
```

## License

MIT

## Author

David Sherlock
