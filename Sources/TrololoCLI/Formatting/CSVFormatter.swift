struct CSVFormatter: OutputFormatter {
    func formatRecord(fields: [(label: String, value: String)]) -> String {
        guard !fields.isEmpty else { return "" }

        let headerRow = fields.map { escapeCSV($0.label) }.joined(separator: ",")
        let dataRow = fields.map { escapeCSV($0.value) }.joined(separator: ",")
        return "\(headerRow)\n\(dataRow)"
    }

    func formatList(headers: [String], rows: [[String]]) -> String {
        var lines: [String] = []
        lines.append(headers.map { escapeCSV($0) }.joined(separator: ","))
        for row in rows {
            lines.append(row.map { escapeCSV($0) }.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
