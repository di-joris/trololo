import Testing
import Foundation
@testable import TrelloAPI

@Suite("Card model decoding")
struct CardDecodingTests {
    @Test("Decodes a complete card JSON")
    func fullCard() throws {
        let json = """
        {
            "id": "5abbe4b7ddc1b351ef961414",
            "name": "My Card",
            "desc": "A card description",
            "closed": false,
            "due": "2025-12-31T12:00:00.000Z",
            "dueComplete": false,
            "idBoard": "board123",
            "idList": "list456",
            "url": "https://trello.com/c/abc123/1-my-card",
            "shortUrl": "https://trello.com/c/abc123",
            "pos": 65535.5,
            "idMembers": ["member1", "member2"]
        }
        """.data(using: .utf8)!

        let card = try JSONDecoder().decode(Card.self, from: json)

        #expect(card.id == "5abbe4b7ddc1b351ef961414")
        #expect(card.name == "My Card")
        #expect(card.desc == "A card description")
        #expect(card.closed == false)
        #expect(card.due == "2025-12-31T12:00:00.000Z")
        #expect(card.dueComplete == false)
        #expect(card.idBoard == "board123")
        #expect(card.idList == "list456")
        #expect(card.url == "https://trello.com/c/abc123/1-my-card")
        #expect(card.shortUrl == "https://trello.com/c/abc123")
        #expect(card.pos == 65535.5)
        #expect(card.idMembers == ["member1", "member2"])
    }

    @Test("Decodes a minimal card JSON with only required fields")
    func minimalCard() throws {
        let json = """
        { "id": "abc123" }
        """.data(using: .utf8)!

        let card = try JSONDecoder().decode(Card.self, from: json)

        #expect(card.id == "abc123")
        #expect(card.name == nil)
        #expect(card.desc == nil)
        #expect(card.closed == nil)
        #expect(card.due == nil)
        #expect(card.dueComplete == nil)
        #expect(card.idBoard == nil)
        #expect(card.idList == nil)
        #expect(card.url == nil)
        #expect(card.shortUrl == nil)
        #expect(card.pos == nil)
        #expect(card.idMembers == nil)
    }

    @Test("Round-trips through encode and decode")
    func roundTrip() throws {
        let original = Card(
            id: "abc123",
            name: "Test Card",
            desc: "A test card",
            closed: false,
            due: "2025-06-15T10:00:00.000Z",
            dueComplete: true,
            idBoard: "board1",
            idList: "list1",
            url: "https://trello.com/c/abc123/1-test-card",
            shortUrl: "https://trello.com/c/abc123",
            pos: 1024.0,
            idMembers: ["m1"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Card.self, from: data)

        #expect(decoded == original)
    }
}
