# Spec: `member organizations` (alias `orgs`)

## Summary

Add a `member organizations` subcommand (with short alias `orgs`) that lists the Trello workspaces (organizations) a member belongs to.

## Motivation

Trello organises boards into workspaces (called "organizations" in the API). Members often belong to multiple workspaces, and there is currently no way to list them from the CLI. This maps to `GET /members/{id}/organizations`.

## Command Signature

```
trololo member organizations [--member <id>] [--format text|csv]
trololo member orgs          [--member <id>] [--format text|csv]
```

Both names invoke the same subcommand. `orgs` is an alias registered via `CommandConfiguration.aliases`.

### Options

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--member` | `-m` | `"me"` | Member ID or username. Defaults to the authenticated user. |
| `--format` | | `text` | Output format. Inherited from `GlobalOptions`. |

## API

**Endpoint:** `GET https://api.trello.com/1/members/{id}/organizations`

**OpenAPI summary:** "Get Member's Organizations"

**Query parameters used:**

| Parameter | Value | Notes |
|-----------|-------|-------|
| `filter` | *(omitted)* | Defaults to `all` on the API side. |

**New TrelloAPI library method:**

```swift
extension TrelloClient {
    /// Fetches the organizations (workspaces) a member belongs to.
    ///
    /// - Parameter memberId: The member ID or `"me"` for the authenticated user.
    /// - Returns: The member's organizations.
    public func getMemberOrganizations(memberId: String = "me") async throws -> [Organization] {
        try await get([Organization].self, path: "/members/\(memberId)/organizations")
    }
}
```

## Model

A new `Organization` model must be added to `Sources/TrelloAPI/Models/Organization.swift`.

### Organization fields

Based on the OpenAPI `Organization` schema:

| Field | Swift type | API field | Notes |
|-------|-----------|-----------|-------|
| `id` | `String` | `id` | Required; 24-char TrelloID |
| `name` | `String?` | `name` | Short name / slug (used in URLs) |
| `displayName` | `String?` | `displayName` | Human-readable name |
| `url` | `String?` | `url` | Full URL to the workspace |
| `idBoards` | `[String]?` | `idBoards` | Array of board IDs in this org |

Fields intentionally excluded from the model for now: `prefs`, `idEnterprise`, `offering`, `memberships`, `premiumFeatures`, `dateLastActivity`. These can be added when needed.

### Model definition

```swift
import Foundation

/// A Trello organization (workspace).
public struct Organization: Codable, Sendable, Equatable {
    public let id: String
    public let name: String?
    public let displayName: String?
    public let url: String?
    public let idBoards: [String]?

    public init(
        id: String,
        name: String? = nil,
        displayName: String? = nil,
        url: String? = nil,
        idBoards: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.url = url
        self.idBoards = idBoards
    }
}
```

## Output Format

Display as a **table**, consistent with other list commands.

### Text format (default)

```
Display Name       Slug            Boards  ID
Acme Engineering   acme-eng        12      5e9b4c2a1d3f8a0b2c4d6e8f
Personal           janedoe         3       6f0c5d3b2e4g9b1c3d5e7f9a
Open Source Club   oss-club        7       7a1d6e4c3f5h0c2d4e6f8g0b
```

Column definitions:

| Column | Source | Notes |
|--------|--------|-------|
| Display Name | `org.displayName ?? org.name ?? org.id` | Human-readable workspace name |
| Slug | `org.name ?? "—"` | URL slug / short name |
| Boards | `org.idBoards.map { String($0.count) } ?? "—"` | Count of board IDs |
| ID | `org.id` | Always present |

**Headers:** `["Display Name", "Slug", "Boards", "ID"]`

**Empty state:** Print `"No organizations found."` if the response array is empty.

### CSV format

Same four columns.

## Implementation Plan

### Files to create/modify

| File | Change |
|------|--------|
| `Sources/TrelloAPI/Models/Organization.swift` | **Create** new `Organization` model |
| `Sources/TrelloAPI/Endpoints/MembersAPI.swift` | Add `getMemberOrganizations(memberId:)` method |
| `Sources/trololo/Commands/MemberCommand.swift` | Add `Organizations` substruct with `orgs` alias; register in `subcommands` |
| `Tests/TrelloAPITests/OrganizationDecodingTests.swift` | **Create** decoding tests |
| `Tests/TrelloAPITests/TrelloClientTests.swift` | Add test for `getMemberOrganizations` endpoint path |

### MemberCommand.swift addition

```swift
struct Organizations: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "organizations",
        abstract: "List organizations (workspaces) the member belongs to.",
        aliases: ["orgs"]
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: [.short, .long], help: "Member ID or username (defaults to authenticated user).")
    var member: String = "me"

    func run() async throws {
        let client = try ClientFactory.makeClient()
        let orgs = try await client.getMemberOrganizations(memberId: member)

        if orgs.isEmpty {
            print("No organizations found.")
            return
        }

        let headers = ["Display Name", "Slug", "Boards", "ID"]
        let rows = orgs.map { org -> [String] in
            let displayName = org.displayName ?? org.name ?? org.id
            let slug        = org.name ?? "—"
            let boardCount  = org.idBoards.map { String($0.count) } ?? "—"
            return [displayName, slug, boardCount, org.id]
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
- If `idBoards` is `nil` in the response, show `"—"` in the Boards column.

## Testing

- Unit test: `getMemberOrganizations(memberId:)` sends request to `/members/me/organizations`.
- Unit test: `Organization` decodes `id`, `name`, `displayName`, `url`, `idBoards` from JSON.
- Unit test: `Organization` decodes gracefully when all optional fields are absent.
- Unit test: Board count column shows correct count from `idBoards` array.
- Unit test: `trololo member orgs` invokes the same command as `trololo member organizations`.

## Open Questions / Out of Scope

- **`organization view <id>`** — a dedicated command to view a single organization's details is out of scope here.
- **Board name resolution** within an org is out of scope; the board count column is intentionally a number, not a list.
- **`--filter` flag** to narrow by membership type (`all`, `members`, `public`) is deferred.
