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

        @OptionGroup var globalOptions: GlobalOptions

        func run() async throws {
            let client = try MemberCommand.makeClient()
            let member = try await client.getMember(id: "me")
            let fields = Self.memberFields(member)
            print(globalOptions.outputFormat.formatter.formatRecord(fields: fields))
        }

        static func memberFields(_ member: Member) -> [(label: String, value: String)] {
            [
                ("Username", member.username ?? "—"),
                ("Full Name", member.fullName ?? "—"),
                ("Initials", member.initials ?? "—"),
                ("Email", member.email ?? "—"),
                ("Bio", member.bio ?? "—"),
                ("URL", member.url ?? "—"),
                ("Type", member.memberType ?? "—"),
                ("Status", member.status ?? "—"),
                ("ID", member.id),
            ]
        }
    }

    struct Boards: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List boards the member belongs to."
        )

        @OptionGroup var globalOptions: GlobalOptions

        @Option(name: [.short, .long], help: "Member ID or username (defaults to authenticated user).")
        var member: String = "me"

        func run() async throws {
            let client = try MemberCommand.makeClient()
            let boards = try await client.getMemberBoards(memberId: member)

            if boards.isEmpty {
                print("No boards found.")
                return
            }

            let headers = ["Name", "ID"]
            let rows = boards.map { board -> [String] in
                let name = board.name ?? board.id
                var indicators: [String] = []
                if board.closed == true { indicators.append("closed") }
                if board.starred == true { indicators.append("★") }
                let suffix = indicators.isEmpty ? "" : " (\(indicators.joined(separator: ", ")))"
                return ["\(name)\(suffix)", board.id]
            }
            print(globalOptions.outputFormat.formatter.formatList(headers: headers, rows: rows))
        }
    }
}
