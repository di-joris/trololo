import ArgumentParser

@main
struct TrelloCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "trello",
        abstract: "A command-line tool for Trello.",
        subcommands: [MemberCommand.self]
    )
}
