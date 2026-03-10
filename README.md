# Trololo

A command-line tool for the [Trello REST API](https://developer.atlassian.com/cloud/trello/rest/), inspired by [GitHub CLI](https://cli.github.com).

## Installation

Requires Swift 6.0+.

```bash
git clone <repo-url>
cd trololo
swift build -c release
# Binary is at .build/release/trololo
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

The CLI looks for `.env` in the current working directory, then falls back to `~/.config/trololo/env`. Environment variables always take priority over `.env` values.

> **Tip:** Add `.env` to your `.gitignore` to avoid committing credentials.
>
> If the CLI still needs credentials from `.env` and an existing file cannot be read, it now surfaces that as an error instead of silently ignoring it.

## Usage

```bash
trololo member view                  # Show your Trello profile
trololo member boards --member me    # List your boards
trololo board lists <board-id>       # List lists on a board
trololo list cards <list-id>         # List cards in a list
trololo member boards --output-format csv
trololo member view janedoe          # Look up another member by username
```

Example text output (`trololo member boards`):

```
Name               Description                                   Short URL                ID
-----------------  --------------------------------------------  -----------------------  ------------------------
Roadmap (★)        Team planning board                           https://trello.com/b/r  5abbe4b7ddc1b351ef961414
Archive (closed)                                                 https://trello.com/b/a  5abbe4b7ddc1b351ef961415
```

Example record output (`trololo member view`):

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

Use `--output-format csv` when you want headered CSV output for scripts or spreadsheets.

## License

MIT
