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

#### 3. Output Size

Responses embed whole related entities next to the references to them — a card
carries `owner_id` *and* the entire owner, plus its board, type, lane, members,
tags and children. Commands drop those by default and keep only scalars and
`*_id` references:

```bash
kaiten get-card --id 123
# {"board_id":5,"column_id":3,"id":123,"owner_id":7,"title":"Fix login",...}
```

`--expand` brings back the ones you name, or `all` for every one of them:

```bash
kaiten get-card --id 123 --expand owner,tags
kaiten get-card --id 123 --expand all
```

Expansion is one level deep: an expanded value is itself stripped of its own
nested fields, so `--expand children` returns the children of a card without
*their* children. Ask for a deeper level with a second command.

A collection that is not expanded collapses to its ids, keeping its own key, so
the response never goes silent about a relation it holds:

```bash
kaiten get-card --id 123
# {"members":[821,904],"external_links":[5512,5513],"tags":[],"owner_id":821,...}

kaiten get-card --id 123 --expand members
# {"members":[{"id":821,"full_name":"…",…}],…}
```

The field therefore holds ids by default and entities when expanded. Keeping
the key is what makes a card with members and a card without report the same
field — `members: [821]` and `members: []` are both answers.

Only entities are trimmed, and an `id` is what marks one. A nested value
without an `id` is data, not a reference — a card's `properties` holds the
custom field values, `{"id_714":[1088]}` — so it is passed through whole. There
is no `properties_id` to stand in for it, and dropping it would lose the values
rather than a pointer to them.

Id arrays Kaiten sends itself (`tag_ids`, `parents_ids`) are passed through
untouched, and nothing is ever invented.

> **`children_ids` and `children_count` undercount.** They come straight from
> Kaiten and can report fewer children than a card has — both have been seen
> reporting eight for a card that has eleven, and expanding `children` returns
> the same short list. Use `list-card-children` when the children of a card
> have to be accurate.

To discover what a command offers, pass a name it does not have:

```bash
kaiten get-card --id 123 --expand '?'
# Error: Unknown --expand field: '?'. Available: board, children, column,
# external_links, files, lane, members, owner, parents, properties, tags, type, all
```

Quote the `?` — unquoted it is a shell glob and never reaches the CLI.

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

### Automations

| Method | Description |
|--------|-------------|
| `listAutomations(spaceId:)` | List automations in a space |
| `createAutomation(spaceId:type:actions:name:trigger:conditions:)` | Create an automation |
| `updateAutomation(spaceId:automationUid:name:trigger:conditions:actions:)` | Update an automation |
| `deleteAutomation(spaceId:automationUid:)` | Delete an automation |

Automations come in three types: `.onAction` (event), `.onDate` (due date) and
`.onDemand` (button).

Trigger, action, status and condition discriminators are exposed as Swift enums
(`AutomationTriggerType`, `AutomationActionType`, `AutomationStatus`,
`AutomationConditionClause`). Each has an `unknown(String)` case: Kaiten returns
values its documentation does not list, so undocumented values are preserved
rather than failing the whole response. Nested `data` payloads stay free-form
JSON — the documentation does not describe their fields.

```swift
let automations = try await client.listAutomations(spaceId: 38155)
for automation in automations {
  switch automation.actions?.first?.actionType {
  case .moveToPath: print("moves cards")
  case .unknown(let raw): print("new action type: \(raw)")
  default: break
  }
}

let created = try await client.createAutomation(
  spaceId: 38155,
  type: .onDemand,
  actions: [.init(actionType: .completeChecklists)],
  name: "Complete all checklists"
)
```

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

### Custom properties

Both option types carry a `properties` payload for the workspace's custom fields. Keys are
`id_<property-id>`; a value is an array of value IDs for select properties, a number for numeric
ones, or `null` to clear the property. Resolve the IDs first with `listCustomProperties()` and
`listCustomPropertySelectValues(propertyId:)` — they differ per workspace.

From the CLI, `create-card` and `update-card` take the same payload as a JSON object:

```bash
kaiten update-card --id 123 --properties '{"id_299126": [106915]}'
```

The object is parsed and validated locally, so a malformed payload fails before any request is sent.

### WIP limits

Columns and lanes carry a work-in-progress limit. `--wip-limit` sets the value and `--wip-limit-type`
selects what it counts — `1` for card count, `2` for card size:

```bash
kaiten update-column --board-id 42 --id 7 --wip-limit 5 --wip-limit-type 1
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

Coding agents guess CLI invocations badly — `kaiten cards list --board 42` looks reasonable and does
not exist. This repository ships a skill that fixes that: it makes the agent read `kaiten --help` and
`kaiten <subcommand> --help` before composing anything, and adds what the help cannot tell it — where
the config file lives, how to walk from spaces to boards to cards when you have no IDs, the two JSON
output shapes, pagination, and the fact that `429` retry is already built in.

One copy of that guidance lives in [`agent/skills/kaiten/`](agent/skills/kaiten). All three hosts
below read it from there.

### Claude Code

```
/plugin marketplace add AllDmeat/kaiten-sdk
/plugin install kaiten@kaiten
```

Then restart or run `/reload-plugins`. To update later:

```
/plugin marketplace update kaiten
/plugin update kaiten@kaiten
```

The same commands work outside the REPL as `claude plugin marketplace add …`, `claude plugin install
…`, and `claude plugin update …`.

### Cursor

Cursor 2.5+ reads plugins from a marketplace repository as well, and this repository is one — see
[`.cursor-plugin/marketplace.json`](.cursor-plugin/marketplace.json).

Add it with the `/add-plugin` command in the editor, or register the repository for a whole team
under Dashboard → Settings → Plugins → Team Marketplaces, where you paste the GitHub URL
`https://github.com/AllDmeat/kaiten-sdk` and review the parsed plugins. Installed plugins are
updated from the same marketplace UI.

Cursor reads the skill from `agent/skills/`, so it gets the same guidance as the other two hosts.

### Gemini CLI

```bash
gemini extensions install https://github.com/AllDmeat/kaiten-sdk
```

Gemini installs an extension from that extension's own root directory and cannot install a
subdirectory straight from GitHub, so each release ships [`agent/`](agent) as a self-contained
archive asset and Gemini takes that instead of cloning the repository. This works from release
`1.8.0` onward; earlier releases carry no extension asset.

To update:

```bash
gemini extensions update kaiten     # or: gemini extensions update --all
```

Restart the CLI afterwards — extension changes only take effect in a new session. Gemini activates
the skill when a task looks relevant, rather than loading it into every session.

## Requirements

- Swift 6.2+
- macOS 15+ (ARM) / Linux (x86-64, ARM)

## License

See [LICENSE](LICENSE) for details.
