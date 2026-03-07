import Testing
import Foundation
@testable import TrelloAPI

@Suite("Member model decoding")
struct MemberDecodingTests {
    @Test("Decodes a complete member JSON")
    func fullMember() throws {
        let json = """
        {
            "id": "5abbe4b7ddc1b351ef961414",
            "username": "bentleycook",
            "fullName": "Bentley Cook",
            "initials": "BC",
            "bio": "👋 I'm a developer advocate at Trello!",
            "url": "https://trello.com/bentleycook",
            "email": "bentley@example.com",
            "avatarUrl": "https://trello-avatars.s3.amazonaws.com/fc8faaaee46666a4eb8b626c08933e16",
            "memberType": "normal",
            "confirmed": true,
            "status": "active"
        }
        """.data(using: .utf8)!

        let member = try JSONDecoder().decode(Member.self, from: json)

        #expect(member.id == "5abbe4b7ddc1b351ef961414")
        #expect(member.username == "bentleycook")
        #expect(member.fullName == "Bentley Cook")
        #expect(member.initials == "BC")
        #expect(member.bio == "👋 I'm a developer advocate at Trello!")
        #expect(member.url == "https://trello.com/bentleycook")
        #expect(member.email == "bentley@example.com")
        #expect(member.avatarUrl == "https://trello-avatars.s3.amazonaws.com/fc8faaaee46666a4eb8b626c08933e16")
        #expect(member.memberType == "normal")
        #expect(member.confirmed == true)
        #expect(member.status == "active")
    }

    @Test("Decodes a minimal member JSON with only required fields")
    func minimalMember() throws {
        let json = """
        { "id": "abc123" }
        """.data(using: .utf8)!

        let member = try JSONDecoder().decode(Member.self, from: json)

        #expect(member.id == "abc123")
        #expect(member.username == nil)
        #expect(member.fullName == nil)
        #expect(member.email == nil)
    }

    @Test("Round-trips through encode and decode")
    func roundTrip() throws {
        let original = Member(
            id: "abc123",
            username: "jdoe",
            fullName: "Jane Doe",
            initials: "JD",
            bio: "Hello",
            url: "https://trello.com/jdoe",
            email: "jane@example.com",
            avatarUrl: nil,
            memberType: "normal",
            confirmed: true,
            status: "active"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Member.self, from: data)

        #expect(decoded == original)
    }
}
