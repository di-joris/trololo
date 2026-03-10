import Testing
import Foundation
@testable import TrelloAPI

@Suite("Label model decoding")
struct LabelDecodingTests {
    @Test("Decodes a complete label JSON")
    func fullLabel() throws {
        let json = """
        {
            "id": "5abbe4b7ddc1b351ef961414",
            "idBoard": "board123",
            "name": "Overdue",
            "color": "red"
        }
        """.data(using: .utf8)!

        let label = try JSONDecoder().decode(Label.self, from: json)

        #expect(label.id == "5abbe4b7ddc1b351ef961414")
        #expect(label.idBoard == "board123")
        #expect(label.name == "Overdue")
        #expect(label.color == "red")
    }

    @Test("Decodes a minimal label JSON with only required fields")
    func minimalLabel() throws {
        let json = """
        { "id": "abc123" }
        """.data(using: .utf8)!

        let label = try JSONDecoder().decode(Label.self, from: json)

        #expect(label.id == "abc123")
        #expect(label.idBoard == nil)
        #expect(label.name == nil)
        #expect(label.color == nil)
    }

    @Test("Decodes a label with null color and name")
    func nullFields() throws {
        let json = """
        { "id": "abc123", "name": null, "color": null }
        """.data(using: .utf8)!

        let label = try JSONDecoder().decode(Label.self, from: json)

        #expect(label.id == "abc123")
        #expect(label.name == nil)
        #expect(label.color == nil)
    }

    @Test("Round-trips through encode and decode")
    func roundTrip() throws {
        let original = Label(
            id: "abc123",
            idBoard: "board456",
            name: "Priority",
            color: "green"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Label.self, from: data)

        #expect(decoded == original)
    }
}

@Suite("Labels API endpoint")
struct LabelsAPITests {
    @Test("getLabel sends request to /labels/{id}")
    func getLabelById() async throws {
        let labelJSON = """
        { "id": "label123", "name": "Urgent", "color": "red" }
        """.data(using: .utf8)!

        let capture = RequestCapture()
        let mock = MockHTTPClient.capturing(into: capture, data: labelJSON)
        let client = TrelloClient(apiKey: "key", apiToken: "token", httpClient: mock)

        let label = try await client.getLabel(id: "label123")

        #expect(label.id == "label123")
        #expect(label.name == "Urgent")
        #expect(label.color == "red")

        let requests = await capture.requests
        let url = try #require(requests.first?.url)
        #expect(url.path.hasSuffix("/labels/label123"))
    }
}

@Suite("Board Labels API endpoint")
struct BoardLabelsAPITests {
    @Test("getBoardLabels sends request to /boards/{id}/labels")
    func getBoardLabels() async throws {
        let labelsJSON = """
        [
            { "id": "label1", "name": "Bug", "color": "red" },
            { "id": "label2", "name": "Feature", "color": "green" }
        ]
        """.data(using: .utf8)!

        let capture = RequestCapture()
        let mock = MockHTTPClient.capturing(into: capture, data: labelsJSON)
        let client = TrelloClient(apiKey: "key", apiToken: "token", httpClient: mock)

        let labels = try await client.getBoardLabels(boardId: "board123")

        #expect(labels.count == 2)
        #expect(labels[0].id == "label1")
        #expect(labels[0].name == "Bug")
        #expect(labels[0].color == "red")
        #expect(labels[1].id == "label2")
        #expect(labels[1].name == "Feature")
        #expect(labels[1].color == "green")

        let requests = await capture.requests
        let url = try #require(requests.first?.url)
        #expect(url.path.hasSuffix("/boards/board123/labels"))
    }
}
