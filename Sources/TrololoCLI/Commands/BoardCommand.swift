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
            let output = CommandOutput.renderRecord(
                TrelloPresentation.boardFields(board),
                using: globalOptions.outputFormat.formatter
            )
            print(output)
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
            let output = CommandOutput.renderTable(
                TrelloPresentation.boardLists(lists),
                using: globalOptions.outputFormat.formatter
            )
            print(output)
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
            let output = CommandOutput.renderTable(
                TrelloPresentation.boardCards(cards),
                using: globalOptions.outputFormat.formatter
            )
            print(output)
        }
    }
}
