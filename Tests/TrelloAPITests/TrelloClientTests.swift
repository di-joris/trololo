import Testing
import Foundation
@testable import TrelloAPI

/// A mock HTTP client that returns preconfigured responses.
struct MockHTTPClient: HTTPClient {
    var result: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await result(request)
    }

    /// Creates a mock that returns the given data with an HTTP 200 response.
    static func success(data: Data) -> MockHTTPClient {
        MockHTTPClient { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.trello.com/1")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }
    }

    /// Creates a mock that returns an HTTP error.
    static func httpError(statusCode: Int, body: String = "") -> MockHTTPClient {
        MockHTTPClient { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.trello.com/1")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data(body.utf8), response)
        }
    }

    /// Creates a mock that captures the request for inspection.
    static func capturing(
        into requests: RequestCapture,
        data: Data = Data("{}".utf8)
    ) -> MockHTTPClient {
        MockHTTPClient { request in
            await requests.append(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }
    }
}

/// Actor for safely capturing requests across async calls.
actor RequestCapture {
    var requests: [URLRequest] = []

    func append(_ request: URLRequest) {
        requests.append(request)
    }
}

@Suite("TrelloClient")
struct TrelloClientTests {
    let apiKey = "test-api-key-32chars-placeholder0"
    let apiToken = "test-api-token"

    @Test("Appends key and token query parameters to requests")
    func authQueryParams() throws {
        let client = TrelloClient(apiKey: apiKey, apiToken: apiToken)
        let request = try client.makeRequest(path: "/members/me")
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try #require(components.queryItems)

        #expect(queryItems.contains(URLQueryItem(name: "key", value: apiKey)))
        #expect(queryItems.contains(URLQueryItem(name: "token", value: apiToken)))
    }

    @Test("Builds the correct base URL with path")
    func urlConstruction() throws {
        let client = TrelloClient(apiKey: apiKey, apiToken: apiToken)
        let request = try client.makeRequest(path: "/boards/123")
        let url = try #require(request.url)

        #expect(url.absoluteString.hasPrefix("https://api.trello.com/1/boards/123"))
    }

    @Test("Includes additional query items in the request")
    func additionalQueryItems() throws {
        let client = TrelloClient(apiKey: apiKey, apiToken: apiToken)
        let request = try client.makeRequest(
            path: "/members/me",
            queryItems: [URLQueryItem(name: "fields", value: "id,username")]
        )
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try #require(components.queryItems)

        #expect(queryItems.contains(URLQueryItem(name: "fields", value: "id,username")))
    }

    @Test("GET request decodes a successful JSON response")
    func getSuccess() async throws {
        let json = """
        { "id": "abc123", "username": "testuser" }
        """.data(using: .utf8)!

        let mock = MockHTTPClient.success(data: json)
        let client = TrelloClient(apiKey: apiKey, apiToken: apiToken, httpClient: mock)

        let member = try await client.get(Member.self, path: "/members/me")

        #expect(member.id == "abc123")
        #expect(member.username == "testuser")
    }

    @Test("GET request throws httpError for non-2xx status codes",
          arguments: [400, 401, 403, 404, 500])
    func getHTTPError(statusCode: Int) async {
        let mock = MockHTTPClient.httpError(statusCode: statusCode, body: "error body")
        let client = TrelloClient(apiKey: apiKey, apiToken: apiToken, httpClient: mock)

        await #expect(throws: TrelloAPIError.httpError(statusCode: statusCode, body: "error body")) {
            try await client.get(Member.self, path: "/members/me")
        }
    }

    @Test("GET request throws decodingError for invalid JSON")
    func getDecodingError() async {
        let mock = MockHTTPClient.success(data: Data("not json".utf8))
        let client = TrelloClient(apiKey: apiKey, apiToken: apiToken, httpClient: mock)

        await #expect {
            try await client.get(Member.self, path: "/members/me")
        } throws: { error in
            guard let apiError = error as? TrelloAPIError,
                  case .decodingError = apiError else { return false }
            return true
        }
    }
}

@Suite("Members API endpoint")
struct MembersAPITests {
    @Test("getMember sends request to /members/me by default")
    func getMemberMe() async throws {
        let memberJSON = """
        { "id": "me123", "username": "myself", "fullName": "My Self" }
        """.data(using: .utf8)!

        let capture = RequestCapture()
        let mock = MockHTTPClient.capturing(into: capture, data: memberJSON)
        let client = TrelloClient(apiKey: "key", apiToken: "token", httpClient: mock)

        let member = try await client.getMember()

        #expect(member.id == "me123")
        #expect(member.username == "myself")
        #expect(member.fullName == "My Self")

        let requests = await capture.requests
        let url = try #require(requests.first?.url)
        #expect(url.path.hasSuffix("/members/me"))
    }

    @Test("getMember sends request with custom ID")
    func getMemberById() async throws {
        let memberJSON = """
        { "id": "custom456", "username": "other" }
        """.data(using: .utf8)!

        let capture = RequestCapture()
        let mock = MockHTTPClient.capturing(into: capture, data: memberJSON)
        let client = TrelloClient(apiKey: "key", apiToken: "token", httpClient: mock)

        let member = try await client.getMember(id: "custom456")

        #expect(member.id == "custom456")

        let requests = await capture.requests
        let url = try #require(requests.first?.url)
        #expect(url.path.hasSuffix("/members/custom456"))
    }
}
