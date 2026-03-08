import Testing
@testable import TrololoCLI

@Suite("OutputFormatter")
struct FormatterTests {

    // MARK: - TextFormatter — Record

    @Test("Text record pads labels to uniform width")
    func textRecordAlignment() {
        let formatter = TextFormatter()
        let fields: [(label: String, value: String)] = [
            ("Name", "Alice"),
            ("Full Name", "Alice Smith"),
            ("ID", "abc123"),
        ]
        let result = formatter.formatRecord(fields: fields)
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count == 3)
        #expect(lines[0] == "Name:      Alice")
        #expect(lines[1] == "Full Name: Alice Smith")
        #expect(lines[2] == "ID:        abc123")
    }

    @Test("Text record with single field has no padding beyond colon")
    func textRecordSingleField() {
        let formatter = TextFormatter()
        let result = formatter.formatRecord(fields: [("Name", "Alice")])
        #expect(result == "Name: Alice")
    }

    @Test("Text record with empty fields returns empty string")
    func textRecordEmpty() {
        let formatter = TextFormatter()
        #expect(formatter.formatRecord(fields: []) == "")
    }

    // MARK: - TextFormatter — List

    @Test("Text list renders aligned columns with headers")
    func textListBasic() {
        let formatter = TextFormatter()
        let result = formatter.formatList(
            headers: ["Name", "ID"],
            rows: [["Board A", "id1"], ["Board B", "id2"]]
        )
        #expect(result == """
        Name     ID
        -------  ---
        Board A  id1
        Board B  id2
        """)
    }

    @Test("Text list aligns to the widest cell in each column")
    func textListAlignment() {
        let formatter = TextFormatter()
        let result = formatter.formatList(
            headers: ["Name", "Board ID"],
            rows: [["Short", "b1"], ["Longer board name", "board-123"]]
        )

        #expect(result == """
        Name               Board ID
        -----------------  ---------
        Short              b1
        Longer board name  board-123
        """)
    }

    @Test("Text list with empty rows returns empty string")
    func textListEmpty() {
        let formatter = TextFormatter()
        #expect(formatter.formatList(headers: ["H"], rows: []) == "")
    }

    // MARK: - CSVFormatter — Record

    @Test("CSV record outputs header row and data row")
    func csvRecordBasic() {
        let formatter = CSVFormatter()
        let result = formatter.formatRecord(fields: [
            ("Name", "Alice"),
            ("Email", "alice@example.com"),
        ])
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count == 2)
        #expect(lines[0] == "Name,Email")
        #expect(lines[1] == "Alice,alice@example.com")
    }

    @Test("CSV record with empty fields returns empty string")
    func csvRecordEmpty() {
        let formatter = CSVFormatter()
        #expect(formatter.formatRecord(fields: []) == "")
    }

    // MARK: - CSVFormatter — List

    @Test("CSV list includes header row")
    func csvListWithHeaders() {
        let formatter = CSVFormatter()
        let result = formatter.formatList(
            headers: ["Name", "ID"],
            rows: [["Board A", "id1"], ["Board B", "id2"]]
        )
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count == 3)
        #expect(lines[0] == "Name,ID")
        #expect(lines[1] == "Board A,id1")
        #expect(lines[2] == "Board B,id2")
    }

    // MARK: - CSVFormatter — Escaping

    @Test("CSV escapes fields containing commas")
    func csvEscapesCommas() {
        let formatter = CSVFormatter()
        let result = formatter.formatRecord(fields: [("Label", "one, two")])
        #expect(result.contains("\"one, two\""))
    }

    @Test("CSV escapes fields containing double quotes")
    func csvEscapesQuotes() {
        let formatter = CSVFormatter()
        let result = formatter.formatRecord(fields: [("Label", "say \"hello\"")])
        #expect(result.contains("\"say \"\"hello\"\"\""))
    }

    @Test("CSV escapes fields containing newlines")
    func csvEscapesNewlines() {
        let formatter = CSVFormatter()
        let result = formatter.formatRecord(fields: [("Label", "line1\nline2")])
        #expect(result.contains("\"line1\nline2\""))
    }

    @Test("CSV does not quote plain fields")
    func csvNoUnnecessaryQuoting() {
        let formatter = CSVFormatter()
        let result = formatter.formatRecord(fields: [("Name", "Alice")])
        #expect(result == "Name\nAlice")
    }

    // MARK: - OutputFormat enum

    @Test("OutputFormat text returns TextFormatter", arguments: [
        (OutputFormat.text, "TextFormatter"),
        (OutputFormat.csv, "CSVFormatter"),
    ])
    func outputFormatReturnsCorrectFormatter(format: OutputFormat, expectedType: String) {
        let formatter = format.formatter
        #expect(String(describing: type(of: formatter)) == expectedType)
    }
}
