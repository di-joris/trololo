# Spec: `member view [<id>]`

## Summary

Rename the existing `member me` subcommand to `member view`, adding an optional positional `<id>` argument so users can look up any member by ID or username. Behaviour when `<id>` is omitted is identical to the current `member me`.

## Motivation

`member me` is too narrow — it can only show the authenticated user. `member view` is the natural gh-CLI pattern (`gh pr view`, `gh issue view`) and allows looking up any member while keeping the authenticated-user default.

## Command Signature

```
trololo member view [<id>] [--format text|csv]
```

### Arguments

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `id` | No | `"me"` | Member ID or username. Pass `"me"` (or omit) for the authenticated user. |

### Options

Inherits the shared `--format` option from `GlobalOptions` (via `@OptionGroup`).

## Migration / Backwards Compatibility

`member me` is removed and replaced by `member view`. There is no alias kept for `me` — this is an early-stage CLI so a breaking rename is acceptable. The help text for `MemberCommand` should be updated to reflect the new subcommand list.

## API

**Endpoint:** `GET https://api.trello.com/1/members/{id}`

**No API changes.** The existing `getMember(id:)` method in `MembersAPI.swift` already defaults to `"me"` and accepts any member ID or username:

```swift
public func getMember(id: String = "me") async throws -> Member {
    try await get(Member.self, path: "/members/\(id)")
}
```

## Output Format

Identical to the current `member me` output — a key–value record:

```
Username   janedoe
Full Name  Jane Doe
Initials   JD
Email      jane@example.com
Bio        Engineer at Acme Corp
URL        https://trello.com/janedoe
Type       normal
Status     disconnected
ID         5e9b4c2a1d3f8a0b2c4d6e8f
```

When looking up another member by username or ID, the same record fields are shown. Fields that the API omits (e.g. `email` for non-self lookups) display as `—`.

## Implementation Plan

### Files to modify

| File | Change |
|------|--------|
| `Sources/trololo/Commands/MemberCommand.swift` | Rename `Me` struct to `View`; add optional `@Argument var id: String = "me"`; update `subcommands` array; update help strings |

### MemberCommand.swift diff (key changes)

**Before:**
```swift
static let configuration = CommandConfiguration(
    commandName: "member",
    abstract: "Manage Trello members.",
    subcommands: [Me.self, Boards.self]
)

struct Me: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Display the authenticated member's profile."
    )

    @OptionGroup var globalOptions: GlobalOptions

    func run() async throws {
        let client = try ClientFactory.makeClient()
        let member = try await client.getMember(id: "me")
        ...
    }
}
```

**After:**
```swift
static let configuration = CommandConfiguration(
    commandName: "member",
    abstract: "Manage Trello members.",
    subcommands: [View.self, Boards.self]
)

struct View: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Display a member's profile."
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Argument(help: "Member ID or username (defaults to the authenticated user).")
    var id: String = "me"

    func run() async throws {
        let client = try ClientFactory.makeClient()
        let member = try await client.getMember(id: id)
        ...
    }
}
```

The `memberFields(_:)` static helper stays unchanged.

## Error Handling

- Unknown member ID/username → API returns HTTP 404 → `TrelloAPIError.httpError(statusCode: 404, body:)`.
- No credentials → `TrelloAPIError.missingCredentials`.

## Testing

- Update any existing CLI tests that reference `member me` to use `member view`.
- Add a test for `member view <id>` to verify the correct path `/members/<id>` is requested.
- Verify `member view` (no argument) still requests `/members/me`.

## Open Questions / Out of Scope

- `member view` does not currently support filtering which fields are returned via `?fields=`. This is a future enhancement.
- Avatar display is out of scope.
