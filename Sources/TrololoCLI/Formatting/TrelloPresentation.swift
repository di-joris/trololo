import TrelloAPI

struct TablePresentation: Sendable, Equatable {
    let headers: [String]
    let rows: [[String]]
    let emptyMessage: String

    var isEmpty: Bool {
        rows.isEmpty
    }
}

enum CommandOutput {
    static func renderRecord(
        _ fields: [(label: String, value: String)],
        using formatter: some OutputFormatter
    ) -> String {
        formatter.formatRecord(fields: fields)
    }

    static func renderTable(
        _ presentation: TablePresentation,
        using formatter: some OutputFormatter
    ) -> String {
        guard !presentation.isEmpty else { return presentation.emptyMessage }
        return formatter.formatList(headers: presentation.headers, rows: presentation.rows)
    }
}

enum TrelloPresentation {
    static func memberFields(_ member: Member) -> [(label: String, value: String)] {
        [
            ("Username", member.username ?? "—"),
            ("Full Name", member.fullName ?? "—"),
            ("Initials", member.initials ?? "—"),
            ("Email", member.email ?? "—"),
            ("Bio", member.bio ?? "—"),
            ("URL", member.url ?? "—"),
            ("Type", member.memberType ?? "—"),
            ("Status", member.status ?? "—"),
            ("ID", member.id),
        ]
    }

    static func boardFields(_ board: Board) -> [(label: String, value: String)] {
        [
            ("Name", board.name ?? "—"),
            ("Description", board.desc ?? "—"),
            ("Closed", board.closed.map { String($0) } ?? "—"),
            ("Starred", board.starred.map { String($0) } ?? "—"),
            ("Pinned", board.pinned.map { String($0) } ?? "—"),
            ("Organization", board.idOrganization ?? "—"),
            ("URL", board.url ?? "—"),
            ("Short URL", board.shortUrl ?? "—"),
            ("ID", board.id),
        ]
    }

    static func cardFields(_ card: Card) -> [(label: String, value: String)] {
        [
            ("Name", card.name ?? "—"),
            ("Description", card.desc ?? "—"),
            ("Closed", card.closed.map { String($0) } ?? "—"),
            ("Start", card.start ?? "—"),
            ("Due", card.due ?? "—"),
            ("Due Complete", card.dueComplete.map { String($0) } ?? "—"),
            ("Board ID", card.idBoard ?? "—"),
            ("List ID", card.idList ?? "—"),
            ("Members", card.idMembers.map { $0.joined(separator: ", ") } ?? "—"),
            ("Labels", card.idLabels.map { $0.joined(separator: ", ") } ?? "—"),
            ("Last Activity", card.dateLastActivity ?? "—"),
            ("URL", card.url ?? "—"),
            ("Short URL", card.shortUrl ?? "—"),
            ("ID", card.id),
        ]
    }

    static func listFields(_ list: TrelloList) -> [(label: String, value: String)] {
        [
            ("Name", list.name ?? "—"),
            ("Closed", list.closed.map { String($0) } ?? "—"),
            ("Position", list.pos.map { String($0) } ?? "—"),
            ("Board ID", list.idBoard ?? "—"),
            ("Subscribed", list.subscribed.map { String($0) } ?? "—"),
            ("ID", list.id),
        ]
    }

    static func memberBoards(_ boards: [Board]) -> TablePresentation {
        TablePresentation(
            headers: ["Name", "Description", "Short URL", "ID"],
            rows: boards.map(boardRow),
            emptyMessage: "No boards found."
        )
    }

    static func memberCards(_ cards: [Card]) -> TablePresentation {
        TablePresentation(
            headers: ["Name", "Board ID", "Due", "ID"],
            rows: cards.map(memberCardRow),
            emptyMessage: "No cards found."
        )
    }

    static func memberOrganizations(_ organizations: [Organization]) -> TablePresentation {
        TablePresentation(
            headers: ["Display Name", "Slug", "Boards", "ID"],
            rows: organizations.map(organizationRow),
            emptyMessage: "No organizations found."
        )
    }

    static func boardLists(_ lists: [TrelloList]) -> TablePresentation {
        TablePresentation(
            headers: ["Name", "ID"],
            rows: lists.map(listRow),
            emptyMessage: "No lists found."
        )
    }

    static func boardCards(_ cards: [Card]) -> TablePresentation {
        TablePresentation(
            headers: ["Name", "ID"],
            rows: cards.map(simpleCardRow),
            emptyMessage: "No cards found."
        )
    }

    static func listCards(_ cards: [Card]) -> TablePresentation {
        TablePresentation(
            headers: ["Name", "ID"],
            rows: cards.map(simpleCardRow),
            emptyMessage: "No cards found."
        )
    }

    private static func boardRow(_ board: Board) -> [String] {
        [
            displayName(board.name, fallback: board.id, indicators: boardIndicators(for: board)),
            truncated(board.desc ?? "", maxLength: 40),
            board.shortUrl ?? board.url ?? "—",
            board.id,
        ]
    }

    private static func memberCardRow(_ card: Card) -> [String] {
        [
            displayName(card.name, fallback: card.id, indicators: cardIndicators(for: card)),
            card.idBoard ?? "—",
            card.due.map { String($0.prefix(10)) } ?? "—",
            card.id,
        ]
    }

    private static func simpleCardRow(_ card: Card) -> [String] {
        [
            displayName(card.name, fallback: card.id, indicators: cardIndicators(for: card)),
            card.id,
        ]
    }

    private static func organizationRow(_ organization: Organization) -> [String] {
        let displayName = organization.displayName ?? organization.name ?? organization.id
        let slug = organization.name ?? "—"
        let boardCount = organization.idBoards.map { String($0.count) } ?? "—"
        return [displayName, slug, boardCount, organization.id]
    }

    private static func listRow(_ list: TrelloList) -> [String] {
        [
            displayName(list.name, fallback: list.id, indicators: listIndicators(for: list)),
            list.id,
        ]
    }

    private static func displayName(_ primary: String?, fallback: String, indicators: [String]) -> String {
        let base = primary ?? fallback
        guard !indicators.isEmpty else { return base }
        return "\(base) (\(indicators.joined(separator: ", ")))"
    }

    private static func boardIndicators(for board: Board) -> [String] {
        var indicators: [String] = []
        if board.closed == true { indicators.append("closed") }
        if board.starred == true { indicators.append("★") }
        if board.pinned == true { indicators.append("📌") }
        return indicators
    }

    private static func cardIndicators(for card: Card) -> [String] {
        var indicators: [String] = []
        if card.closed == true { indicators.append("closed") }
        if card.due != nil && card.dueComplete != true { indicators.append("due") }
        if card.dueComplete == true { indicators.append("done") }
        return indicators
    }

    private static func listIndicators(for list: TrelloList) -> [String] {
        var indicators: [String] = []
        if list.closed == true { indicators.append("closed") }
        return indicators
    }

    private static func truncated(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }
        return String(text.prefix(maxLength)) + "…"
    }
}
