import ArgumentParser
import TrelloAPI

struct MemberCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "member",
        abstract: "Manage Trello members.",
        subcommands: [View.self, Boards.self, Cards.self, Organizations.self]
    )

    struct View: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Display a member's profile."
        )

        @OptionGroup var globalOptions: GlobalOptions

        @Argument(help: "Member ID or username (defaults to the authenticated user).")
        var id: String = "me"

        func run() async throws {
            let client = try ClientFactory.makeClient()
            let member = try await client.getMember(id: id)
            let output = CommandOutput.renderRecord(
                TrelloPresentation.memberFields(member),
                using: globalOptions.outputFormat.formatter
            )
            print(output)
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
            let client = try ClientFactory.makeClient()
            let boards = try await client.getMemberBoards(memberId: member)
            let output = CommandOutput.renderTable(
                TrelloPresentation.memberBoards(boards),
                using: globalOptions.outputFormat.formatter
            )
            print(output)
        }
    }

    struct Cards: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List cards the member is assigned to."
        )

        @OptionGroup var globalOptions: GlobalOptions

        @Option(name: [.short, .long], help: "Member ID or username (defaults to authenticated user).")
        var member: String = "me"

        func run() async throws {
            let client = try ClientFactory.makeClient()
            let cards = try await client.getMemberCards(memberId: member)
            let output = CommandOutput.renderTable(
                TrelloPresentation.memberCards(cards),
                using: globalOptions.outputFormat.formatter
            )
            print(output)
        }
    }

    struct Organizations: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "organizations",
            abstract: "List organizations (workspaces) the member belongs to.",
            aliases: ["orgs"]
        )

        @OptionGroup var globalOptions: GlobalOptions

        @Option(name: [.short, .long], help: "Member ID or username (defaults to authenticated user).")
        var member: String = "me"

        func run() async throws {
            let client = try ClientFactory.makeClient()
            let orgs = try await client.getMemberOrganizations(memberId: member)
            let output = CommandOutput.renderTable(
                TrelloPresentation.memberOrganizations(orgs),
                using: globalOptions.outputFormat.formatter
            )
            print(output)
        }
    }
}
