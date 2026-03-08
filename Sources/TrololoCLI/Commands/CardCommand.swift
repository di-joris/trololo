import ArgumentParser
import TrelloAPI

struct CardCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "card",
        abstract: "Manage Trello cards.",
        subcommands: [View.self]
    )

    struct View: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Display details of a card."
        )

        @OptionGroup var globalOptions: GlobalOptions

        @Argument(help: "The card ID.")
        var id: String

        func run() async throws {
            let client = try ClientFactory.makeClient()
            let card = try await client.getCard(id: id)
            let output = CommandOutput.renderRecord(
                TrelloPresentation.cardFields(card),
                using: globalOptions.outputFormat.formatter
            )
            print(output)
        }
    }
}
