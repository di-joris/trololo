import ArgumentParser
import TrelloAPI
import Foundation

struct CardCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "card",
        abstract: "Manage Trello cards.",
        subcommands: [View.self]
    )

    private static func makeClient() throws -> TrelloClient {
        Environment.load()

        guard let apiKey = ProcessInfo.processInfo.environment["TRELLO_API_KEY"],
              !apiKey.isEmpty else {
            throw TrelloAPIError.missingCredentials
        }
        guard let apiToken = ProcessInfo.processInfo.environment["TRELLO_API_TOKEN"],
              !apiToken.isEmpty else {
            throw TrelloAPIError.missingCredentials
        }
        return TrelloClient(apiKey: apiKey, apiToken: apiToken)
    }

    struct View: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Display details of a card."
        )

        @OptionGroup var globalOptions: GlobalOptions

        @Argument(help: "The card ID.")
        var id: String

        func run() async throws {
            let client = try CardCommand.makeClient()
            let card = try await client.getCard(id: id)
            let fields = Self.cardFields(card)
            print(globalOptions.outputFormat.formatter.formatRecord(fields: fields))
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
    }
}
