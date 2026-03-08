# AGENTS.md

## Project Overview

`trololo` is a Swift command-line client for the Trello REST API, modeled after the `gh` CLI's noun-verb structure.
The OpenAPI spec lives in `trello-openapi.json`; Trello's REST docs are at <https://developer.atlassian.com/cloud/trello/rest/api-group-actions/>.

## Build & Test

```bash
swift build
swift test
swift run trololo
```

Requires **Swift 6.0+** and **macOS 13+**. The package uses Swift Concurrency (`async/await`, `Sendable`) throughout.

## Package Layout

### `TrololoCLI` (executable target)
- `TrololoCLI.swift` — `@main` root command
- `ClientFactory.swift` — credential resolution and `TrelloClient` construction
- `Environment.swift` / `DotEnv.swift` — process environment + `.env` merging
- `GlobalOptions.swift` — shared CLI flags
- `Formatting/` — `OutputFormatter`, `OutputFormat`, `TextFormatter`, `CSVFormatter`, `TrelloPresentation`
- `Commands/` — noun commands: `member`, `board`, `card`, `list`

### `TrelloAPI` (library target)
- `TrelloClient.swift` — authenticated HTTP client and API error handling
- `Models/` — `Member`, `Board`, `Card`, `TrelloList`, `Organization`
- `Endpoints/` — `TrelloClient` extensions for members, boards, cards, and lists

### Test Targets
- `TrelloAPITests` — API client, endpoint, and model decoding coverage
- `TrololoCLITests` — dotenv, environment, client factory, formatter, and presentation coverage

## CLI Design

Command pattern:

```bash
trololo <noun> <verb> [options]
```

Implemented nouns and verbs:
- `member`: `view`, `boards`, `cards`, `organizations`
- `board`: `view`, `lists`, `cards`
- `card`: `view`
- `list`: `view`, `cards`

Shared global option:
- `--output-format text|csv`

Commands should stay thin: parse arguments, build a client, fetch data, render output.

## Authentication & Environment

- Trello authentication uses query parameters: `key` and `token`.
- The CLI resolves credentials through `ClientFactory.makeClient()`.
- Resolution order is:
  1. current process environment
  2. `.env` in the current working directory
  3. `~/.config/trololo/.env`
- Existing environment values always win over `.env` values.
- Existing but unreadable `.env` files surface as errors only while the CLI still needs them to resolve missing credentials.
- `TrelloClient` itself does **not** read environment variables or `.env` files; it only accepts explicit credentials.

## Output Architecture

- `TrelloPresentation` is the single place for CLI field ordering, row construction, indicator suffixes, truncation, and empty-state copy.
- `CommandOutput` renders record or table output from `TrelloPresentation`.
- `TextFormatter` renders aligned records and tables with headers.
- `CSVFormatter` renders headered CSV and handles escaping.
- New CLI output work should extend `TrelloPresentation` and the formatters instead of duplicating presentation logic in command files.

## API Architecture

- `TrelloClient` is initialized with `apiKey`, `apiToken`, and an optional `HTTPClient` (defaults to `URLSession.shared`).
- `makeRequest(path:queryItems:)` appends Trello auth parameters to each request.
- `get(_:path:queryItems:)` performs GET requests and decodes `Decodable` models.
- Endpoints are added as `TrelloClient` extensions under `Sources/TrelloAPI/Endpoints/`.
- Models conform to `Codable`, `Sendable`, and `Equatable`; most fields are optional because Trello responses vary by endpoint and query parameters.

## Testing

The project uses **Swift Testing** (`@Test`, `#expect`, `#require`).

Key testing patterns:
- API tests use `MockHTTPClient` and `RequestCapture` from `Tests/TrelloAPITests/TrelloClientTests.swift`.
- CLI tests cover dotenv parsing, merged environment behavior, client factory credential resolution, formatter behavior, and presentation mapping.
- For isolated `ClientFactory` tests, inject `environment` and pass `paths: []` when you want to disable local `.env` fallback.

Run `swift test` after code changes; it validates both the API and CLI layers.

## Adding New Features

When adding a new Trello surface:
1. Add or update a model in `Sources/TrelloAPI/Models/` if needed.
2. Add an endpoint method as a `TrelloClient` extension in `Sources/TrelloAPI/Endpoints/`.
3. Add or extend a CLI command in `Sources/TrololoCLI/Commands/`.
4. Add presentation mapping in `Sources/TrololoCLI/Formatting/TrelloPresentation.swift`.
5. Add or update tests in both `TrelloAPITests` and `TrololoCLITests` as appropriate.
6. Update `README.md` if the user-facing CLI changes.

## Conventions

- Use incremental git commits at logical boundaries.
- Keep public APIs concurrency-safe (`Sendable` where appropriate).
- Prefer `AsyncParsableCommand` for CLI commands.
- Keep credential loading centralized in `ClientFactory`.
- Keep rendering logic centralized in `TrelloPresentation` and formatter types rather than inline in commands.
