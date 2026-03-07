# Spec: `board view <id>`

## Summary

Add a `board view <id>` subcommand that fetches and displays detailed information about a single Trello board by its ID.

## Motivation

`board` currently only has `board cards`. Users need a way to inspect a board's metadata (name, description, URL, organization, status, etc.) directly from the CLI.

## Command Signature

```
trololo board view <id> [--format text|csv]
```

### Arguments

| Name | Required | Description |
|------|----------|-------------|
| `id` | Yes | The board ID (24-character Trello ID). |

### Options

Inherits the shared `--format` option from `GlobalOptions` (via `@OptionGroup`).

## API

**Endpoint:** `GET https://api.trello.com/1/boards/{id}`

**OpenAPI summary:** "Get a Board"

**New TrelloAPI library method:**

```swift
extension TrelloClient {
    public func getBoard(id: String) async throws -> Board {
        try await get(Board.self, path: "/boards/\(id)")
    }
}
```

No additional query parameters are required for the default use case; the endpoint returns all standard board fields without needing `fields=all`.

## Model Changes

The existing `Board` model already covers the required fields. No new model fields are needed for this command, but future work may add `dateLastActivity`, `dateLastView`, `shortLink`, etc. if the API returns them.

Current `Board` fields used:

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | Always present |
| `name` | `String?` | Display name |
| `desc` | `String?` | Board description |
| `closed` | `Bool?` | Archived status |
| `url` | `String?` | Full URL |
| `shortUrl` | `String?` | Short URL |
| `idOrganization` | `String?` | ID of the owning workspace |
| `pinned` | `Bool?` | Pinned to home screen |
| `starred` | `Bool?` | Starred by the authenticated user |

## Output Format

Display as a **record** (key–value pairs), consistent with `card view` and `member view`.

### Text format (default)

```
Name          My Project Board
Description   Track all tasks for Q1
Closed        false
Starred       true
Pinned        false
Organization  5e9b4c2a1d3f8a0b2c4d6e8f
URL           https://trello.com/b/AbCdEfGh/my-project-board
Short URL     https://trello.com/b/AbCdEfGh
ID            5e9b4c2a1d3f8a0b2c4d6e8f
```

Fields shown (in order):

1. Name
2. Description
3. Closed (bool as string, or `—` if nil)
4. Starred (bool as string, or `—` if nil)
5. Pinned (bool as string, or `—` if nil)
6. Organization (value of `idOrganization`, or `—`)
7. URL
8. Short URL
9. ID

Missing optional fields display as `—` (em dash), consistent with the rest of the CLI.

## Implementation Plan

### Files to create/modify

| File | Change |
|------|--------|
| `Sources/TrelloAPI/Endpoints/BoardsAPI.swift` | Add `getBoard(id:)` method |
| `Sources/trololo/Commands/BoardCommand.swift` | Add `View` substruct; register in `subcommands` |
| `Tests/TrelloAPITests/BoardDecodingTests.swift` | Add decoding tests for the Board model (if not already present) |
| `Tests/TrelloAPITests/TrelloClientTests.swift` | Add test for `getBoard` endpoint path |

### BoardCommand.swift skeleton

```swift
struct View: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Display details of a board."
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Argument(help: "The board ID.")
    var id: String

    func run() async throws {
        let client = try ClientFactory.makeClient()
        let board = try await client.getBoard(id: id)
        let fields = Self.boardFields(board)
        print(globalOptions.outputFormat.formatter.formatRecord(fields: fields))
    }

    static func boardFields(_ board: Board) -> [(label: String, value: String)] {
        [
            ("Name",         board.name         ?? "—"),
            ("Description",  board.desc         ?? "—"),
            ("Closed",       board.closed.map { String($0) } ?? "—"),
            ("Starred",      board.starred.map { String($0) } ?? "—"),
            ("Pinned",       board.pinned.map  { String($0) } ?? "—"),
            ("Organization", board.idOrganization ?? "—"),
            ("URL",          board.url          ?? "—"),
            ("Short URL",    board.shortUrl     ?? "—"),
            ("ID",           board.id),
        ]
    }
}
```

## Error Handling

- Invalid or non-existent board ID → API returns HTTP 404 → `TrelloAPIError.httpError(statusCode: 404, body:)` is thrown and the CLI prints the error message to stderr.
- No credentials → `TrelloAPIError.missingCredentials` (existing behaviour).

## Testing

- Unit test: `getBoard(id:)` sends request to `/boards/{id}`.
- Unit test: Board model decodes all fields correctly from a JSON fixture.
- Unit test: Board model decodes gracefully when optional fields are absent.

## Open Questions / Out of Scope

- Displaying nested resources (members, lists, labels) is out of scope for this command; see `board cards` for the existing pattern.
- `board view` intentionally does not accept `"me"` — boards require an explicit ID.
