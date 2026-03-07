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
