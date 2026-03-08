import ArgumentParser
import TrelloAPI

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "Manage Trello lists.",
        subcommands: [View.self, Cards.self]
    )

    struct View: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Display details of a list."
        )

        @OptionGroup var globalOptions: GlobalOptions
        @Argument(help: "The list ID.")
        var id: String

        func run() async throws {
            let client = try ClientFactory.makeClient()
            let list = try await client.getList(id: id)
            let output = CommandOutput.renderRecord(
                TrelloPresentation.listFields(list),
                using: globalOptions.outputFormat.formatter
            )
            print(output)
        }
    }

    struct Cards: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List all cards in a list."
        )

        @OptionGroup var globalOptions: GlobalOptions
        @Argument(help: "The list ID.")
        var id: String

        func run() async throws {
            let client = try ClientFactory.makeClient()
            let cards = try await client.getListCards(listId: id)
            let output = CommandOutput.renderTable(
                TrelloPresentation.listCards(cards),
                using: globalOptions.outputFormat.formatter
            )
            print(output)
        }
    }
}
