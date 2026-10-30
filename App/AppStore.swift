import Foundation

/// The public iTunes Search API: no key, about 20 calls a minute.
enum AppStore {
    struct Result: Decodable, Identifiable {
        let trackId: Int
        let trackName: String
        let bundleId: String
        let sellerName: String?
        let artworkUrl512: URL?
        let artworkUrl100: URL?

        var id: Int { trackId }

        var appRef: AppRef {
            let artwork = artworkUrl512 ?? artworkUrl100
            return AppRef(id: UUID(), name: trackName, bundleId: bundleId,
                          icon: artwork.map { .artwork($0) } ?? .letter(colorHex: Palette.folderColors[0]))
        }
    }

    private struct Response: Decodable {
        let results: [Result]
    }

    static let countryKey = "storeCountry"

    /// The store to search: the one set in About Tuck, else this phone's region.
    static var country: String {
        let chosen = UserDefaults.standard.string(forKey: countryKey)?.trimmingCharacters(in: .whitespaces).lowercased()
        if let chosen, !chosen.isEmpty { return chosen }
        return Locale.current.region?.identifier.lowercased() ?? "us"
    }

    /// Searches the chosen store first, then the US store if that finds nothing.
    static func search(_ term: String) async throws -> [Result] {
        let local = country
        let found = try await request("search", country: local, [("term", term), ("limit", "25")])
        if found.isEmpty && local != "us" {
            return try await request("search", country: "us", [("term", term), ("limit", "25")])
        }
        return found
    }

    /// Details for many bundle IDs, in batches (one call per 40 apps), US store for any the local
    /// store doesn't have.
    static func lookup(bundleIds: [String]) async -> [Result] {
        var found: [Result] = []
        for start in stride(from: 0, to: bundleIds.count, by: 40) {
            let batch = Array(bundleIds[start..<min(start + 40, bundleIds.count)])
            found += (try? await request("lookup", country: country, [("bundleId", batch.joined(separator: ","))])) ?? []
        }
        let missing = bundleIds.filter { id in !found.contains { $0.bundleId == id } }
        if !missing.isEmpty && country != "us" {
            found += (try? await request("lookup", country: "us", [("bundleId", missing.joined(separator: ","))])) ?? []
        }
        return found
    }

    private static func request(_ path: String, country: String, _ query: [(String, String)]) async throws -> [Result] {
        var components = URLComponents(string: "https://itunes.apple.com/\(path)")!
        components.queryItems = [URLQueryItem(name: "entity", value: "software"),
                                 URLQueryItem(name: "country", value: country)]
            + query.map { URLQueryItem(name: $0.0, value: $0.1) }
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(Response.self, from: data).results
    }
}
