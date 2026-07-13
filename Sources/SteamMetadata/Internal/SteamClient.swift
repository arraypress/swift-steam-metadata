//
//  SteamClient.swift
//  SteamMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Performs GET requests against Steam's keyless store endpoints.
///
/// No API key or authentication is required. Every query value is strictly
/// percent-encoded (RFC 3986 unreserved set) — this matters for the reviews
/// `cursor`, whose base64 payload contains `+`, `/`, and `=` that Steam would
/// otherwise misread. Over-limit responses (`429`) map to
/// ``SteamMetadataError/rateLimited``.
enum SteamClient {

    /// The base host for the Steam store API.
    static let host = "https://store.steampowered.com"

    /// A browser-like User-Agent; the store endpoints are friendlier to one.
    static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"

    /// RFC 3986 unreserved characters — everything else in a query value is encoded.
    private static let unreserved: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()

    /// Performs a GET against `host + path` and returns the decoded JSON object.
    ///
    /// - Parameters:
    ///   - path: The request path (e.g. `/api/appdetails` or `/appreviews/620`).
    ///   - queryItems: The query parameters to append (values are percent-encoded).
    /// - Returns: The top-level JSON object.
    static func get(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> [String: Any] {
        guard var components = URLComponents(string: host + path) else {
            throw SteamMetadataError.networkError("Invalid request URL")
        }
        if !queryItems.isEmpty {
            components.percentEncodedQueryItems = queryItems.map { item in
                let value = item.value?.addingPercentEncoding(withAllowedCharacters: unreserved)
                return URLQueryItem(name: item.name, value: value)
            }
        }
        guard let url = components.url else {
            throw SteamMetadataError.networkError("Invalid request URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SteamMetadataError.networkError(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            switch http.statusCode {
            case 429: throw SteamMetadataError.rateLimited
            case 404: throw SteamMetadataError.notFound
            default: throw SteamMetadataError.apiError("HTTP \(http.statusCode)")
            }
        }

        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw SteamMetadataError.parsingError("Invalid JSON response")
        }
        return json
    }
}
