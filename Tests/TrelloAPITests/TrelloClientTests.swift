import Testing
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
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

@Suite("Members boards API endpoint")
struct MembersBoardsAPITests {
    @Test("getMemberBoards sends request to /members/me/boards by default")
    func getMemberBoardsDefault() async throws {
        let boardsJSON = """
        [
            { "id": "board1", "name": "First Board" },
            { "id": "board2", "name": "Second Board", "closed": true }
        ]
        """.data(using: .utf8)!

        let capture = RequestCapture()
        let mock = MockHTTPClient.capturing(into: capture, data: boardsJSON)
        let client = TrelloClient(apiKey: "key", apiToken: "token", httpClient: mock)

        let boards = try await client.getMemberBoards()

        #expect(boards.count == 2)
        #expect(boards[0].id == "board1")
        #expect(boards[0].name == "First Board")
        #expect(boards[1].id == "board2")
        #expect(boards[1].closed == true)

        let requests = await capture.requests
        let url = try #require(requests.first?.url)
        #expect(url.path.hasSuffix("/members/me/boards"))
    }

    @Test("getMemberBoards sends request with custom member ID")
    func getMemberBoardsById() async throws {
        let boardsJSON = """
        [ { "id": "board1", "name": "Board" } ]
        """.data(using: .utf8)!

        let capture = RequestCapture()
        let mock = MockHTTPClient.capturing(into: capture, data: boardsJSON)
        let client = TrelloClient(apiKey: "key", apiToken: "token", httpClient: mock)

        let boards = try await client.getMemberBoards(memberId: "user789")

        #expect(boards.count == 1)

        let requests = await capture.requests
        let url = try #require(requests.first?.url)
        #expect(url.path.hasSuffix("/members/user789/boards"))
    }
}

@Suite("Boards cards API endpoint")
struct BoardsCardsAPITests {
    @Test("getBoardCards sends request to /boards/{id}/cards")
    func getBoardCards() async throws {
        let cardsJSON = """
        [
            { "id": "card1", "name": "First Card" },
            { "id": "card2", "name": "Second Card", "closed": true }
        ]
        """.data(using: .utf8)!

        let capture = RequestCapture()
        let mock = MockHTTPClient.capturing(into: capture, data: cardsJSON)
        let client = TrelloClient(apiKey: "key", apiToken: "token", httpClient: mock)

        let cards = try await client.getBoardCards(boardId: "board123")

        #expect(cards.count == 2)
        #expect(cards[0].id == "card1")
        #expect(cards[0].name == "First Card")
        #expect(cards[1].id == "card2")
        #expect(cards[1].closed == true)

        let requests = await capture.requests
        let url = try #require(requests.first?.url)
        #expect(url.path.hasSuffix("/boards/board123/cards"))
    }
}

@Suite("Cards API endpoint")
struct CardsAPITests {
    @Test("getCard sends request to /cards/{id}")
    func getCardById() async throws {
        let cardJSON = """
        { "id": "card123", "name": "My Card", "desc": "A description" }
        """.data(using: .utf8)!

        let capture = RequestCapture()
        let mock = MockHTTPClient.capturing(into: capture, data: cardJSON)
        let client = TrelloClient(apiKey: "key", apiToken: "token", httpClient: mock)

        let card = try await client.getCard(id: "card123")

        #expect(card.id == "card123")
        #expect(card.name == "My Card")
        #expect(card.desc == "A description")

        let requests = await capture.requests
        let url = try #require(requests.first?.url)
        #expect(url.path.hasSuffix("/cards/card123"))
    }
}

@Suite("Member Organizations API endpoint")
struct MemberOrganizationsAPITests {
    @Test("getMemberOrganizations sends request to /members/me/organizations by default")
    func getMemberOrganizationsDefault() async throws {
        let orgsJSON = """
        [
            { "id": "org1", "name": "acme-eng", "displayName": "Acme Engineering" },
            { "id": "org2", "name": "oss-club", "idBoards": ["b1", "b2"] }
        ]
        """.data(using: .utf8)!

        let capture = RequestCapture()
        let mock = MockHTTPClient.capturing(into: capture, data: orgsJSON)
        let client = TrelloClient(apiKey: "key", apiToken: "token", httpClient: mock)

        let orgs = try await client.getMemberOrganizations()

        #expect(orgs.count == 2)
        #expect(orgs[0].id == "org1")
        #expect(orgs[0].name == "acme-eng")
        #expect(orgs[0].displayName == "Acme Engineering")
        #expect(orgs[1].id == "org2")
        #expect(orgs[1].idBoards == ["b1", "b2"])

        let requests = await capture.requests
        let url = try #require(requests.first?.url)
        #expect(url.path.hasSuffix("/members/me/organizations"))
    }

    @Test("getMemberOrganizations sends request with custom member ID")
    func getMemberOrganizationsById() async throws {
        let orgsJSON = """
        [ { "id": "org1", "name": "workspace" } ]
        """.data(using: .utf8)!

        let capture = RequestCapture()
        let mock = MockHTTPClient.capturing(into: capture, data: orgsJSON)
        let client = TrelloClient(apiKey: "key", apiToken: "token", httpClient: mock)

        let orgs = try await client.getMemberOrganizations(memberId: "user789")

        #expect(orgs.count == 1)

        let requests = await capture.requests
        let url = try #require(requests.first?.url)
        #expect(url.path.hasSuffix("/members/user789/organizations"))
    }
}
