import Testing
@testable import TrololoCLI
import TrelloAPI

@Suite("TrelloPresentation")
struct TrelloPresentationTests {
    @Test("Member fields preserve CLI field ordering")
    func memberFieldsKeepOrder() {
        let member = Member(
            id: "member-1",
            username: "joris",
            fullName: "Joris Example",
            initials: "JE",
            bio: "Swift developer",
            url: "https://trello.com/joris",
            email: "joris@example.com",
            memberType: "normal",
            status: "active"
        )

        let fields = TrelloPresentation.memberFields(member)

        #expect(fields.map { $0.label } == [
            "Username",
            "Full Name",
            "Initials",
            "Email",
            "Bio",
            "URL",
            "Type",
            "Status",
            "ID",
        ])
        #expect(fields.map { $0.value } == [
            "joris",
            "Joris Example",
            "JE",
            "joris@example.com",
            "Swift developer",
            "https://trello.com/joris",
            "normal",
            "active",
            "member-1",
        ])
    }

    @Test("Board presentations include board indicators and truncate long descriptions")
    func memberBoardsPresentation() throws {
        let board = Board(
            id: "board-1",
            name: "Roadmap",
            desc: String(repeating: "x", count: 45),
            closed: true,
            url: "https://trello.com/b/roadmap",
            shortUrl: "https://trello.com/b/r",
            pinned: true,
            starred: true
        )

        let presentation = TrelloPresentation.memberBoards([board])
        let row = try #require(presentation.rows.first)

        #expect(presentation.headers == ["Name", "Description", "Short URL", "ID"])
        #expect(row == [
            "Roadmap (closed, ★, 📌)",
            String(repeating: "x", count: 40) + "…",
            "https://trello.com/b/r",
            "board-1",
        ])
    }

    @Test(
        "Card presentations apply stable status suffixes",
        arguments: zip(
            [
                Card(id: "card-1", name: "Plain"),
                Card(id: "card-2", name: "Needs attention", due: "2026-03-08T12:30:00.000Z"),
                Card(id: "card-3", name: "Completed", due: "2026-03-08T12:30:00.000Z", dueComplete: true),
                Card(id: "card-4", name: "Archived", closed: true, due: "2026-03-08T12:30:00.000Z"),
            ],
            [
                "Plain",
                "Needs attention (due)",
                "Completed (done)",
                "Archived (closed, due)",
            ]
        )
    )
    func cardPresentationIndicators(card: Card, expectedName: String) throws {
        let presentation = TrelloPresentation.memberCards([card])
        let row = try #require(presentation.rows.first)

        #expect(row[0] == expectedName)
    }

    @Test("Member card presentations keep due date and board columns")
    func memberCardsPresentation() throws {
        let card = Card(
            id: "card-1",
            name: "Due soon",
            due: "2026-03-08T12:30:00.000Z",
            idBoard: "board-9"
        )

        let presentation = TrelloPresentation.memberCards([card])
        let row = try #require(presentation.rows.first)

        #expect(presentation.headers == ["Name", "Board ID", "Due", "ID"])
        #expect(row == ["Due soon (due)", "board-9", "2026-03-08", "card-1"])
    }

    @Test("Organization presentations use display name, slug, and board count")
    func organizationsPresentation() throws {
        let organization = Organization(
            id: "org-1",
            name: "eng",
            displayName: "Engineering",
            idBoards: ["b1", "b2", "b3"]
        )

        let presentation = TrelloPresentation.memberOrganizations([organization])
        let row = try #require(presentation.rows.first)

        #expect(row == ["Engineering", "eng", "3", "org-1"])
    }

    @Test("List presentations include closed state suffix")
    func boardListsPresentation() throws {
        let list = TrelloList(id: "list-1", name: "Done", closed: true)

        let presentation = TrelloPresentation.boardLists([list])
        let row = try #require(presentation.rows.first)

        #expect(row == ["Done (closed)", "list-1"])
    }

    @Test(
        "List presentations expose empty-state copy",
        arguments: [
            ("boards", TrelloPresentation.memberBoards([]).emptyMessage, "No boards found."),
            ("cards", TrelloPresentation.memberCards([]).emptyMessage, "No cards found."),
            ("organizations", TrelloPresentation.memberOrganizations([]).emptyMessage, "No organizations found."),
            ("lists", TrelloPresentation.boardLists([]).emptyMessage, "No lists found."),
        ]
    )
    func emptyMessages(_: String, actual: String, expected: String) {
        #expect(actual == expected)
    }
}
