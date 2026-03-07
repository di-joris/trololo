# Spec: `member cards`

## Summary

Add a `member cards` subcommand that lists all cards a member is assigned to.

## Motivation

Users frequently want to see their own (or another member's) assigned cards across all boards. This maps directly to the Trello API's `GET /members/{id}/cards` endpoint.

## Command Signature

```
trololo member cards [--member <id>] [--format text|csv]
```

### Options

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--member` | `-m` | `"me"` | Member ID or username. Defaults to the authenticated user. |
| `--format` | | `text` | Output format. Inherited from `GlobalOptions`. |

## API

**Endpoint:** `GET https://api.trello.com/1/members/{id}/cards`

**OpenAPI summary:** "Get Cards the Member is on"

**Query parameters used:**

| Parameter | Value | Notes |
|-----------|-------|-------|
| `filter` | *(omitted)* | Defaults to `visible` on the API side, which returns open cards the member is assigned to. |

**New TrelloAPI library method:**

```swift
extension TrelloClient {
    /// Fetches cards the member is assigned to.
    ///
    /// - Parameter memberId: The member ID or `"me"` for the authenticated user.
    /// - Returns: The member's cards.
    public func getMemberCards(memberId: String = "me") async throws -> [Card] {
        try await get([Card].self, path: "/members/\(memberId)/cards")
    }
}
```

## Model

No new model required. Uses the existing `Card` model.

Relevant `Card` fields for display:

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | Always present |
| `name` | `String?` | Card title |
| `idBoard` | `String?` | Board the card belongs to |
| `idList` | `String?` | List the card is in |
| `due` | `String?` | ISO-8601 due date string (or nil) |
| `dueComplete` | `Bool?` | Whether the due date is marked complete |
| `closed` | `Bool?` | Whether the card is archived |

## Output Format

Display as a **table**, consistent with other list commands (`member boards`, `board cards`).

### Text format (default)

```
Name                        Board ID                  Due          ID
Fix login bug (due)         5e9b4c2a1d3f8a0b2c4d6e8f  2024-03-15   6f0c5d3b2e4g9b1c3d5e7f9a
Write release notes (done)  5e9b4c2a1d3f8a0b2c4d6e8f  2024-03-10   7a1d6e4c3f5h0c2d4e6f8g0b
Design new logo             6f0c5d3b2e4g9b1c3d5e7f9a  —            8b2e7f5d4g6i1d3e5f7g9h1c
```

Column definitions:

| Column | Source | Notes |
|--------|--------|-------|
| Name | `card.name ?? card.id` | Appends `(closed)` if `card.closed == true`, `(due)` if `card.due != nil && card.dueComplete != true`, `(done)` if `card.dueComplete == true` |
| Board ID | `card.idBoard ?? "—"` | Raw board ID (board name resolution is out of scope) |
| Due | First 10 chars of `card.due` (date part of ISO-8601), or `"—"` | Trims time component for readability |
| ID | `card.id` | Always present |

**Headers:** `["Name", "Board ID", "Due", "ID"]`

**Empty state:** Print `"No cards found."` if the response array is empty.

### CSV format

Same four columns, full ISO-8601 due date string (not truncated).

## Implementation Plan

### Files to create/modify

| File | Change |
|------|--------|
| `Sources/TrelloAPI/Endpoints/MembersAPI.swift` | Add `getMemberCards(memberId:)` method |
| `Sources/trololo/Commands/MemberCommand.swift` | Add `Cards` substruct; register in `subcommands` |
| `Tests/TrelloAPITests/TrelloClientTests.swift` | Add test for `getMemberCards` endpoint path |

### MemberCommand.swift addition

```swift
struct Cards: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List cards the member is assigned to."
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: [.short, .long], help: "Member ID or username (defaults to authenticated user).")
    var member: String = "me"

    func run() async throws {
        let client = try ClientFactory.makeClient()
        let cards = try await client.getMemberCards(memberId: member)

        if cards.isEmpty {
            print("No cards found.")
            return
        }

        let headers = ["Name", "Board ID", "Due", "ID"]
        let rows = cards.map { card -> [String] in
            let name = card.name ?? card.id
            var indicators: [String] = []
            if card.closed == true                                   { indicators.append("closed") }
            if card.due != nil && card.dueComplete != true           { indicators.append("due") }
            if card.dueComplete == true                              { indicators.append("done") }
            let suffix = indicators.isEmpty ? "" : " (\(indicators.joined(separator: ", ")))"

            let due = card.due.map { String($0.prefix(10)) } ?? "—"
            return ["\(name)\(suffix)", card.idBoard ?? "—", due, card.id]
        }
        print(globalOptions.outputFormat.formatter.formatList(headers: headers, rows: rows))
    }
}
```

Register in the parent `MemberCommand`:

```swift
subcommands: [View.self, Boards.self, Cards.self, Organizations.self]
```

## Error Handling

- Unknown member → HTTP 404 → `TrelloAPIError.httpError`.
- No credentials → `TrelloAPIError.missingCredentials`.

## Testing

- Unit test: `getMemberCards(memberId:)` sends request to `/members/me/cards` when called with default.
- Unit test: `getMemberCards(memberId: "johndoe")` sends request to `/members/johndoe/cards`.
- Unit test: Card decoding with `due`, `dueComplete`, and `idBoard` fields.

## Open Questions / Out of Scope

- **Filtering by status:** An optional `--filter` flag (e.g. `--filter open`) is intentionally omitted from v1 to keep the interface simple.
- **Board name resolution:** Displaying board names instead of IDs would require additional API calls; deferred to a future enhancement.
- **Sorting:** Cards are returned in the API's default order (by board and position); no client-side sorting.
