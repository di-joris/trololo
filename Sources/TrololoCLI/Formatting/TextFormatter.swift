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
        guard !rows.isEmpty else { return "" }

        let columnCount = max(headers.count, rows.map(\.count).max() ?? 0)
        guard columnCount > 0 else { return "" }

        let normalizedHeaders = normalized(headers, columnCount: columnCount)
        let normalizedRows = rows.map { normalized($0, columnCount: columnCount) }

        var widths = Array(repeating: 0, count: columnCount)
        for cells in [normalizedHeaders] + normalizedRows {
            for (index, cell) in cells.enumerated() {
                widths[index] = max(widths[index], cell.count)
            }
        }

        func renderRow(_ cells: [String]) -> String {
            cells.enumerated().map { index, cell in
                if index == columnCount - 1 {
                    return cell
                }
                return cell.padding(toLength: widths[index], withPad: " ", startingAt: 0)
            }.joined(separator: "  ")
        }

        if headers.isEmpty {
            return normalizedRows.map(renderRow).joined(separator: "\n")
        }

        let separator = widths.map { String(repeating: "-", count: $0) }
        return ([renderRow(normalizedHeaders), renderRow(separator)] + normalizedRows.map(renderRow))
            .joined(separator: "\n")
    }

    private func normalized(_ cells: [String], columnCount: Int) -> [String] {
        cells + Array(repeating: "", count: max(0, columnCount - cells.count))
    }
}
