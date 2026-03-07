# Spec: `member boards` — Enhanced Output

## Summary

Enhance the existing `member boards` subcommand to show more useful board information: description, short URL, starred/pinned/closed status indicators, and organization ID.

## Motivation

The current output only shows `Name` and `ID`. Users need quick access to the board URL and other metadata to decide which board to work with, without having to run `board view <id>` for each result.

## Command Signature

Unchanged:

```
trololo member boards [--member <id>] [--format text|csv]
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--member` / `-m` | `"me"` | Member ID or username. |
| `--format` | `text` | Output format (`text` or `csv`). Inherited from `GlobalOptions`. |

## API

**Endpoint:** `GET https://api.trello.com/1/members/{id}/boards`

No change to the API call. The existing `getMemberBoards(memberId:)` method already fetches the full Board objects. The additional fields (`desc`, `shortUrl`, `idOrganization`, `pinned`, `starred`, `closed`) are already included in the `Board` model.

## Output Format

### Text format (default) — table

Add columns for **Description** (truncated), **Short URL**, and the existing **ID**. Status indicators (`closed`, `★` for starred, `📌` for pinned) remain in the **Name** column as suffixes.

```
Name                          Description            Short URL                      ID
My Project Board (★)          Track Q1 tasks         https://trello.com/b/AbCdEfGh  5e9b4c2a1d3f8a0b2c4d6e8f
Team Backlog                                         https://trello.com/b/XyZwVuTs  6f0c5d3b2e4g9b1c3d5e7f9a
Archive (closed)              Old completed work     https://trello.com/b/MnOpQrSt  7a1d6e4c3f5h0c2d4e6f8g0b
```

Column definitions:

| Column | Source | Notes |
|--------|--------|-------|
| Name | `board.name ?? board.id` | Appends `(closed)` if `board.closed == true`, `★` if `board.starred == true`, `📌` if `board.pinned == true` |
| Description | `board.desc ?? ""` | Truncated to 40 characters with `…` if longer; empty string if nil |
| Short URL | `board.shortUrl ?? board.url ?? "—"` | Prefer shortUrl |
| ID | `board.id` | Always present |

**Headers:** `["Name", "Description", "Short URL", "ID"]`

### CSV format

Same four columns, no truncation of description.

## Model Changes

No changes required. The `Board` model already has all necessary fields.

## Implementation Plan

### Files to modify

| File | Change |
|------|--------|
| `Sources/trololo/Commands/MemberCommand.swift` | Update `Boards.run()` to build rows with new columns |

### Updated `Boards.run()` logic

```swift
let headers = ["Name", "Description", "Short URL", "ID"]
let rows = boards.map { board -> [String] in
    let name = board.name ?? board.id
    var indicators: [String] = []
    if board.closed == true  { indicators.append("closed") }
    if board.starred == true { indicators.append("★") }
    if board.pinned  == true { indicators.append("📌") }
    let suffix = indicators.isEmpty ? "" : " (\(indicators.joined(separator: ", ")))"

    let desc = board.desc ?? ""
    let truncatedDesc = desc.count > 40 ? String(desc.prefix(40)) + "…" : desc

    let shortURL = board.shortUrl ?? board.url ?? "—"

    return ["\(name)\(suffix)", truncatedDesc, shortURL, board.id]
}
```

## Error Handling

No changes. Empty board list continues to print `"No boards found."`.

## Testing

- Verify the new column headers are present in text output.
- Verify description truncation at exactly 40 characters.
- Verify `shortUrl` is preferred over `url`; falls back to `—` if both are nil.
- Verify status indicators appear correctly in the Name column.

## Open Questions / Out of Scope

- Filtering boards by status (`--filter closed|open|all`) is out of scope here; could be a follow-up.
- Organization name resolution (resolving `idOrganization` to a display name) is out of scope.
