# kaiten-sdk

[![Build](https://github.com/AllDmeat/kaiten-sdk/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/AllDmeat/kaiten-sdk/actions/workflows/build-and-test.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAllDmeat%2Fkaiten-sdk%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/AllDmeat/kaiten-sdk)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAllDmeat%2Fkaiten-sdk%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/AllDmeat/kaiten-sdk)

Swift SDK for the [Kaiten](https://kaiten.ru) project management API. OpenAPI-generated types with typed errors, automatic retry on `429 Too Many Requests`, and Bearer token authentication.

Full Kaiten API documentation: [developers.kaiten.ru](https://developers.kaiten.ru)

## Installation

### As a library

Add KaitenSDK to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AllDmeat/kaiten-sdk.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "KaitenSDK", package: "KaitenSDK"),
        ]
    ),
]
```

### mise (recommended)

[mise](https://mise.jdx.dev) — a tool version manager. It will install the required version automatically:

```bash
mise use github:alldmeat/kaiten-sdk
```

### GitHub Release

Download the binary for your platform from the [releases page](https://github.com/AllDmeat/kaiten-sdk/releases).

## Quick Start

### As a library

```swift
import KaitenSDK

let client = try KaitenClient(
    baseURL: "https://your-company.kaiten.ru/api/latest",
    token: "your-api-token"
)

let spaces = try await client.listSpaces()
let cards = try await client.listCards(boardId: 42)
let card = try await client.getCard(id: 123)
```

### As a CLI

The CLI resolves credentials in order: flags → config file.

#### 1. Get a Kaiten API Token

Get your API token at `https://<your-company>.kaiten.ru/profile/api-key`.

#### 2. Configure Credentials

**Option 1 — Config file** (recommended):

Create `~/.config/kaiten/config.json`:

```json
{
  "url": "https://<your-company>.kaiten.ru/api/latest",
  "token": "<your-api-token>"
}
```

Then run commands:

```bash
kaiten list-spaces
kaiten get-card --id 123
```

## API Reference

### Cards

| Method | Description |
|--------|-------------|
| `listCards(boardId:)` | List all cards on a board |
| `getCard(id:)` | Fetch a single card by ID |
| `createCard(...)` | Create a new card |
| `updateCard(...)` | Update a card |
| `deleteCard(...)` | Delete a card |
| `listCardChildren(...)` | List child cards |
| `addCardChild(...)` | Add a child card |
| `removeCardChild(...)` | Remove a child card |
| `getCardMembers(cardId:)` | Get members of a card |
| `addCardMember(...)` | Add a member to a card |
| `updateCardMemberRole(...)` | Update a card member's role |
| `removeCardMember(...)` | Remove a member from a card |
| `getCardComments(cardId:)` | Get comments on a card |
| `createComment(cardId:text:)` | Add a comment to a card |
| `updateComment(...)` | Update a comment |
| `deleteComment(...)` | Delete a comment |
| `listCardTags(...)` | List tags on a card |
| `addCardTag(...)` | Add a tag to a card |
| `removeCardTag(...)` | Remove a tag from a card |
| `listCardBlockers(...)` | List card blockers |
| `createCardBlocker(...)` | Create a card blocker |
| `updateCardBlocker(...)` | Update a card blocker |
| `deleteCardBlocker(...)` | Delete a card blocker |
| `getCardLocationHistory(...)` | Get card location history |
| `getCardBaselines(...)` | Get card baselines |

### Checklists

| Method | Description |
|--------|-------------|
| `createChecklist(...)` | Create a checklist on a card |
| `getChecklist(...)` | Get a checklist |
| `updateChecklist(...)` | Update a checklist |
| `removeChecklist(...)` | Remove a checklist |
| `createChecklistItem(...)` | Create a checklist item |
| `updateChecklistItem(...)` | Update a checklist item |
| `removeChecklistItem(...)` | Remove a checklist item |

### External Links

| Method | Description |
|--------|-------------|
| `listExternalLinks(...)` | List external links on a card |
| `createExternalLink(...)` | Create an external link |
| `updateExternalLink(...)` | Update an external link |
| `removeExternalLink(...)` | Remove an external link |

### Spaces

| Method | Description |
|--------|-------------|
| `listSpaces()` | List all spaces |
| `createSpace(...)` | Create a space |
| `getSpace(...)` | Get a space by ID |
| `updateSpace(...)` | Update a space |

### Boards

| Method | Description |
|--------|-------------|
| `listBoards(spaceId:)` | List boards in a space |
| `getBoard(id:)` | Fetch a board by ID |
| `createBoard(...)` | Create a board |
| `updateBoard(...)` | Update a board |

### Columns

| Method | Description |
|--------|-------------|
| `getBoardColumns(boardId:)` | Get columns for a board |
| `createColumn(...)` | Create a column |
| `updateColumn(...)` | Update a column |
| `deleteColumn(...)` | Delete a column |
| `listSubcolumns(...)` | List subcolumns |
| `createSubcolumn(...)` | Create a subcolumn |
| `updateSubcolumn(...)` | Update a subcolumn |
| `deleteSubcolumn(...)` | Delete a subcolumn |

### Lanes

| Method | Description |
|--------|-------------|
| `getBoardLanes(boardId:)` | Get lanes for a board |
| `createLane(...)` | Create a lane |
| `updateLane(...)` | Update a lane |

### Custom Properties

| Method | Description |
|--------|-------------|
| `listCustomProperties()` | List all custom property definitions |
| `getCustomProperty(id:)` | Get a single custom property definition |
| `listCustomPropertySelectValues(propertyId:)` | List select values for a custom property |
| `getCustomPropertySelectValue(propertyId:id:)` | Get a single select value |

### Users

| Method | Description |
|--------|-------------|
| `listUsers()` | List all users |
| `getCurrentUser()` | Get the current user |

### Card Types & Sprints

| Method | Description |
|--------|-------------|
| `listCardTypes()` | List card types |
| `listSprints()` | List sprints |
| `getSprintSummary(...)` | Get sprint summary |

## Pagination

Most list endpoints accept `offset` and `limit` parameters and return a `Page<T>`:

```swift
let page = try await client.listCards(boardId: 42, offset: 0, limit: 20)
print(page.items)   // [Card] — the items in this page
print(page.hasMore) // true if more pages are available
```

To fetch the next page, increment `offset` by `limit` and repeat until `hasMore` is `false`.

### Auto-pagination

Convenience methods handle pagination automatically and return an `AsyncThrowingStream` so you can iterate all items without managing offsets:

```swift
for try await card in client.allCards(boardId: 42) {
    print(card.title)
}
```

Available auto-pagination methods:

| Method | Description |
|--------|-------------|
| `allCards(boardId:columnId:laneId:filter:pageSize:)` | All cards matching the given criteria |
| `allUsers(type:query:includeInactive:pageSize:)` | All users |
| `allCustomProperties(query:pageSize:)` | All custom property definitions |
| `allCustomPropertySelectValues(propertyId:pageSize:)` | All select values for a property |
| `allCardTypes(pageSize:)` | All card types |
| `allSprints(active:pageSize:)` | All sprints |

Each method accepts an optional `pageSize` parameter (default `100`).

## Filtering Cards

Use `CardFilter` to narrow results when listing cards. All properties are optional — set only the ones you need:

```swift
let overdueCards = try await client.listCards(
    filter: CardFilter(memberIds: "10,25", overdue: true)
)
```

Search by text within a space:

```swift
let results = try await client.listCards(
    filter: CardFilter(query: "login bug", spaceId: 42)
)
```

Filters work with auto-pagination too:

```swift
let filter = CardFilter(states: [.inProgress], orderBy: "updated_at")
for try await card in client.allCards(boardId: 1, filter: filter) {
    print(card.title)
}
```

Commonly used filter properties include `query`, `memberIds`, `states`, `overdue`, `spaceId`, `typeId`, `condition`, and date ranges like `createdAfter`/`createdBefore`. See `CardFilter` source for the full list of 40+ parameters.

## Creating & Updating Cards

### CardCreateOptions

Create a card by providing a title and board ID. Set additional properties as needed:

```swift
var opts = CardCreateOptions(title: "Bug fix", boardId: 1)
opts.columnId = 42
opts.description = "Fix the login crash"
let card = try await client.createCard(opts)
```

### CardUpdateOptions

Update specific fields on an existing card — only the properties you set are sent to the server:

```swift
var opts = CardUpdateOptions()
opts.title = "Updated Title"
opts.columnId = 42
let card = try await client.updateCard(id: 123, opts)
```

## Configuration

The CLI and MCP server share the same config file at `~/.config/kaiten/config.json` (see [Configure Credentials](#2-configure-credentials) above).

Use `--config` to provide a custom config file path when needed.

## Error Handling

All methods throw `KaitenError`, which provides typed cases for every failure mode:

```swift
do {
    let card = try await client.getCard(id: 999)
} catch let error as KaitenError {
    switch error {
    case .missingConfiguration(let key):
        print("Missing config: \(key)")
    case .invalidURL(let url):
        print("Bad URL: \(url)")
    case .unauthorized:
        print("Check your API token")
    case .notFound(let resource, let id):
        print("\(resource) \(id) not found")
    case .rateLimited(let retryAfter):
        print("Rate limited, retry after: \(String(describing: retryAfter))")
    case .serverError(let statusCode, let body):
        print("Server error \(statusCode): \(body ?? "")")
    case .networkError(let underlying):
        print("Network: \(underlying)")
    case .unexpectedResponse(let statusCode):
        print("Unexpected HTTP \(statusCode)")
    }
}
```

## Agent skill

This repository doubles as a [plugin marketplace](.claude-plugin/marketplace.json) so coding agents
can drive the CLI correctly. The `kaiten` plugin in [`agent/`](agent) teaches an agent to consult
`kaiten --help` and `kaiten <subcommand> --help` before composing a command, and covers what the help
cannot: config file location, the ID discovery chain, the two JSON output shapes, pagination, and the
built-in `429` handling.

**Claude Code** — install from the marketplace:

```
/plugin marketplace add AllDmeat/kaiten-sdk
/plugin install kaiten@kaiten
```

**Gemini CLI** — `agent/` is also a Gemini extension, and Gemini discovers the same
`agent/skills/kaiten/SKILL.md`. Gemini installs an extension from its root directory, and installing
a subdirectory straight from GitHub is not supported, so clone first:

```bash
git clone https://github.com/AllDmeat/kaiten-sdk.git
gemini extensions install --path ./kaiten-sdk/agent
```

**Cursor** loads the equivalent guidance from [`agent/rules/`](agent/rules).

## Requirements

- Swift 6.2+
- macOS 15+ (ARM) / Linux (x86-64, ARM)

## License

See [LICENSE](LICENSE) for details.
