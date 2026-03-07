import ArgumentParser
import TrelloAPI

struct BoardCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "board",
        abstract: "Manage Trello boards.",
        subcommands: [Cards.self]
    )

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
