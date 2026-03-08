# AGENTS.md

## Project Overview

A Swift command-line tool (`trololo`) for interfacing with the Trello REST API, modeled after the `gh` CLI's noun-verb structure. The OpenAPI specification is at `trello-openapi.json` (187 endpoints); online docs at <https://developer.atlassian.com/cloud/trello/rest/api-group-actions/>.

## Build & Test

```bash
swift build           # Build all targets
swift test            # Run all unit tests (21 tests, 4 suites)
swift run trololo      # Run the CLI
```

Requires **Swift 6.0+** and **macOS 13+**. Uses strict concurrency (`Sendable`, `async/await`).

## Package Structure

Four targets in `Package.swift`:

| Target | Type | Dependencies | Purpose |
|--------|------|-------------|---------|
| `TrololoCLI` | Executable | `TrelloAPI`, `swift-argument-parser` | CLI entry point |
| `TrelloAPI` | Library | Foundation | API client, models, endpoints |
| `TrelloAPITests` | Test | `TrelloAPI` | Unit tests (Swift Testing framework) |
| `TrololoCLITests` | Test | `TrololoCLI` | CLI unit tests (.env parser, etc.) |

```
Sources/
├── TrololoCLI/                      # CLI executable
│   ├── TrololoCLI.swift             # @main root command
│   ├── DotEnv.swift                 # Lightweight .env file parser
│   ├── Environment.swift            # Loads .env files (cwd → ~/.config/trololo/.env)
│   └── Commands/
│       └── MemberCommand.swift      # `trololo member me`
└── TrelloAPI/                       # Library (reusable API client)
    ├── TrelloClient.swift           # HTTPClient protocol, TrelloClient, TrelloAPIError
    ├── Models/
    │   └── Member.swift             # Member Codable model
    └── Endpoints/
        └── MembersAPI.swift         # getMember(id:) extension

Tests/
├── TrelloAPITests/
│   ├── MemberDecodingTests.swift    # Model decoding tests
│   └── TrelloClientTests.swift      # Client + endpoint tests, MockHTTPClient
└── TrololoCLITests/
    └── DotEnvTests.swift            # .env parser tests
```

## CLI Usage

```bash
# Requires credentials (environment variables or .env file)
export TRELLO_API_KEY="your-api-key"
export TRELLO_API_TOKEN="your-api-token"

# Or create a .env file in the current directory or ~/.config/trololo/.env
# TRELLO_API_KEY=your-api-key
# TRELLO_API_TOKEN=your-api-token

trololo member me       # Display authenticated user's profile
trololo --help          # Show help
trololo member --help   # Show member subcommand help
```

Command pattern: `trololo <noun> <verb>` (like `gh`).

## Authentication

- **Trello API uses API Key + API Token** passed as query parameters (`key` and `token`) on every request.
- The CLI reads credentials from `TRELLO_API_KEY` and `TRELLO_API_TOKEN` environment variables, or from a `.env` file.
- `.env` file lookup order: current working directory (`.env`), then `~/.config/trololo/.env`. Environment variables take priority over `.env` values.
- The library (`TrelloClient`) accepts credentials via its initializer — it does not read environment variables or `.env` files directly.

## Architecture

### TrelloClient

- Initialized with `apiKey`, `apiToken`, and an `HTTPClient` (defaults to `URLSession.shared`).
- `makeRequest(path:queryItems:)` builds authenticated `URLRequest` objects with key/token appended.
- `get<T: Decodable>(_:path:queryItems:)` executes GET requests and decodes responses.
- Base URL: `https://api.trello.com/1`.

### HTTPClient Protocol

```swift
public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
```

`URLSession` conforms automatically. Tests inject `MockHTTPClient` for deterministic behavior.

### Error Handling

`TrelloAPIError` enum with cases: `missingCredentials`, `invalidURL`, `httpError(statusCode:body:)`, `decodingError`, `networkError`. All conform to `LocalizedError`, `Equatable`, and `Sendable`.

### Adding New Endpoints

Follow the extension pattern in `Endpoints/MembersAPI.swift`:

```swift
extension TrelloClient {
    public func getBoards(memberId: String = "me") async throws -> [Board] {
        try await get([Board].self, path: "/members/\(memberId)/boards")
    }
}
```

1. Add a Codable model in `Models/`.
2. Add an endpoint extension in `Endpoints/`.
3. Add a CLI subcommand in `Commands/`.

## Testing

Uses **Swift Testing** framework (`@Test`, `#expect`, `#require`). Key test helpers:

- **`MockHTTPClient`** — Configurable mock with factory methods: `.success(data:)`, `.httpError(statusCode:body:)`, `.capturing(into:data:)`.
- **`RequestCapture`** — Actor for thread-safe request inspection in async tests.

Tests cover: model decoding (full/minimal/round-trip), URL construction, auth parameter injection, HTTP error codes (parameterized), decoding errors, and endpoint request paths.

## Trello API Reference

- OpenAPI spec: `trello-openapi.json` (OpenAPI 3.0, 187 paths)
- Base URL: `https://api.trello.com/1`
- Auth: query params `key` (32-char hex) and `token`
- Key schemas: `Member`, `TrelloID` (24-char hex string)
- The `{id}` parameter in `/members/{id}` accepts `"me"` as a special value for the authenticated user.

## Conventions

- Incremental git commits at logical boundaries.
- All public types are `Sendable` for Swift concurrency safety.
- Optional fields in models (the API may omit fields depending on query parameters).
- CLI uses `AsyncParsableCommand` for async endpoint calls.
