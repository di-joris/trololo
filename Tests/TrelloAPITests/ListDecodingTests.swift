import Testing
import Foundation
@testable import TrelloAPI

@Suite("TrelloList model decoding")
struct ListDecodingTests {
    @Test("Decodes a complete list JSON")
    func fullList() throws {
        let json = """
        {
            "id": "60d5a2c5b4a5c812a4e3f001",
            "name": "To Do",
            "closed": false,
            "pos": 16384.5,
            "softLimit": "50",
            "idBoard": "5abbe4b7ddc1b351ef961414",
            "subscribed": true
        }
        """.data(using: .utf8)!

        let list = try JSONDecoder().decode(TrelloList.self, from: json)

        #expect(list.id == "60d5a2c5b4a5c812a4e3f001")
        #expect(list.name == "To Do")
        #expect(list.closed == false)
        #expect(list.pos == 16384.5)
        #expect(list.softLimit == "50")
        #expect(list.idBoard == "5abbe4b7ddc1b351ef961414")
        #expect(list.subscribed == true)
    }

    @Test("Decodes a minimal list JSON with only required fields")
    func minimalList() throws {
        let json = """
        { "id": "abc123" }
        """.data(using: .utf8)!

        let list = try JSONDecoder().decode(TrelloList.self, from: json)

        #expect(list.id == "abc123")
        #expect(list.name == nil)
        #expect(list.closed == nil)
        #expect(list.pos == nil)
        #expect(list.softLimit == nil)
        #expect(list.idBoard == nil)
        #expect(list.subscribed == nil)
    }

    @Test("Round-trips through encode and decode")
    func roundTrip() throws {
        let original = TrelloList(
            id: "abc123",
            name: "In Progress",
            closed: false,
            pos: 32768.0,
            softLimit: "25",
            idBoard: "board456",
            subscribed: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TrelloList.self, from: data)

        #expect(decoded == original)
    }
}
