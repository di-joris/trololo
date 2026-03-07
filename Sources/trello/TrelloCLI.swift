import ArgumentParser

@main
struct TrelloCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "trello",
        abstract: "A command-line tool for Trello"
    )
}
