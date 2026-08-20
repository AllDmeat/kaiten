# kaiten

[![Build](https://github.com/AllDmeat/kaiten/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/AllDmeat/kaiten/actions/workflows/build-and-test.yml)

`kaiten` is a command-line tool for the [Kaiten](https://kaiten.ru) API. It prints compact JSON to stdout, so you can pipe cards, spaces, users, sprints, and the rest of Kaiten into `jq` or scripts.

A Swift SDK powers the CLI and is available as a library too. See [Library bonus](#library-bonus).

## Install

### mise (recommended)

```sh
mise use github:AllDmeat/kaiten
kaiten --help
```

This installs the latest release binary for your platform. Add `-g` for a global install or append a release tag to pin a version.

### Release binary

Download the archive for your platform from [Releases](https://github.com/AllDmeat/kaiten/releases), extract it, and put `kaiten` on your `PATH`.

### From source

```sh
git clone https://github.com/AllDmeat/kaiten && cd kaiten
swift build -c release
```

The binary will be at `.build/release/kaiten`.

## Authenticate

Create an API token at `https://<your-company>.kaiten.ru/profile/api-key`. Then save the URL and token in `~/.config/kaiten/config.json`:

```json
{
  "url": "https://<your-company>.kaiten.ru/api/latest",
  "token": "<your-api-token>"
}
```

For CI, keep credentials in environment variables:

```sh
export KAITEN_URL="https://<your-company>.kaiten.ru/api/latest"
export KAITEN_TOKEN="<your-api-token>"
```

Each environment variable overrides the same value from the config file. Pass `--config <path>` to use another config file.

Next to the config you can keep a reference file — `~/.config/kaiten/reference.<ext>`, any format
you like (JSON, YAML, Markdown, plain text) — with the entity IDs, metadata, and working
preferences you actually use: spaces, boards, card types, users, notes on how to work with them —
whatever you need. To keep it elsewhere, point at it with an optional `reference` key in the
config:

```json
{
  "url": "https://<your-company>.kaiten.ru/api/latest",
  "token": "<your-api-token>",
  "reference": "~/notes/kaiten-reference.md"
}
```

The CLI ignores both the key and the file — they exist for AI agents. Agents read IDs from that
file instead of resolving names through the API (Kaiten instances accumulate same-named entities,
and name search can silently return the wrong one), offer to create the file if you have none, and
propose additions — but only write to it with your approval.

## Usage

```sh
kaiten --help
kaiten list-spaces
kaiten list-boards --space-id 42
kaiten list-cards --board-id 84 | jq '.[].title'
kaiten get-card --id 123
kaiten add-comment --card-id 123 --text "Checked from the CLI"
```

Every command has its own help. Read it before composing a request:

```sh
kaiten list-cards --help
kaiten add-comment --help
```

The CLI covers cards, spaces, boards, users, groups, sprints, documents, custom properties, checklists, files, automations, and the other Kaiten API resources. `kaiten --help` is the command reference for the installed version.

## Control JSON output size

Kaiten responses embed related entities next to their ids. A card can carry `owner_id` and the whole owner, plus its board, type, lane, members, tags, and children. The CLI drops nested entities by default and keeps scalars and id references:

```sh
kaiten get-card --id 123
```

Example output:

```json
{"board_id":5,"column_id":3,"id":123,"owner_id":7,"title":"Fix login"}
```

`--expand` brings back the fields you name. Use `all` to return every nested entity:

```sh
kaiten get-card --id 123 --expand owner,tags
kaiten get-card --id 123 --expand all
```

Expansion is one level deep: an expanded value is itself stripped of its own
nested fields, so `--expand children` returns the children of a card without
their children. Ask for a deeper level with a second command.

A collection that is not expanded collapses to its ids, keeping its own key, so
the response never goes silent about a relation it holds:

```sh
kaiten get-card --id 123
```

The response keeps collection keys and replaces their entities with ids:

```json
{"members":[821,904],"external_links":[5512,5513],"tags":[],"owner_id":821}
```

Expand a collection to return its entities:

```sh
kaiten get-card --id 123 --expand members
```

Only entities are trimmed, and an `id` is what marks one. A nested value
without an `id` is data, not a reference — a card's `properties` holds the
custom field values, `{"id_714":[1088]}` — so it is passed through whole. There
is no `properties_id` to stand in for it, and dropping it would lose the values
rather than a pointer to them.

Id arrays Kaiten sends itself (`tag_ids`, `parents_ids`) are passed through
untouched, and nothing is ever invented.

> [!WARNING]
> `children_ids` and `children_count` can undercount. They come straight from
> Kaiten and can report fewer children than a card has — both have been seen
> reporting eight for a card that has eleven, and expanding `children` returns
> the same short list. Use `list-card-children` when the children of a card
> have to be accurate.

To discover what a command offers, pass a name it does not have:

```sh
kaiten get-card --id 123 --expand '?'
```

Quote the `?` — unquoted it is a shell glob and never reaches the CLI.

The error lists every expandable field for that command.

## Library bonus

The same Kaiten API coverage is available as the `KaitenSDK` Swift package for iOS 18+ and macOS 15+.

Add it to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AllDmeat/kaiten.git", from: "0.1.0"),
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

Create a client and make the first request:

```swift
import KaitenSDK

let client = try KaitenClient(
    baseURL: "https://your-company.kaiten.ru/api/latest",
    token: "your-api-token"
)

let spaces = try await client.listSpaces()
```

The SDK provides typed errors, retries `429 Too Many Requests` responses automatically, and uses Bearer token authentication. The full Kaiten API documentation lives at [developers.kaiten.ru](https://developers.kaiten.ru).

### Cards

| Method | Description |
|--------|-------------|
| `listCards(boardId:)` | List all cards on a board |
| `getCard(id:)` | Fetch a single card by ID |
| `createCard(...)` | Create a new card |
| `updateCard(...)` | Update a card |
| `batchUpdateCards(...)` | Update multiple cards by criteria (background job) |
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
| `listCardAllowedUsers(cardId:...)` | List users with access to a card |
| `getCardTimeLogs(cardId:forDate:personal:)` | List time logs on a card |
| `createCardTimeLog(cardId:roleId:timeSpent:forDate:comment:)` | Add a time log to a card |
| `updateCardTimeLog(cardId:timeLogId:...)` | Update a time log |
| `deleteCardTimeLog(cardId:timeLogId:)` | Remove a time log |

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
| `createChecklistItem(checklistId:text:...)` | Add an item to a checklist by checklist ID |
| `updateChecklistItem(checklistId:itemId:...)` | Update a checklist item by checklist ID |
| `removeChecklistItem(checklistId:itemId:)` | Remove a checklist item by checklist ID |
| `listCardsWithChecklist(checklistId:onlySharedCards:)` | List cards that use a checklist |

The three checklist-item methods above address a checklist directly
(`/checklists/{checklist_id}/items`), without card context.

CLI: `add-item-to-checklist --checklist-id <id> --text <text>`,
`update-item-in-checklist --checklist-id <id> --item-id <id>`,
`remove-item-from-checklist --checklist-id <id> --item-id <id>`,
`list-checklist-cards --checklist-id <id> --only-shared-cards <bool>`.
The `only_shared_cards` query parameter is required by the API — requests
without it are rejected with 400 — but no filtering effect has been observed.

### External Links

| Method | Description |
|--------|-------------|
| `listExternalLinks(...)` | List external links on a card |
| `createExternalLink(...)` | Create an external link |
| `updateExternalLink(...)` | Update an external link |
| `removeExternalLink(...)` | Remove an external link |

### Service Desk External Recipients

| Method | Description |
|--------|-------------|
| `addServiceDeskExternalRecipient(cardId:email:)` | Add an external recipient to a card's service desk request |
| `removeServiceDeskExternalRecipient(cardId:email:)` | Remove an external recipient from a card's service desk request |

### Service Desk Services

| Method | Description |
|--------|-------------|
| `listServiceDeskServices()` | List service desk services in the company |

The API answers HTTP 403 for tokens without access to the service desk.

CLI: `list-service-desk-services`.

### Card Files

| Method | Description |
|--------|-------------|
| `attachFile(cardId:fileData:filename:)` | Attach a file to a card (multipart upload) |
| `updateFile(cardId:fileId:cardCover:)` | Update a file attached to a card |
| `detachFile(cardId:fileId:)` | Detach a file from a card |

The attach response is one of two shapes — a legacy attachment (integer `id`) or a
private file (UUID string `id`) — the same pair a card's `files` array carries.

From the CLI:

```bash
kaiten attach-card-file --card-id 123 --file ./diagram.png
kaiten update-card-file --card-id 123 --file-id 7 --card-cover true
kaiten detach-card-file --card-id 123 --file-id 7
```

### Private Card Files

| Method | Description |
|--------|-------------|
| `attachPrivateFile(cardUid:fileData:filename:)` | Attach a file to a card addressed by UID (multipart upload) |
| `getPrivateFile(cardUid:fileId:responseType:)` | Get the signed URL of a private card file |
| `deletePrivateFile(cardUid:fileId:)` | Delete a private card file |

These routes address the card by UID and the file by UUID string id, and are live only
when "Restricted file access" is enabled in company settings. The docs mark the section
as under active development.

From the CLI:

```bash
kaiten attach-private-card-file --card-uid aaaa-11 --file ./diagram.png
kaiten get-private-card-file --card-uid aaaa-11 --file-id bbbb-22
kaiten delete-private-card-file --card-uid aaaa-11 --file-id bbbb-22
```

### Private Comment Files

| Method | Description |
|--------|-------------|
| `attachFileToComment(cardUid:commentUid:fileData:filename:)` | Attach a file to a card comment (multipart upload) |
| `getCommentFile(cardUid:commentUid:fileId:responseType:)` | Get a signed URL for a comment file |
| `deleteCommentFile(cardUid:commentUid:fileId:)` | Delete a comment file |

All three endpoints require "Restricted file access" enabled in company settings and
address the card, the comment and the file by string UID. `getCommentFile` requests the
`json` disposition by default; `inline` and `attachment` answer with a redirect to the
file content instead of a JSON body.

From the CLI:

```bash
kaiten attach-comment-file --card-uid CARD-UID --comment-uid COMMENT-UID --file ./log.txt
kaiten get-comment-file --card-uid CARD-UID --comment-uid COMMENT-UID --file-id FILE-ID
kaiten delete-comment-file --card-uid CARD-UID --comment-uid COMMENT-UID --file-id FILE-ID
```

### Private Custom Property Files

| Method | Description |
|--------|-------------|
| `attachFileToCustomProperty(cardUid:propertyUid:fileData:filename:)` | Attach a file to a card custom property (multipart upload) |
| `getCustomPropertyFileUrl(cardUid:propertyUid:fileId:responseType:)` | Get the signed URL of a custom property file |
| `deleteCustomPropertyFile(cardUid:propertyUid:fileId:)` | Delete a custom property file |

These endpoints require the "Restricted file access" company setting and are
marked by Kaiten as under active development. Resources are addressed by string
UIDs, so a 404 surfaces as `unexpectedResponse(statusCode: 404)`.

The documented `response_type` query parameter is exposed as the
`CustomPropertyFileResponseType` enum. With `.json` (the default) the API
returns the signed URL; with `.inline` or `.attachment` it redirects (302) to
the file itself, which the SDK's transport follows, so only `.json` produces a
decodable response.

From the CLI:

```bash
kaiten attach-custom-property-file --card-uid c1a2 --property-uid p3b4 --file ./report.pdf
kaiten get-custom-property-file --card-uid c1a2 --property-uid p3b4 --file-id f5c6
kaiten delete-custom-property-file --card-uid c1a2 --property-uid p3b4 --file-id f5c6
```

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
| `getSpaceBoard(spaceId:id:)` | Fetch a board within a space, with its position on the space |
| `createBoard(...)` | Create a board |
| `updateBoard(...)` | Update a board |

CLI: `get-space-board --space-id <id> --id <id>`.

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
| `createCustomProperty(name:type:...)` | Create a custom property definition |
| `updateCustomProperty(id:...)` | Update a custom property definition |
| `removeCustomProperty(id:)` | Remove a custom property definition |
| `listCustomPropertySelectValues(propertyId:)` | List select values for a custom property |
| `getCustomPropertySelectValue(propertyId:id:)` | Get a single select value |
| `createCustomPropertySelectValue(propertyId:value:color:)` | Create a select value for a custom property |
| `updateCustomPropertySelectValue(propertyId:id:value:color:condition:sortOrder:deleted:)` | Update a select value |
| `removeCustomPropertySelectValue(propertyId:id:)` | Remove a select value |
| `listCustomPropertyTreeEntities(propertyId:)` | List tree entities of a custom property |
| `addCustomPropertyTreeEntity(propertyId:treeEntityUid:)` | Add a tree entity to a custom property |
| `deleteCustomPropertyTreeEntity(propertyId:uid:)` | Delete a tree entity from a custom property |
| `listCustomPropertyCatalogValues(propertyId:query:conditions:offset:limit:)` | List catalog values for a custom property |
| `getCustomPropertyCatalogValue(propertyId:id:)` | Get a single catalog value |
| `createCustomPropertyCatalogValue(propertyId:value:)` | Create a catalog value for a custom property |
| `updateCustomPropertyCatalogValue(propertyId:id:condition:value:deleted:)` | Update a catalog value |
| `removeCustomPropertyCatalogValue(propertyId:id:)` | Remove a catalog value |
| `listCollectiveScoreValues(cardId:propertyId:)` | List collective score values of a custom property on a card |
| `createCollectiveScoreValue(cardId:propertyId:value:)` | Create a collective score value |
| `updateCollectiveScoreValue(cardId:propertyId:scoreValueId:value:)` | Update a collective score value |
| `listCollectiveVoteValues(cardId:propertyId:)` | List collective vote values on a card |
| `createCollectiveVoteValue(cardId:propertyId:numberVote:emojiVote:)` | Create a collective vote value on a card |
| `updateCollectiveVoteValue(cardId:propertyId:voteValueId:numberVote:)` | Update a collective vote value |
| `deleteCollectiveVoteValue(cardId:propertyId:voteValueId:emojiVote:)` | Remove a collective vote value |

Property discriminators are exposed as Swift enums (`CustomPropertyType`,
`CustomPropertyCondition`, `CustomPropertyVoteVariant`,
`CustomPropertyValuesType`). Each has an `unknown(String)` case that preserves
values the documentation does not list. The `data` and `fields_settings`
payloads stay free-form JSON — their shape depends on the property type.

CLI: `create-custom-property --name <name> [--type <type>] ...`,
`update-custom-property --id <id> [--name <name>] [--condition <condition>] ...`,
`remove-custom-property --id <id>`.

Catalog values belong to catalog-type custom properties. Their `value` payload
is a free-form object of catalog field UID to field value pairs. The condition
discriminator is exposed as the Swift enum `CatalogValueCondition`
(`.active` / `.inactive`) with an `unknown(String)` case that preserves values
the documentation does not list.

CLI: `list-custom-property-catalog-values`, `get-custom-property-catalog-value`,
`create-custom-property-catalog-value --property-id <id> --value '<JSON object>'`,
`update-custom-property-catalog-value`, `remove-custom-property-catalog-value`.

The select value `condition` discriminator is exposed as the
`CustomPropertySelectValueCondition` Swift enum (`.active` / `.inactive`) with an
`unknown(String)` case, so undocumented values are preserved rather than failing
the whole response.

CLI: `list-custom-property-select-values --property-id <id>`,
`get-custom-property-select-value --property-id <id> --id <id>`,
`create-custom-property-select-value --property-id <id> --value <text>`,
`update-custom-property-select-value --property-id <id> --id <id>`,
`remove-custom-property-select-value --property-id <id> --id <id>`.

Collective vote values are votes users cast on a card for a vote-type custom
property. A scale or rating property carries `number_vote`; an emoji-set
property carries `emoji_vote`. Updating with `numberVote: .some(nil)` sends an
explicit JSON `null` and clears the vote.

CLI: `list-collective-vote-values`, `create-collective-vote-value`,
`update-collective-vote-value`, `remove-collective-vote-value`, each with
`--card-id` and `--property-id`; the update and remove commands also take
`--vote-value-id`.

### Users

| Method | Description |
|--------|-------------|
| `listUsers()` | List all users |
| `getCurrentUser()` | Get the current user |
| `updateUser(id:...)` | Update a user |
| `getCurrentUserBlockers()` | Get cards blocked on the current user (see [Card Blocker Users](#card-blocker-users)) |

`updateUser` changes only the fields that are set; the API requires at least
one field and answers HTTP 400 otherwise. Closed-set fields are exposed as
Swift enums (`UserAvatarType`, `UserTheme`, `UserEmailFrequency`,
`UserEmailSubject`, `UserUiVersion`, `UserNotificationChannel`), each with an
`unknown` case that preserves values the documentation does not list. The
`email_settings`, `telegram_settings`, `slack_settings` and
`notification_settings` payloads stay free-form JSON — the documentation does
not describe their fields.

CLI: `update-user --id <id> [--full-name <name>] [--theme <theme>] ...`.

### Company Users

| Method | Description |
|--------|-------------|
| `listCompanyUsers(invitesOnly:withTransferAccessStatus:forMembersSection:ownerOnly:onlyPaid:onlyRecordsCount:onlyVirtual:offset:limit:query:accessTypePermissions:sdAccessType:takeLicence:temporarilyInactiveStatus:groupIds:permissions:)` | List company users |
| `updateCompanyUser(id:appsPermissions:temporarilyInactive:)` | Update a company user |
| `removeVirtualUser(id:)` | Remove a virtual user |

Listing and updating require an API token of a user with access to the
administrative section "Members"; removing a virtual user requires access to
the administrative section "Resource planning". Without that access the API
returns 403.

CLI: `kaiten list-company-users` (with the same filters as the SDK method),
`kaiten update-company-user` with `--id`, `--apps-permissions`,
`--temporarily-inactive`, and `kaiten remove-virtual-user` with `--id`.

### Group Users

| Method | Description |
|--------|-------------|
| `listGroupUsers(groupUid:)` | List users in a company group |
| `addUserToGroup(groupUid:userId:requestId:operatorComment:)` | Add a user to a company group |
| `removeUserFromGroup(groupUid:userId:)` | Remove a user from a company group |

Groups are addressed by string UID. Kaiten marks the group-users endpoints as
under active development, so their responses may change.

CLI: `list-group-users --group-uid <uid>`,
`add-group-user --group-uid <uid> --user-id <id>` with optional `--request-id`
and `--operator-comment`,
`remove-group-user --group-uid <uid> --user-id <id>`.

### Tags

| Method | Description |
|--------|-------------|
| `listTags(limit:offset:spaceId:ids:query:)` | List tags in the company |
| `addTag(name:...)` | Add a tag to the company |

Live responses carry `uid`, `locked` and `fts_version` fields the documentation
does not list. The documentation also lists the list endpoint's filter query
parameters on the add endpoint; the SDK exposes them, their effect on creation
is unverified.

CLI: `list-tags` with `--limit`, `--offset`, `--space-id`, `--ids`, `--query`;
`add-tag --name <name>`.

### User Roles

| Method | Description |
|--------|-------------|
| `listUserRoles()` | List user roles in the company |
| `getUserRole(id:)` | Get a single user role |
| `createUserRole(name:)` | Create a user role |
| `updateUserRole(id:name:)` | Update a user role |
| `deleteUserRole(id:replaceRoleId:)` | Delete a user role, moving its users to a replacement role |

Deleting a role requires a replacement: users holding the deleted role are
moved to the role named by `replaceRoleId`, and the API returns the deleted
role.

CLI: `list-user-roles`, `get-user-role --id <id>`,
`create-user-role --name <name>`, `update-user-role --id <id> --name <name>`,
`delete-user-role --id <id> --replace-role-id <id>`.

### Card Types & Sprints

| Method | Description |
|--------|-------------|
| `listCardTypes()` | List card types |
| `getCardType(id:)` | Get a card type |
| `createCardType(letter:name:color:properties:cardProperties:suggestFields:)` | Create a new card type |
| `updateCardType(id:letter:name:color:properties:cardProperties:suggestFields:)` | Update a card type |
| `deleteCardType(id:replaceTypeId:)` | Remove a card type, replacing it in existing cards |
| `listCardTypeTreeEntities(typeId:)` | List tree entities of a card type |
| `addCardTypeTreeEntity(typeId:treeEntityUid:)` | Add a tree entity to a card type |
| `deleteCardTypeTreeEntity(typeId:uid:)` | Delete a tree entity from a card type |
| `listSprints()` | List sprints |
| `getSprintSummary(...)` | Get sprint summary |

The `regular_property` key of a card type's suggested properties is exposed as
the `CardTypeRegularProperty` Swift enum with an `unknown(String)` case, so
values the documentation does not list survive decoding.

CLI: `list-card-types`, `get-card-type --id <id>`,
`create-card-type --letter <letter> --name <name> --color <color>`,
`update-card-type --id <id>`,
`delete-card-type --id <id> --replace-type-id <id>`.

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

### Space Users

| Method | Description |
|--------|-------------|
| `listSpaceUsers(spaceId:includeInheritedAccess:inactive:)` | List users of a space |
| `inviteUserToSpace(spaceId:email:roleId:guest:operatorComment:sendEmail:)` | Invite a user to a space |
| `getSpaceUser(spaceId:userId:)` | Get a user of a space |
| `updateSpaceUser(spaceId:userId:roleId:notificationsEnabled:spaceGroupId:settings:)` | Change a space user's role and notification settings |
| `removeSpaceUser(spaceId:userId:)` | Remove a user from a space |

Role ids are string UIDs. Preset roles: reader
`06ccb31f-426b-4fa3-b7e5-861daee95696`, writer
`a431ed00-1b32-4cc7-92b6-85e4bc7de40e`, admin
`07ea3efc-a004-4d31-8683-4bb2084e209b`.

CLI: `list-space-users --space-id <id>`,
`invite-space-user --space-id <id> --email <email>`,
`get-space-user --space-id <id> --user-id <id>`,
`update-space-user --space-id <id> --user-id <id>`,
`remove-space-user --space-id <id> --user-id <id>`.
### Space Template Checklists

| Method | Description |
|--------|-------------|
| `listSpaceTemplateChecklists(spaceUid:)` | List template checklists in a space |
| `createSpaceTemplateChecklist(spaceUid:name:sortOrder:)` | Create a template checklist in a space |
| `updateSpaceTemplateChecklist(spaceUid:templateChecklistUid:name:sortOrder:newSpaceUid:)` | Update a space template checklist |
| `removeSpaceTemplateChecklist(spaceUid:templateChecklistUid:)` | Remove a template checklist from a space |

Spaces and template checklists are addressed by string UIDs here, not integer
IDs. The list response embeds the checklist items; the documented create and
update responses return the checklist without them. Remove answers with an
object carrying only the deleted checklist UID.

CLI: `list-space-template-checklists --space-uid <uid>`,
`create-space-template-checklist --space-uid <uid> [--name <name>] [--sort-order <n>]`,
`update-space-template-checklist --space-uid <uid> --template-checklist-uid <uid> [--name <name>] [--sort-order <n>] [--new-space-uid <uid>]`,
`remove-space-template-checklist --space-uid <uid> --template-checklist-uid <uid>`.

### Space Template Checklist Items

| Method | Description |
|--------|-------------|
| `createSpaceTemplateChecklistItem(spaceUid:templateChecklistUid:text:sortOrder:)` | Create an item in a space template checklist |
| `updateSpaceTemplateChecklistItem(spaceUid:templateChecklistUid:itemUid:text:sortOrder:)` | Update an item in a space template checklist |
| `removeSpaceTemplateChecklistItem(spaceUid:templateChecklistUid:itemUid:)` | Remove an item from a space template checklist |

CLI: `create-space-template-checklist-item --space-uid <uid>
--template-checklist-uid <uid> --text <text>`,
`update-space-template-checklist-item --space-uid <uid>
--template-checklist-uid <uid> --item-uid <uid>`,
`remove-space-template-checklist-item --space-uid <uid>
--template-checklist-uid <uid> --item-uid <uid>`.

### Iterations

| Method | Description |
|--------|-------------|
| `getCardIterationsHistory(cardUid:)` | Get the iterations history of a card |
| `listIterations(spaceUid:status:withData:limit:offset:order:)` | List iterations of a space |
| `createIteration(spaceUid:title:goal:startDate:finishDate:)` | Create an iteration |
| `getIteration(spaceUid:id:)` | Get an iteration by ID |
| `updateIteration(spaceUid:id:title:goal:status:startDate:finishDate:actualFinishDate:newIterationId:)` | Update an iteration |
| `deleteIteration(spaceUid:id:newIterationId:)` | Delete an iteration |
| `listIterationCards(spaceUid:iterationId:status:)` | List card records of an iteration |
| `addCardToIteration(spaceUid:iterationId:cardUid:)` | Add a card to an iteration |
| `removeCardFromIteration(spaceUid:iterationId:cardUid:)` | Remove a card from an iteration |

The Kaiten iterations API is in beta and may change. Spaces, iterations and
cards are addressed by string UIDs rather than integer IDs.

The iteration status is exposed as the `IterationStatus` Swift enum (`planned`,
`active`, `closed`, `removed`) with an `unknown(String)` case that preserves
values the documentation does not list. Status transitions are limited to
planned-to-active and active-to-closed; deletion gives the iteration the
`removed` status. The `committed` and `velocity` statistics stay free-form
JSON — the documentation does not describe their fields.

```swift
let iterations = try await client.listIterations(
  spaceUid: "sp-uid-1",
  status: [.active],
  withData: "cards"
)
for iteration in iterations {
  print(iteration.title ?? "", iteration.cards?.count ?? 0)
}
```

CLI: `get-card-iterations-history --card-uid <uid>`,
`list-iterations --space-uid <uid>` with `--status`, `--with-data`, `--limit`,
`--offset`, `--order`;
`create-iteration --space-uid <uid> --title <title>` with `--goal`,
`--start-date`, `--finish-date`;
`get-iteration --space-uid <uid> --id <id>`,
`update-iteration --space-uid <uid> --id <id>` with `--title`, `--goal`,
`--status`, `--start-date`, `--finish-date`, `--actual-finish-date`,
`--new-iteration-id`;
`delete-iteration --space-uid <uid> --id <id> [--new-iteration-id <id>]`,
`list-iteration-cards --space-uid <uid> --iteration-id <id> [--status <status>]`,
`add-card-to-iteration --space-uid <uid> --iteration-id <id> --card-uid <uid>`,
`remove-card-from-iteration --space-uid <uid> --iteration-id <id> --card-uid <uid>`.

### Blocker Categories

| Method | Description |
|--------|-------------|
| `listBlockerCategories()` | List blocker categories in the company |
| `addBlockerCategory(blockerId:name:)` | Add a category to a card blocker |
| `removeBlockerCategory(blockerId:categoryUid:)` | Remove a category from a card blocker |

CLI: `list-blocker-categories`, `add-blocker-category --blocker-id <id> --name <name>`,
`remove-blocker-category --blocker-id <id> --category-uid <uid>`.

### Card Blocker Users

| Method | Description |
|--------|-------------|
| `listCardBlockerUsers(blockerId:)` | List users assigned to a card blocker |
| `addCardBlockerUser(blockerId:userId:)` | Add a user to a card blocker |
| `removeCardBlockerUser(blockerId:userId:)` | Remove a user from a card blocker |
| `getCurrentUserBlockers()` | Get cards blocked on the current user |

The current-user blockers endpoint is documented as returning an object, but a
live instance answers with an empty JSON array when the user has no blockers.
The SDK maps that shape to an empty result: `blocked_cards` is an empty array
and `summary` is `nil`.

CLI: `list-card-blocker-users --blocker-id <id>`,
`add-card-blocker-user --blocker-id <id> --user-id <id>`,
`remove-card-blocker-user --blocker-id <id> --user-id <id>`,
`get-current-user-blockers`.

### Card SLA

| Method | Description |
|--------|-------------|
| `getCardSlaMeasurements(cardId:)` | Get card SLA measurements |

SLA measurements exist only for service desk request cards; for any other card,
and for archived cards, the API answers HTTP 400.

### Audit Logs

| Method | Description |
|--------|-------------|
| `listAuditLogs(from:to:authorId:authorUid:categories:actions:id:offset:limit:)` | List audit log events for the current company |

Requires an API token of a user with access to the administrative section
"Audit log". Events are ordered by creation time from newest to oldest.

Category and action discriminators are exposed as Swift enums
(`AuditLogCategory`, `AuditLogAction`), each with an `unknown(String)` case
that preserves values the documentation does not list. The `details` payload
stays free-form JSON — its shape depends on category and action and is not
described in the documentation.

```swift
let page = try await client.listAuditLogs(
  categories: [.auth],
  actions: [.signInFail],
  limit: 200
)
for event in page.items {
  print(event.message ?? "")
}
```

CLI: `kaiten list-audit-logs` with `--from`, `--to`, `--author-id`,
`--author-uid`, `--categories`, `--actions`, `--id`, `--offset`, `--limit`.

### Custom Directories

| Method | Description |
|--------|-------------|
| `listCustomDirectories(includeFields:includeAuthor:includeRecordsCount:query:conditions:offset:limit:)` | List custom directories in the company |
| `createCustomDirectory(name:description:multiSelect:allowEditing:displayFieldIndex:fields:)` | Create a custom directory |
| `getCustomDirectory(directoryId:)` | Get a custom directory |
| `updateCustomDirectory(directoryId:name:description:condition:multiSelect:allowEditing:fields:)` | Update a custom directory |
| `deleteCustomDirectory(directoryId:)` | Delete a custom directory (soft delete, condition becomes `removed`) |

The custom-directories API is documented as beta: parameters, attributes and
response formats are subject to change. Directory and field conditions and
field types are exposed as Swift enums (`CustomDirectoryCondition`,
`CustomDirectoryFieldType`), each with an `unknown(String)` case that preserves
values the documentation does not list.

```swift
let directory = try await client.createCustomDirectory(
  name: "Contacts",
  fields: [
    .init(fieldType: .string, name: "Name", required: true),
    .init(fieldType: .email, name: "Email"),
  ]
)

let page = try await client.listCustomDirectories(conditions: [.active, .inactive])
for directory in page.items {
  print(directory.name ?? "")
}
```

CLI: `list-custom-directories` with `--include-fields`, `--include-author`,
`--include-records-count`, `--query`, `--conditions`, `--offset`, `--limit`;
`create-custom-directory --name <name>` with `--description`, `--multi-select`,
`--allow-editing`, `--display-field-index`, `--fields <json>`;
`get-custom-directory --directory-id <id>`;
`update-custom-directory --directory-id <id>` with `--name`, `--description`,
`--clear-description`, `--condition`, `--multi-select`, `--allow-editing`,
`--fields <json>`; `delete-custom-directory --directory-id <id>`.

### Custom Directory Fields

| Method | Description |
|--------|-------------|
| `listCustomDirectoryFields(directoryId:includeAuthor:conditions:)` | List fields of a custom directory |
| `createCustomDirectoryField(directoryId:name:type:sortOrder:required:isDisplay:)` | Create a field in a custom directory |
| `getCustomDirectoryField(directoryId:fieldId:)` | Get a field of a custom directory |
| `updateCustomDirectoryField(directoryId:fieldId:name:condition:sortOrder:required:isDisplay:)` | Update a field of a custom directory |
| `deleteCustomDirectoryField(directoryId:fieldId:)` | Soft-delete a field of a custom directory |

The custom directories API is documented as beta and may change. Directories and
fields are addressed by string UUIDs. Type and condition discriminators are
exposed as Swift enums (`CustomDirectoryFieldType`,
`CustomDirectoryCondition`), each with an `unknown(String)` case that
preserves values the documentation does not list. Deleting a field soft-deletes
it: the API answers with the removed field, its condition set to `.removed`.

```swift
let field = try await client.createCustomDirectoryField(
  directoryId: "dir-uid-1",
  name: "Email",
  type: .email
)

let fields = try await client.listCustomDirectoryFields(
  directoryId: "dir-uid-1",
  conditions: [.active]
)
```

CLI: `list-custom-directory-fields`, `create-custom-directory-field`,
`get-custom-directory-field`, `update-custom-directory-field`,
`delete-custom-directory-field`, each taking `--directory-id` (and `--field-id`
where a single field is addressed).
### Custom Directory Records

| Method | Description |
|--------|-------------|
| `listCustomDirectoryRecords(directoryId:query:profile:includeValues:includeAuthor:conditions:filters:filterOperator:offset:limit:)` | List records in a custom directory |
| `createCustomDirectoryRecord(directoryId:values:responseProfile:)` | Create a record |
| `getCustomDirectoryRecord(directoryId:recordId:profile:)` | Get a record |
| `updateCustomDirectoryRecord(directoryId:recordId:condition:values:responseProfile:)` | Update a record's values and/or condition |
| `deleteCustomDirectoryRecord(directoryId:recordId:)` | Soft-delete a record (condition becomes `removed`) |
| `listCustomDirectoryRecordCards(directoryId:recordId:filter:offset:limit:)` | List cards linked to a record |

The custom directories API is documented as beta and may change. Which record
fields a response includes depends on the `profile`/`responseProfile`
parameter (`CustomDirectoryProfile`; the documented `none` value is spelled
`.noRelations` in Swift so it cannot be shadowed by `Optional.none`). The
record condition is exposed as the `CustomDirectoryRecordCondition` enum with
an `unknown(String)` case that preserves values the documentation does not
list. Request `values` maps and populated relation objects stay free-form
JSON — the documentation does not describe their shapes.

```swift
let page = try await client.listCustomDirectoryRecords(
  directoryId: "d1",
  profile: .details,
  conditions: [.active]
)
for record in page.items {
  print(record.display_value ?? "")
}
```

CLI: `list-custom-directory-records`, `create-custom-directory-record`,
`get-custom-directory-record`, `update-custom-directory-record`,
`delete-custom-directory-record`, `list-custom-directory-record-cards` — all
take `--directory-id`, the record-scoped ones also `--record-id`.

### Group Admins

| Method | Description |
|--------|-------------|
| `listGroupAdmins(groupUid:)` | List admins of a group |
| `addGroupAdmin(groupUid:userId:)` | Add a user as an admin of a group |
| `removeGroupAdmin(groupUid:userId:)` | Remove an admin from a group |

Groups are addressed by string UID. Adding and removing an admin both return
the affected user.

CLI: `list-group-admins --group-uid <uid>`,
`add-group-admin --group-uid <uid> --user-id <id>`,
`remove-group-admin --group-uid <uid> --user-id <id>`.

### Document Schemas

| Method | Description |
|--------|-------------|
| `getDocumentSchema(id:format:)` | Get the document data schema |

Returns the schema used to validate and describe document data in ProseMirror
JSON format. Pass `latest` as the `id` for the latest available schema, or a
concrete version such as `v25`; the response `version` field always carries the
resolved `v{number}` version.

The response shape follows the requested `DocumentSchemaFormat`: `.draft06`
(the API default) returns a JSON Schema draft-06 document, `.proseMirror`
returns sanitized ProseMirror node and mark specs. Exactly one of the
`draft06` and `proseMirror` accessors on the result is populated:

```swift
let schema = try await client.getDocumentSchema(id: "latest")
print(schema.draft06?.version ?? "")

let specs = try await client.getDocumentSchema(id: "latest", format: .proseMirror)
print(specs.proseMirror?.topNode ?? "")
```

CLI: `kaiten get-document-schema --id latest` with optional `--format`
(`draft-06` or `prosemirror`).

### Group Entities

| Method | Description |
|--------|-------------|
| `listGroupEntities(groupUid:)` | List entities of a company group |
| `addGroupEntity(groupUid:entityUid:roleIds:)` | Add an entity to a company group |
| `updateGroupEntity(groupUid:uid:roleIds:)` | Update the roles of an entity in a company group |
| `removeGroupEntity(groupUid:uid:)` | Remove an entity from a company group |

Group entities attach spaces, documents, folders and story maps to a company
group. The entity type discriminator is exposed as the `GroupEntityType` Swift
enum with an `unknown(String)` case that preserves values the documentation
does not list. The `role_permissions` payload stays free-form JSON — its
nested permission objects are not described in the documentation.

```swift
let entities = try await client.listGroupEntities(groupUid: "grp-1")
for entity in entities where entity.groupEntityType == .space {
  print(entity.title ?? "")
}

let added = try await client.addGroupEntity(
  groupUid: "grp-1",
  entityUid: "ent-1",
  roleIds: ["role-1"]
)
```

CLI: `list-group-entities --group-uid <uid>`,
`add-group-entity --group-uid <uid> --entity-uid <uid> --role-ids <uids>`,
`update-group-entity --group-uid <uid> --uid <uid> --role-ids <uids>`,
`remove-group-entity --group-uid <uid> --uid <uid>`.

### Document Groups

| Method | Description |
|--------|-------------|
| `listDocumentGroups(query:role:offset:limit:)` | List document groups |
| `searchDocumentGroups(query:condition:startPosition:role:offset:limit:)` | Search document groups via OpenSearch (`version=2`), with a cursor for pagination |
| `getDocumentGroup(uid:relations:)` | Get a document group |
| `createDocumentGroup(title:parentEntityUid:forEveryoneAccessRoleId:sortOrder:key:)` | Create a document group |
| `updateDocumentGroup(uid:title:parentEntityUid:sortOrder:access:...)` | Update a document group |
| `deleteDocumentGroup(uid:)` | Remove a document group |

The access discriminator is exposed as the `DocumentGroupAccess` Swift enum
(`.forEveryone`, `.byInvite`) with an `unknown(String)` case that preserves
values the documentation does not list. `deleteDocumentGroup` returns the
removed group stub with `archived` set to `true`, and answers HTTP 400 while
the group still has child tree entities.

```swift
let groups = try await client.listDocumentGroups(query: "handbook")
for group in groups where group.documentGroupAccess == .forEveryone {
  print(group.title ?? "")
}

let created = try await client.createDocumentGroup(title: "Handbook", key: "HB")
```

CLI: `list-document-groups`, `search-document-groups`, `get-document-group`,
`create-document-group`, `update-document-group`, `delete-document-group`.

### Documents

| Method | Description |
|--------|-------------|
| `listDocuments(query:offset:limit:)` | List documents (version=1 response) |
| `searchDocuments(query:condition:fields:startPosition:includeSearchPreview:offset:limit:)` | Search documents via OpenSearch (version=2 response) |
| `getDocument(uid:)` | Get a document, including its content |
| `createDocument(sortOrder:title:parentEntityUid:forEveryoneAccessRoleId:cloneUid:cloneVersion:key:)` | Create a document |
| `updateDocument(uid:title:sortOrder:publishDate:data:access:parentEntityUid:forEveryoneAccessRoleId:isPublic:redirectUrl:hiddenOnPublicSite:settings:backupVersion:publishedVersion:key:iconType:iconValue:iconColor:notificationPeriodStart:notificationPeriodEnd:slug:)` | Update a document |
| `deleteDocument(uid:)` | Remove a document |

Documents are addressed by string UID. `GET /documents` answers in two shapes:
the default (version=1) response is a plain array exposed as a `Page`, while
`searchDocuments` calls the same endpoint with `version=2` and returns a
`result` list plus an opaque `position` cursor — pass it back as
`startPosition` to fetch the next page.

Access and icon type discriminators are exposed as Swift enums
(`DocumentAccess`, `DocumentIconType`), each with an `unknown(String)` case
that preserves values the documentation does not list. A document's `data`
holds the ProseMirror content: live responses return it as a JSON-encoded
string even though the documentation declares an object, so the SDK accepts
both shapes.

```swift
let page = try await client.listDocuments(query: "handbook")
for document in page.items {
  print(document.title ?? "")
}

let document = try await client.getDocument(uid: "doc-uid")
print(document.data?.value1 ?? "")  // ProseMirror JSON string
```

CLI: `kaiten list-documents` with `--query`, `--offset`, `--limit`;
`kaiten search-documents` with `--query`, `--condition`, `--fields`,
`--start-position`, `--include-search-preview`, `--offset`, `--limit`;
`kaiten get-document --document-uid <uid>`;
`kaiten create-document --sort-order <n>` with `--title`,
`--parent-entity-uid`, `--for-everyone-access-role-id`, `--clone-uid`,
`--clone-version`, `--key`;
`kaiten update-document --document-uid <uid>` with `--title`, `--sort-order`,
`--publish-date`, `--data`, `--access`, `--parent-entity-uid`,
`--for-everyone-access-role-id`, `--public`, `--redirect-url`,
`--hidden-on-public-site`, `--settings`, `--backup-version`,
`--published-version`, `--key`, `--icon-type`, `--icon-value`, `--icon-color`,
`--notification-period-start`, `--notification-period-end`, `--slug`;
`kaiten delete-document --document-uid <uid>`.

### Groups

| Method | Description |
|--------|-------------|
| `listGroups(withTreeEntities:withUsersCount:withSyncGroupAttribute:condition:query:limit:offset:)` | List user groups in the company |
| `createGroup(name:permissions:addToCardsAndSpacesEnabled:)` | Create a user group |
| `getGroup(uid:)` | Get a user group |
| `updateGroup(uid:name:permissions:addToCardsAndSpacesEnabled:)` | Update a user group |
| `removeGroup(uid:)` | Remove a user group; returns the removed group |

Requires an API token of a user with access to the administrative section
"Members" — other tokens get HTTP 403. Kaiten documents the groups endpoints as
under active development, so attributes are subject to change. The `condition`
filter is exposed as the `GroupCondition` enum (`.active`, `.inactive`) with an
`unknown(Int)` case that preserves undocumented values. The `permissions` field
is a bit mask; sum the documented values to combine permissions.

```swift
let groups = try await client.listGroups(condition: .active)

let created = try await client.createGroup(
  name: "QA engineers",
  permissions: 3  // administrative sections "Members" + "Billing"
)
```

CLI: `list-groups` with `--with-tree-entities`, `--with-users-count`,
`--with-sync-group-attribute`, `--condition`, `--query`, `--limit`, `--offset`;
`create-group --name <name>` with `--permissions`,
`--add-to-cards-and-spaces-enabled`; `get-group --uid <uid>`;
`update-group --uid <uid>` with `--name`, `--permissions`,
`--add-to-cards-and-spaces-enabled`; `remove-group --uid <uid>`.

### Timesheet

| Method | Description |
|--------|-------------|
| `listTimeLogs(from:to:tagIds:userIds:groupIds:spaceIds:boardIds:columnIds:cardIds:visibleColumnIds:condition:groupBy:timePrecision:timeUnit:withDailyDistribution:onlyGeneralSum:offset:limit:)` | List time logs for the whole company |

Requires an API token of a user with access to the company timesheet; without
it the API answers HTTP 403 with an empty body. The SDK models the documented
(ungrouped) response shape; the grouping parameters are forwarded as
documented, but the documentation does not describe how they change the
response.

```swift
let page = try await client.listTimeLogs(
  from: "2026-04-01",
  to: "2026-04-30",
  userIds: [42]
)
for timeLog in page.items {
  print(timeLog.time_spent ?? 0)
}
```

CLI: `kaiten list-time-logs` with `--from`, `--to`, `--tag-ids`, `--user-ids`,
`--group-ids`, `--space-ids`, `--board-ids`, `--column-ids`, `--card-ids`,
`--visible-column-ids`, `--condition`, `--group-by`, `--time-precision`,
`--time-unit`, `--with-daily-distribution`, `--only-general-sum`, `--offset`,
`--limit`.

### Tree Entities

| Method | Description |
|--------|-------------|
| `listTreeEntities(parentEntityUid:levelsCount:offset:limit:)` | List company tree entities |

Returns nodes of the company entity tree: spaces, documents, document groups
and story maps. Kaiten documents the endpoint as under active development, so
parameters, attributes and response formats are subject to change. Each entity
type carries its own extra fields beyond the common ones.

The entity type discriminator is exposed as the `TreeEntityType` Swift enum
with an `unknown(String)` case: the documentation lists no values, so anything
new the API returns is preserved rather than failing the whole response.

```swift
let page = try await client.listTreeEntities(levelsCount: 2)
for entity in page.items where entity.treeEntityType == .space {
  print(entity.title ?? "")
}
```

CLI: `kaiten list-tree-entities` with `--parent-entity-uid`, `--levels-count`,
`--offset`, `--limit`.

### Tree Entity Roles

| Method | Description |
|--------|-------------|
| `listTreeEntityRoles()` | List tree entity roles of the company |

Kaiten documents this endpoint as under active development, so its response
format is subject to change. The response nests per-entity permission objects
(menu root, spaces, documents, folders, story maps); card custom property
permissions arrive either as a blanket boolean or as an object keyed by custom
property id.

CLI: `list-tree-entity-roles`.

### Pagination

Most list endpoints accept `offset` and `limit` parameters and return a `Page<T>`:

```swift
let page = try await client.listCards(boardId: 42, offset: 0, limit: 20)
print(page.items)   // [Card] — the items in this page
print(page.hasMore) // true if more pages are available
```

To fetch the next page, increment `offset` by `limit` and repeat until `hasMore` is `false`.

#### Auto-pagination

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

### Filtering cards

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

### Creating and updating cards

#### CardCreateOptions

Create a card by providing a title and board ID. Set additional properties as needed:

```swift
var opts = CardCreateOptions(title: "Bug fix", boardId: 1)
opts.columnId = 42
opts.description = "Fix the login crash"
let card = try await client.createCard(opts)
```

#### CardUpdateOptions

Update specific fields on an existing card — only the properties you set are sent to the server:

```swift
var opts = CardUpdateOptions()
opts.title = "Updated Title"
opts.columnId = 42
let card = try await client.updateCard(id: 123, opts)
```

#### Batch update

`batchUpdateCards` updates every card matching the given criteria in one call. It runs in the
background and returns the job's UUID rather than the updated cards. Provide at least one
criteria parameter together with `attributes`, or `columnId` + `laneId` together with `orderBy`
to reposition cards inside a cell:

```swift
let job = try await client.batchUpdateCards(
  boardId: 1,
  condition: .onBoard,
  attributes: .init(asap: true)
)
print(job.id)  // UUID of the background job
```

The `orderBy` field and direction are exposed as Swift enums (`BatchUpdateOrderField`,
`SortDirection`), each with an `unknown(String)` case preserving values the documentation
does not list.

From the CLI, criteria are plain options and the nested payloads are JSON objects:

```bash
kaiten batch-update-cards --board-id 1 --condition 1 --attributes '{"asap": true}'
kaiten batch-update-cards --column-id 2 --lane-id 3 \
  --order-by '{"field_type": "title", "direction": "asc"}'
```

#### Custom properties

Both option types carry a `properties` payload for the workspace's custom fields. Keys are
`id_<property-id>`; a value is an array of value IDs for select properties, a number for numeric
ones, or `null` to clear the property. Resolve the IDs first with `listCustomProperties()` and
`listCustomPropertySelectValues(propertyId:)` — they differ per workspace.

From the CLI, `create-card` and `update-card` take the same payload as a JSON object:

```bash
kaiten update-card --id 123 --properties '{"id_299126": [106915]}'
```

The object is parsed and validated locally, so a malformed payload fails before any request is sent.

#### WIP limits

Columns and lanes carry a work-in-progress limit. `--wip-limit` sets the value and `--wip-limit-type`
selects what it counts — `1` for card count, `2` for card size:

```bash
kaiten update-column --board-id 42 --id 7 --wip-limit 5 --wip-limit-type 1
```

### SDK configuration

`KaitenClient` can read the same `~/.config/kaiten/config.json` file as the CLI. See [Authenticate](#authenticate).

Use `--config` to provide a custom config file path when needed.

### Error handling

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
/plugin marketplace add AllDmeat/kaiten
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
`https://github.com/AllDmeat/kaiten` and review the parsed plugins. Installed plugins are
updated from the same marketplace UI.

Cursor reads the skill from `agent/skills/`, so it gets the same guidance as the other two hosts.

### Gemini CLI

```bash
gemini extensions install https://github.com/AllDmeat/kaiten
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

- Running the CLI: no runtime dependencies. Release binaries support macOS 15+ on ARM and Linux on x86-64 or ARM.
- Building from source or using the library: Swift 6.2+.
- Using the library: iOS 18+ or macOS 15+.

## License

See [LICENSE](LICENSE) for details.
