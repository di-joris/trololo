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

        @Argument(help: "The card ID.")
        var id: String

        func run() async throws {
            let client = try CardCommand.makeClient()
            let card = try await client.getCard(id: id)
            Self.printCard(card)
        }

        private static func printCard(_ card: Card) {
            print("Name:          \(card.name ?? "—")")
            print("Description:   \(card.desc ?? "—")")
            print("Closed:        \(card.closed.map { String($0) } ?? "—")")
            print("Start:         \(card.start ?? "—")")
            print("Due:           \(card.due ?? "—")")
            print("Due Complete:  \(card.dueComplete.map { String($0) } ?? "—")")
            print("Board ID:      \(card.idBoard ?? "—")")
            print("List ID:       \(card.idList ?? "—")")
            print("Members:       \(card.idMembers.map { $0.joined(separator: ", ") } ?? "—")")
            print("Labels:        \(card.idLabels.map { $0.joined(separator: ", ") } ?? "—")")
            print("Last Activity: \(card.dateLastActivity ?? "—")")
            print("URL:           \(card.url ?? "—")")
            print("Short URL:     \(card.shortUrl ?? "—")")
            print("ID:            \(card.id)")
        }
    }
}
