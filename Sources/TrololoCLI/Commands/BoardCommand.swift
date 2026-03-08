import ArgumentParser
import TrelloAPI

struct BoardCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "board",
        abstract: "Manage Trello boards.",
        subcommands: [View.self, Cards.self, Lists.self]
    )

    struct View: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Display details of a board."
        )

        @OptionGroup var globalOptions: GlobalOptions

        @Argument(help: "The board ID.")
        var id: String

        func run() async throws {
            let client = try ClientFactory.makeClient()
            let board = try await client.getBoard(id: id)
            let fields = Self.boardFields(board)
            print(globalOptions.outputFormat.formatter.formatRecord(fields: fields))
        }

        static func boardFields(_ board: Board) -> [(label: String, value: String)] {
            [
                ("Name",         board.name         ?? "—"),
                ("Description",  board.desc         ?? "—"),
                ("Closed",       board.closed.map { String($0) } ?? "—"),
                ("Starred",      board.starred.map { String($0) } ?? "—"),
                ("Pinned",       board.pinned.map  { String($0) } ?? "—"),
                ("Organization", board.idOrganization ?? "—"),
                ("URL",          board.url          ?? "—"),
                ("Short URL",    board.shortUrl     ?? "—"),
                ("ID",           board.id),
            ]
        }
    }

    struct Lists: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List all lists on a board."
        )

        @OptionGroup var globalOptions: GlobalOptions
        @Argument(help: "The board ID.")
        var id: String

        func run() async throws {
            let client = try ClientFactory.makeClient()
            let lists = try await client.getBoardLists(boardId: id)

            if lists.isEmpty {
                print("No lists found.")
                return
            }

            let headers = ["Name", "ID"]
            let rows = lists.map { list -> [String] in
                let name = list.name ?? list.id
                var indicators: [String] = []
                if list.closed == true { indicators.append("closed") }
                let suffix = indicators.isEmpty ? "" : " (\(indicators.joined(separator: ", ")))"
                return ["\(name)\(suffix)", list.id]
            }
            print(globalOptions.outputFormat.formatter.formatList(headers: headers, rows: rows))
        }
    }

    struct Cards: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List all cards on a board."
        )

        @OptionGroup var globalOptions: GlobalOptions

        @Argument(help: "The board ID.")
        var id: String

        func run() async throws {
            let client = try ClientFactory.makeClient()
            let cards = try await client.getBoardCards(boardId: id)

            if cards.isEmpty {
                print("No cards found.")
                return
            }

            let headers = ["Name", "ID"]
            let rows = cards.map { card -> [String] in
                let name = card.name ?? card.id
                var indicators: [String] = []
                if card.closed == true { indicators.append("closed") }
                if card.due != nil && card.dueComplete != true { indicators.append("due") }
                if card.dueComplete == true { indicators.append("done") }
                let suffix = indicators.isEmpty ? "" : " (\(indicators.joined(separator: ", ")))"
                return ["\(name)\(suffix)", card.id]
            }
            print(globalOptions.outputFormat.formatter.formatList(headers: headers, rows: rows))
        }
    }
}
