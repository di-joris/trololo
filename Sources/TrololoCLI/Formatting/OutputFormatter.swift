protocol OutputFormatter: Sendable {
    func formatRecord(fields: [(label: String, value: String)]) -> String
    func formatList(headers: [String], rows: [[String]]) -> String
}
