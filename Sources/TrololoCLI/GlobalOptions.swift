import ArgumentParser

struct GlobalOptions: ParsableArguments {
    @Option(name: .long, help: "Output format (text, csv).")
    var outputFormat: OutputFormat = .text
}
