import ArgumentParser
import TrelloAPI
import Foundation

struct MemberCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "member",
        abstract: "Manage Trello members.",
        subcommands: [Me.self]
    )

    struct Me: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Display the authenticated member's profile."
        )

        func run() async throws {
            let client = try Self.makeClient()
            let member = try await client.getMember(id: "me")
            Self.printMember(member)
        }

        private static func makeClient() throws -> TrelloClient {
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

        private static func printMember(_ member: Member) {
            print("Username:  \(member.username ?? "—")")
            print("Full Name: \(member.fullName ?? "—")")
            print("Initials:  \(member.initials ?? "—")")
            print("Email:     \(member.email ?? "—")")
            print("Bio:       \(member.bio ?? "—")")
            print("URL:       \(member.url ?? "—")")
            print("Type:      \(member.memberType ?? "—")")
            print("Status:    \(member.status ?? "—")")
            print("ID:        \(member.id)")
        }
    }
}
