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
            let fields = Self.listFields(list)
            print(globalOptions.outputFormat.formatter.formatRecord(fields: fields))
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
