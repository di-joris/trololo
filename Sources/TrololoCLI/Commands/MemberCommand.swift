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
            let client = try ClientFactory.makeClient()
            let boards = try await client.getMemberBoards(memberId: member)

            if boards.isEmpty {
                print("No boards found.")
                return
            }

            let headers = ["Name", "Description", "Short URL", "ID"]
            let rows = boards.map { board -> [String] in
                let name = board.name ?? board.id
                var indicators: [String] = []
                if board.closed == true  { indicators.append("closed") }
                if board.starred == true { indicators.append("★") }
                if board.pinned  == true { indicators.append("📌") }
                let suffix = indicators.isEmpty ? "" : " (\(indicators.joined(separator: ", ")))"

                let desc = board.desc ?? ""
                let truncatedDesc = desc.count > 40 ? String(desc.prefix(40)) + "…" : desc

                let shortURL = board.shortUrl ?? board.url ?? "—"

                return ["\(name)\(suffix)", truncatedDesc, shortURL, board.id]
            }
            print(globalOptions.outputFormat.formatter.formatList(headers: headers, rows: rows))
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

            if cards.isEmpty {
                print("No cards found.")
                return
            }

            let headers = ["Name", "Board ID", "Due", "ID"]
            let rows = cards.map { card -> [String] in
                let name = card.name ?? card.id
                var indicators: [String] = []
                if card.closed == true                         { indicators.append("closed") }
                if card.due != nil && card.dueComplete != true { indicators.append("due") }
                if card.dueComplete == true                    { indicators.append("done") }
                let suffix = indicators.isEmpty ? "" : " (\(indicators.joined(separator: ", ")))"

                let due = card.due.map { String($0.prefix(10)) } ?? "—"
                return ["\(name)\(suffix)", card.idBoard ?? "—", due, card.id]
            }
            print(globalOptions.outputFormat.formatter.formatList(headers: headers, rows: rows))
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

            if orgs.isEmpty {
                print("No organizations found.")
                return
            }

            let headers = ["Display Name", "Slug", "Boards", "ID"]
            let rows = orgs.map { org -> [String] in
                let displayName = org.displayName ?? org.name ?? org.id
                let slug = org.name ?? "—"
                let boardCount = org.idBoards.map { String($0.count) } ?? "—"
                return [displayName, slug, boardCount, org.id]
            }
            print(globalOptions.outputFormat.formatter.formatList(headers: headers, rows: rows))
        }
    }
}
