import ArgumentParser

@main
struct TrololoCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "trololo",
        abstract: "A command-line tool for Trello.",
        subcommands: [MemberCommand.self, BoardCommand.self, CardCommand.self, ListCommand.self]
    )
}
