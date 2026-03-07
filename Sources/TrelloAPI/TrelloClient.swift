import Foundation

/// Errors that can occur when communicating with the Trello API.
public enum TrelloAPIError: Error, LocalizedError, Equatable, Sendable {
    case missingCredentials
    case invalidURL(String)
    case httpError(statusCode: Int, body: String)
    case decodingError(String)
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Missing API credentials. Set TRELLO_API_KEY and TRELLO_API_TOKEN as environment variables or in a .env file."
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .httpError(let statusCode, let body):
            return "HTTP \(statusCode): \(body)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

/// Abstraction over URL-based HTTP data loading for testability.
public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Default implementation using URLSession.
extension URLSession: HTTPClient {
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}

/// Client for the Trello REST API.
public struct TrelloClient: Sendable {
    public static let baseURL = "https://api.trello.com/1"

    private let apiKey: String
    private let apiToken: String
    private let httpClient: HTTPClient

    public init(apiKey: String, apiToken: String, httpClient: HTTPClient = URLSession.shared) {
        self.apiKey = apiKey
        self.apiToken = apiToken
        self.httpClient = httpClient
    }

    /// Creates an authenticated URL request for the given API path.
    public func makeRequest(path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        guard var components = URLComponents(string: Self.baseURL + path) else {
            throw TrelloAPIError.invalidURL(Self.baseURL + path)
        }

        var items = queryItems
        items.append(URLQueryItem(name: "key", value: apiKey))
        items.append(URLQueryItem(name: "token", value: apiToken))
        components.queryItems = items

        guard let url = components.url else {
            throw TrelloAPIError.invalidURL(components.string ?? path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }

    /// Performs a GET request and decodes the response.
    public func get<T: Decodable>(_ type: T.Type, path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let request = try makeRequest(path: path, queryItems: queryItems)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await httpClient.data(for: request)
        } catch let error as TrelloAPIError {
            throw error
        } catch {
            throw TrelloAPIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TrelloAPIError.networkError("Invalid response type")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<unreadable>"
            throw TrelloAPIError.httpError(statusCode: httpResponse.statusCode, body: body)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw TrelloAPIError.decodingError(error.localizedDescription)
        }
    }
}
