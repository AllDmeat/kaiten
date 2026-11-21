# kaiten-mcp

`kaiten-mcp` is an MCP server for [Kaiten](https://kaiten.ru): it gives AI agents access to boards, cards and properties through the [Model Context Protocol](https://modelcontextprotocol.io). It is built from this repository on top of the in-repo `KaitenSDK`, and ships in the same release archive as the `kaiten` CLI.

## Install

`mise use github:AllDmeat/kaiten` installs both `kaiten` and `kaiten-mcp`. A release archive from [Releases](https://github.com/AllDmeat/kaiten/releases) contains both binaries too. From source:

```sh
swift build -c release --product kaiten-mcp
# Binary: .build/release/kaiten-mcp
```

## Usage

### 1. Get a Kaiten API Token

Get your API token at `https://<your-company>.kaiten.ru/profile/api-key`.

### 2. Configure Credentials

Credentials are stored in `~/.config/kaiten/config.json` (shared with the [CLI](../README.md)):

```json
{
  "url": "https://<your-company>.kaiten.ru/api/latest",
  "token": "<your-api-token>"
}
```

Or set credentials through MCP after connecting:

- Call `kaiten_login` with `url` and `token`.
- The server starts even without credentials; API tools validate config lazily and return an error telling you to run `kaiten_login` when credentials are missing.
- Call `kaiten_read_logs` to get MCP log file path and contents (optionally `tail_lines`).

### 3. Connect to Your AI Tool

See the **[Integration Guide](mcp-integration-guide.md)** for step-by-step instructions for:

- Claude Desktop
- Claude Code (CLI)
- GitHub Copilot (VS Code)
- GitHub Copilot CLI
- Cursor
- OpenAI Codex CLI
- Windsurf

## API Reference

### Cards

| Tool | Description |
|------|-------------|
| `kaiten_list_cards` | List cards on a board (paginated) |
| `kaiten_get_card` | Get a card by ID |
| `kaiten_create_card` | Create a new card |
| `kaiten_update_card` | Update a card |
| `kaiten_get_card_members` | Get card members |
| `kaiten_get_card_comments` | Get card comments |
| `kaiten_create_comment` | Add a comment to a card |
| `kaiten_get_card_baselines` | Get card baselines |
| `kaiten_list_external_links` | List external links on a card |
| `kaiten_add_external_link` | Add an external link to a card |
| `kaiten_remove_external_link` | Remove an external link from a card |

### Spaces

| Tool | Description |
|------|-------------|
| `kaiten_list_spaces` | List all spaces |
| `kaiten_create_space` | Create a space |
| `kaiten_get_space` | Get a space by ID |
| `kaiten_update_space` | Update a space |

### Boards

| Tool | Description |
|------|-------------|
| `kaiten_list_boards` | List boards in a space |
| `kaiten_get_board` | Get a board by ID |
| `kaiten_create_board` | Create a board |
| `kaiten_update_board` | Update a board |

### Columns

| Tool | Description |
|------|-------------|
| `kaiten_get_board_columns` | Get columns of a board |
| `kaiten_create_column` | Create a column |
| `kaiten_update_column` | Update a column |
| `kaiten_delete_column` | Delete a column |
| `kaiten_list_subcolumns` | List subcolumns |
| `kaiten_create_subcolumn` | Create a subcolumn |
| `kaiten_update_subcolumn` | Update a subcolumn |
| `kaiten_delete_subcolumn` | Delete a subcolumn |

### Lanes

| Tool | Description |
|------|-------------|
| `kaiten_get_board_lanes` | Get lanes of a board |
| `kaiten_create_lane` | Create a lane |
| `kaiten_update_lane` | Update a lane |

### Custom Properties

| Tool | Description |
|------|-------------|
| `kaiten_list_custom_properties` | List custom property definitions |
| `kaiten_get_custom_property` | Get a custom property by ID |
| `kaiten_get_custom_property_select_values` | Get available select/multi-select values for a property |
| `kaiten_update_card_properties` | Update custom property values on a card |

### Sprints

| Tool | Description |
|------|-------------|
| `kaiten_get_sprint_summary` | Get sprint summary |

### Settings

| Tool | Description |
|------|-------------|
| `kaiten_configure` | Manage preferences (boards/spaces) |
| `kaiten_get_preferences` | Get current preferences |
| `kaiten_login` | Save shared API credentials (`url`, `token`) |
| `kaiten_read_logs` | Read MCP log file path and text content |

## Configuration

The config file at `~/.config/kaiten/config.json` is shared between MCP and [CLI](../README.md). You only need to configure it once (see [Configure Credentials](#2-configure-credentials) above).

User preferences are stored separately in `~/.config/kaiten/preferences.json`:

```json
{
  "myBoards": [
    { "id": 123, "alias": "team" }
  ],
  "mySpaces": [
    { "id": 456 }
  ]
}
```
