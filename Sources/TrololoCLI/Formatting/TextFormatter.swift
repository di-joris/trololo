struct TextFormatter: OutputFormatter {
    func formatRecord(fields: [(label: String, value: String)]) -> String {
        guard !fields.isEmpty else { return "" }

        let maxLabelWidth = fields.map { $0.label.count + 1 }.max()! // +1 for the colon
        return fields.map { field in
            let labelWithColon = "\(field.label):"
            let padded = labelWithColon.padding(toLength: maxLabelWidth + 1, withPad: " ", startingAt: 0)
            return "\(padded)\(field.value)"
        }.joined(separator: "\n")
    }

    func formatList(headers: [String], rows: [[String]]) -> String {
        rows.map { $0.joined(separator: "\t") }.joined(separator: "\n")
    }
}
