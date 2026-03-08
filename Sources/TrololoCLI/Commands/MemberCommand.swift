import ArgumentParser
import TrelloAPI
import Foundation

struct MemberCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "member",
        abstract: "Manage Trello members.",
        subcommands: [Me.self, Boards.self]
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

    struct Me: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Display the authenticated member's profile."
        )

        func run() async throws {
            let client = try MemberCommand.makeClient()
            let member = try await client.getMember(id: "me")
            Self.printMember(member)
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

    struct Boards: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List boards the member belongs to."
        )

        @Option(name: [.short, .long], help: "Member ID or username (defaults to authenticated user).")
        var member: String = "me"

        func run() async throws {
            let client = try MemberCommand.makeClient()
            let boards = try await client.getMemberBoards(memberId: member)

            if boards.isEmpty {
                print("No boards found.")
                return
            }

            for board in boards {
                let name = board.name ?? board.id
                var indicators: [String] = []
                if board.closed == true { indicators.append("closed") }
                if board.starred == true { indicators.append("★") }
                let suffix = indicators.isEmpty ? "" : " (\(indicators.joined(separator: ", ")))"
                print("\(name)\(suffix)")
            }
        }
    }
}
