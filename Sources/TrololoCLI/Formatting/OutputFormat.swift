import ArgumentParser

enum OutputFormat: String, CaseIterable, ExpressibleByArgument, Sendable {
    case text
    case csv

    var formatter: OutputFormatter {
        switch self {
        case .text: TextFormatter()
        case .csv: CSVFormatter()
        }
    }
}
