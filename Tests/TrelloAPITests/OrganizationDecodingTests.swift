import Testing
import Foundation
@testable import TrelloAPI

@Suite("Organization model decoding")
struct OrganizationDecodingTests {
    @Test("Decodes a complete organization JSON")
    func fullOrganization() throws {
        let json = """
        {
            "id": "5abbe4b7ddc1b351ef961414",
            "name": "acme-eng",
            "displayName": "Acme Engineering",
            "url": "https://trello.com/acme-eng",
            "idBoards": ["board1", "board2", "board3"]
        }
        """.data(using: .utf8)!

        let org = try JSONDecoder().decode(Organization.self, from: json)

        #expect(org.id == "5abbe4b7ddc1b351ef961414")
        #expect(org.name == "acme-eng")
        #expect(org.displayName == "Acme Engineering")
        #expect(org.url == "https://trello.com/acme-eng")
        #expect(org.idBoards == ["board1", "board2", "board3"])
    }

    @Test("Decodes a minimal organization JSON with only required fields")
    func minimalOrganization() throws {
        let json = """
        { "id": "abc123" }
        """.data(using: .utf8)!

        let org = try JSONDecoder().decode(Organization.self, from: json)

        #expect(org.id == "abc123")
        #expect(org.name == nil)
        #expect(org.displayName == nil)
        #expect(org.url == nil)
        #expect(org.idBoards == nil)
    }

    @Test("Round-trips through encode and decode")
    func roundTrip() throws {
        let original = Organization(
            id: "abc123",
            name: "acme-eng",
            displayName: "Acme Engineering",
            url: "https://trello.com/acme-eng",
            idBoards: ["board1", "board2"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Organization.self, from: data)

        #expect(decoded == original)
    }
}
