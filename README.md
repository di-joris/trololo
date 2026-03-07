# trello

A command-line tool for the [Trello REST API](https://developer.atlassian.com/cloud/trello/rest/), inspired by [GitHub CLI](https://cli.github.com).

## Installation

Requires Swift 6.0+.

```bash
git clone <repo-url>
cd trello-tool
swift build -c release
# Binary is at .build/release/trello
```

## Authentication

Get your API key and token from <https://trello.com/power-ups/admin>.

### Environment variables

```bash
export TRELLO_API_KEY="your-api-key"
export TRELLO_API_TOKEN="your-api-token"
```

### `.env` file

Alternatively, create a `.env` file with your credentials:

```
TRELLO_API_KEY=your-api-key
TRELLO_API_TOKEN=your-api-token
```

The CLI looks for `.env` in the current working directory, then falls back to `~/.config/trello/.env`. Environment variables always take priority over `.env` values.

> **Tip:** Add `.env` to your `.gitignore` to avoid committing credentials.

## Usage

```bash
trello member me    # Show your Trello profile
```

Example output:

```
Username:  bentleycook
Full Name: Bentley Cook
Initials:  BC
Email:     bentley@example.com
Bio:       👋 I'm a developer advocate at Trello!
URL:       https://trello.com/bentleycook
Type:      normal
Status:    active
ID:        5abbe4b7ddc1b351ef961414
```

## License

MIT
