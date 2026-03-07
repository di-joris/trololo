import ArgumentParser
import TrelloAPI
import Foundation

struct BoardCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "board",
        abstract: "Manage Trello boards.",
        subcommands: [Cards.self]
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

    struct Cards: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List all cards on a board."
        )

        @Argument(help: "The board ID.")
        var id: String

        func run() async throws {
            let client = try BoardCommand.makeClient()
            let cards = try await client.getBoardCards(boardId: id)

            if cards.isEmpty {
                print("No cards found.")
                return
            }

            for card in cards {
                let name = card.name ?? card.id
                var indicators: [String] = []
                if card.closed == true { indicators.append("closed") }
                if card.due != nil && card.dueComplete != true { indicators.append("due") }
                if card.dueComplete == true { indicators.append("done") }
                let suffix = indicators.isEmpty ? "" : " (\(indicators.joined(separator: ", ")))"
                print("\(name)\(suffix)\t\(card.id)")
            }
        }
    }
}
