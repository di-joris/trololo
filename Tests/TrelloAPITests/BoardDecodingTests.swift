import Testing
import Foundation
@testable import TrelloAPI

@Suite("Board model decoding")
struct BoardDecodingTests {
    @Test("Decodes a complete board JSON")
    func fullBoard() throws {
        let json = """
        {
            "id": "5abbe4b7ddc1b351ef961414",
            "name": "My Project Board",
            "desc": "A board for tracking project tasks",
            "closed": false,
            "url": "https://trello.com/b/abc123/my-project-board",
            "shortUrl": "https://trello.com/b/abc123",
            "idOrganization": "5abbe4b7ddc1b351ef961415",
            "pinned": true,
            "starred": true
        }
        """.data(using: .utf8)!

        let board = try JSONDecoder().decode(Board.self, from: json)

        #expect(board.id == "5abbe4b7ddc1b351ef961414")
        #expect(board.name == "My Project Board")
        #expect(board.desc == "A board for tracking project tasks")
        #expect(board.closed == false)
        #expect(board.url == "https://trello.com/b/abc123/my-project-board")
        #expect(board.shortUrl == "https://trello.com/b/abc123")
        #expect(board.idOrganization == "5abbe4b7ddc1b351ef961415")
        #expect(board.pinned == true)
        #expect(board.starred == true)
    }

    @Test("Decodes a minimal board JSON with only required fields")
    func minimalBoard() throws {
        let json = """
        { "id": "abc123" }
        """.data(using: .utf8)!

        let board = try JSONDecoder().decode(Board.self, from: json)

        #expect(board.id == "abc123")
        #expect(board.name == nil)
        #expect(board.desc == nil)
        #expect(board.closed == nil)
        #expect(board.url == nil)
        #expect(board.shortUrl == nil)
        #expect(board.idOrganization == nil)
        #expect(board.pinned == nil)
        #expect(board.starred == nil)
    }

    @Test("Round-trips through encode and decode")
    func roundTrip() throws {
        let original = Board(
            id: "abc123",
            name: "Test Board",
            desc: "A test board",
            closed: false,
            url: "https://trello.com/b/abc123/test-board",
            shortUrl: "https://trello.com/b/abc123",
            idOrganization: "org456",
            pinned: false,
            starred: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Board.self, from: data)

        #expect(decoded == original)
    }
}
