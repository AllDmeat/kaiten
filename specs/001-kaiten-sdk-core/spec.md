# Feature Specification: Kaiten SDK Core

**Feature Branch**: `001-kaiten-sdk-core`
**Created**: 2026-02-14
**Status**: Draft
**Input**: A Swift library for working with the Kaiten API. Fetching cards, boards, fields (assignees, teams, platforms). Will be used as a dependency in the MCP server.

## User Scenarios & Testing

### User Story 1 — Get a Card by ID (Priority: P1)

A developer (or MCP server) requests card details by its ID. Receives all fields: title, description, status, assignees, custom properties (team, platform).

**Why this priority**: This is the fundamental operation — nothing works without it.

**Independent Test**: Call `client.getCard(id: 123)`, receive a `Card` struct with all fields.

**Acceptance Scenarios**:

1. **Given** a valid token and card ID, **When** I call `getCard(id:)`, **Then** I receive a `Card` with all fields including custom properties
2. **Given** an invalid ID, **When** I call `getCard(id:)`, **Then** I receive a typed error (no crash)
3. **Given** an invalid token, **When** I call `getCard(id:)`, **Then** I receive an authorization error

---

### User Story 2 — Get a List of Cards on a Board (Priority: P1)

A developer requests all cards for a specific board. Receives a list with basic fields + assignees.

**Why this priority**: Needed for board overview — who is working on what, what status things are in.

**Independent Test**: Call `client.listCards(boardId: 456)`, receive an array `[Card]`.

**Acceptance Scenarios**:

1. **Given** a valid board ID, **When** I call `listCards(boardId:)`, **Then** I receive an array of cards with fields
2. **Given** a board with no cards, **When** I call `listCards(boardId:)`, **Then** I receive an empty array
3. **Given** an invalid board ID, **When** I call `listCards(boardId:)`, **Then** I receive a typed error

---

### User Story 3 — Get Members and Custom Properties of a Card (Priority: P1)

A developer retrieves information about who is assigned to a card (members), which team it belongs to, and which platform it's on (via custom properties).

**Why this priority**: Key for planning — understanding people and team workload.

**Independent Test**: From a fetched `Card`, read `members`, `customProperties` and get typed values.

**Acceptance Scenarios**:

1. **Given** a card with members, **When** I read `card.members`, **Then** I receive an array `[Member]` with `userId`, `fullName`, `role`
2. **Given** a card with custom properties, **When** I read `card.customProperties`, **Then** I receive a dictionary with typed values
3. **Given** a card without members, **When** I read `card.members`, **Then** I receive an empty array

---

### User Story 4 — Get Board Structure (Priority: P2)

A developer requests a board with its columns and lanes — to understand which column each card is in.

**Why this priority**: Needed for visualization and understanding the flow, but does not block core work.

**Independent Test**: Call `client.getBoard(id:)`, receive a `Board` with `columns` and `lanes`.

**Acceptance Scenarios**:

1. **Given** a valid board ID, **When** I call `getBoard(id:)`, **Then** I receive a `Board` with `columns` and `lanes` arrays

---

### User Story 5 — Get List of Spaces and Boards (Priority: P2)

A developer requests all spaces and boards — for navigation.

**Why this priority**: Auxiliary navigation, not critical for the first version.

**Independent Test**: Call `client.listSpaces()`, then `client.listBoards(spaceId:)`.

**Acceptance Scenarios**:

1. **Given** a valid token, **When** I call `listSpaces()`, **Then** I receive an array `[Space]`
2. **Given** a valid space ID, **When** I call `listBoards(spaceId:)`, **Then** I receive an array `[Board]`

### Edge Cases

- What happens on a network error (timeout, DNS)? → typed error, no crash
- What if the API returns unknown fields? → they are ignored (forward compatibility)
- What if the API returns 429 (rate limit)? → automatic retry with delay via `Task.retrying`
- What if a request is cancelled by caller task? → cancellation MUST propagate as cancellation; it MUST NOT be converted to a network error
- What if a custom property has an unknown type? → stored as raw value
- What if `baseURL` uses a non-HTTPS scheme? → initialization MUST fail with a typed error
- What if `baseURL` is HTTPS but has no host (or is otherwise non-absolute)? → initialization MUST fail with a typed error
- What if list endpoints return HTTP 200 with malformed/partial payloads? → MUST throw a typed decoding/network error, MUST NOT silently return an empty list
- What if pagination inputs are invalid (`offset < 0`, `limit <= 0`, or above API max)? → MUST fail fast with a typed validation error
- What if retry headers request very large waits? → retry delay MUST be bounded; long waits MUST be surfaced to caller via typed rate-limit error
- What if an endpoint returns HTTP 400 (bad request)? → SDK MUST surface a dedicated typed client-side validation/request error, not a generic unexpected-response error
- What if auto-pagination receives a short page before completion? → pagination progression MUST use server/page semantics and MUST NOT assume `offset += requestedLimit`

## Requirements

### Functional Requirements

- **FR-001**: SDK MUST generate client code from the OpenAPI spec via `swift-openapi-generator`
- **FR-002**: SDK MUST support authorization via Bearer token
- **FR-003**: SDK MUST provide typed models for Card, Board, Column, Lane, Space, Member, CustomProperty
- **FR-004**: SDK MUST return typed errors for all failure cases (network, auth, not found, rate limit). All public methods MUST use typed throws (`throws(KaitenError)`) instead of untyped `throws`.
- **FR-005**: SDK MUST accept `baseURL` and `token` as
  explicit initialization parameters. The SDK does not read
  configuration on its own — that is the caller's responsibility.
- **FR-006**: SDK MUST throw an error on initialization
  (fail fast) if `baseURL` is invalid.
- **FR-007**: SDK MUST support async/await
- **FR-008**: The OpenAPI spec MUST contain only endpoints (`paths`) that are actually used in the SDK. The `components/schemas` section MUST contain all data models needed to fully describe responses of these endpoints — including nested objects (User, Checklist, SLA, etc.), even if the SDK has no special business logic for them. Since Kaiten does not yet have an official OpenAPI spec, we maintain a minimal hand-crafted spec — only used endpoints + complete models of their responses. When Kaiten provides an official spec, we can switch to it entirely.
- **FR-009**: The OpenAPI spec is assembled **manually** — Kaiten does not have a public OpenAPI specification. The spec MUST accurately reflect real API behavior:
  - **Kaiten documentation is the starting point**, but not absolute truth. Docs may diverge from the real API.
  - **When docs diverge from API — the real API takes priority.** Verify fields, types, nullable/required through real requests. Example: docs show a full Board for Card.board, but the API returns only 6 fields → the spec uses a separate CardBoardSummary schema.
  - **Divergences MUST be documented** with a YAML comment directly above the field/schema (e.g. `# NOTE: Kaiten docs show X, but API returns Y`).
  - **Different responses = different schemas** — if two endpoints return similar but not identical data, the spec MUST have separate schemas (Board vs BoardInSpace vs CardBoardSummary).
  - **One field holding several shapes = `anyOf` over separate schemas, plus a free-form fallback branch.** A single collection may carry structurally different objects (Card.files holds legacy attachments keyed by an integer `id` and private files keyed by a UUID string). Model each shape as its own schema and combine them with `anyOf`; discriminators are unusable when the deciding field is not a string. The trailing `type: object` branch MUST be present so a shape Kaiten adds later degrades to raw JSON instead of failing the whole response — modelling an open set as closed is what broke `getCard` on every card with a private file.
  - **Nullable and required strictly per the real API** — verify through requests, not just docs.
  - **Cross-checking is mandatory** — for any spec change, compare with documentation + verify against the real API. Documentation parsing guide: [docs/kaiten-docs-parsing.md](../../docs/kaiten-docs-parsing.md).
- **FR-010**: SDK MUST support ALL query parameters documented in the Kaiten API for every endpoint in the spec. No subset, no phasing — every filter the API accepts MUST be present in the OpenAPI spec and exposed in the SDK's public API with backward-compatible optional defaults.
- **FR-011**: SDK MUST NOT expose destructive delete operations for spaces, boards, and lanes.
- **FR-012**: SDK MUST enforce secure transport for API authentication. `baseURL` MUST use `https`; non-HTTPS URLs MUST fail during initialization with a typed error.
- **FR-013**: SDK list methods MUST NOT convert unexpected successful-response parsing failures into empty results. Empty list fallback is allowed only for explicitly confirmed empty response bodies.
- **FR-014**: SDK MUST validate pagination inputs for list methods. Invalid values (`offset < 0`, `limit <= 0`, or values above documented endpoint caps) MUST fail fast with typed validation errors.
- **FR-015**: SDK async APIs MUST preserve cooperative cancellation semantics. If the caller task is cancelled, the SDK MUST propagate cancellation and MUST NOT remap it into `.networkError`.
- **FR-016**: SDK auto-pagination helpers MUST advance offsets using page semantics from returned data (server-provided next position when available, otherwise `offset + page.items.count`). Fixed-step advancement by requested page size is forbidden.
- **FR-017**: SDK initialization MUST validate that `baseURL` is an absolute HTTPS URL with a non-empty host component.
- **FR-018**: SDK response mapping MUST preserve documented client error classes. HTTP 400 responses MUST map to a dedicated typed error case and MUST NOT be downgraded to generic unexpected/undocumented errors.
- **FR-019**: SDK methods exposing `limit`/`offset` for users, card types, and sprints MUST enforce documented endpoint caps locally with typed validation errors before network calls.
- **FR-020**: SDK MUST expose space automations (list, create, update, delete). Nested `data` payloads of triggers and actions MUST stay free-form JSON objects — the documentation does not describe those fields, and reverse-engineering them from live responses is forbidden by FR-009.
- **FR-020a**: Automation discriminators (`type`, `status`, `clause`) MUST be declared as plain `string` in the OpenAPI spec, not as closed enums. Kaiten returns values its documentation does not list (confirmed live: action type `change_type`), and a generated closed enum fails the entire response instead of the single field. The typed surface MUST instead be hand-written enums in `Enums.swift` with an `unknown(String)` case, per the forward-compatibility rule those enums already follow.
- **FR-021**: For resources addressed by a string UID rather than an integer id (currently automations and documents), a HTTP 404 MUST surface as `unexpectedResponse(statusCode: 404)`. `notFound(resource:id:)` carries an `Int` id and MUST NOT be populated with an unrelated identifier (for example the parent space id) to fake specificity.
- **FR-022**: Endpoints documented as returning HTTP 200 with no response body (currently `delete_automation`) MUST map to a `Void`-returning SDK method. The SDK MUST NOT invent a response payload for them.
- **FR-023**: SDK MUST expose card blocker categories: list company categories (`GET /categories`), add a category to a blocker (`POST /blockers/{blocker_id}/categories`), and remove a category from a blocker (`DELETE /blockers/{blocker_id}/categories/{category_uuid}`). Removal returns only the removed category UID, per documentation.
- **FR-024**: SDK MUST expose batch card updates (`PATCH /cards`). The endpoint answers HTTP 202 with only the UUID of a background job, so the SDK returns that job payload and MUST NOT pretend to return updated cards. A 404 surfaces as `unexpectedResponse(404)` per the FR-021 rationale — cards are selected by criteria, and no single integer id identifies what was missing. The `order_by` discriminators (`field_type`, `direction`) follow the FR-020a rule: plain `string` in the spec, hand-written enums with an `unknown(String)` case in `Enums.swift`.
- **FR-025**: SDK MUST expose card blocker users: list users on a blocker (`GET /blockers/{blocker_id}/users`), add a user (`POST /blockers/{blocker_id}/users`), remove a user (`DELETE /blockers/{blocker_id}/users/{user_id}`), and the current-user blockers list (`GET /users/current/blockers`). The current-user blockers endpoint is documented as returning an object, but a live instance answers with an empty JSON array when the user has no blockers; the spec MUST model both shapes (`anyOf`) and the SDK MUST map the array shape to an empty result rather than a decoding error.
- **FR-026**: SDK MUST expose custom directory fields (list, create, get, update, delete under `/company/custom-directories/{directory_id}/fields`). The documentation marks the custom directories API as beta, so its discriminators (`type`, `condition`) MUST follow FR-020a: plain `string` in the OpenAPI spec, typed via hand-written enums with an `unknown(String)` case (`CustomDirectoryFieldType`, `CustomDirectoryCondition`). Directories and fields are addressed by string UUIDs, so a HTTP 404 MUST surface per FR-021. Deletion is a soft delete that returns the removed field with `condition: removed`, per documentation. The nested `linkedDirectory` and `customProperty` objects MUST stay free-form JSON — the documentation does not describe their shape, and reverse-engineering them from live responses is forbidden by FR-009.
- **FR-027**: SDK MUST expose company group entities (list, add, update, remove) under `/company/groups/{group_uid}/entities`. The `entity_type` discriminator MUST follow the FR-020a pattern (plain `string` in the spec, hand-written `GroupEntityType` enum with an `unknown(String)` case). The `role_permissions` payload MUST stay a free-form JSON object — the documentation does not describe its nested permission objects, and reverse-engineering them from live responses is forbidden by FR-009. Groups are addressed by string UID, so a 404 follows FR-021.
- **FR-028**: SDK MUST expose custom property collective score values on a card: list (`GET /cards/{card_id}/custom-properties/{property_id}/collective-score-values`), create (`POST` to the same path), and update (`PATCH .../collective-score-values/{id}`). The update body's `value` field distinguishes an explicit `null` (clear the value) from an absent field (leave unchanged), so it MUST use the three-state `NullableString` pattern.
- **FR-029**: SDK MUST expose card collective vote values for vote-type custom properties (list, create, update, delete under `/cards/{card_id}/custom-properties/{property_id}/collective-vote-values`). A scale or rating property carries `number_vote`, an emoji-set property carries `emoji_vote`; the documentation's own response examples return `null` for whichever of the two the vote does not use, so both MUST be nullable. Updating documents `number_vote: null` as a valid value that clears the vote, so the update method MUST support sending an explicit JSON `null` (three-state encoding, like `NullableString`).
- **FR-030**: SDK MUST expose documents (list, search, retrieve, create, update, remove). `GET /documents` answers in two shapes depending on the `version` query parameter — a plain array by default, a `result`/`position` cursor object with `version=2` — so the spec models the 200 response as `anyOf` over both shapes and the SDK exposes them as two methods (`listDocuments`, `searchDocuments`). Document `access` and `icon_type` discriminators follow FR-020a (plain strings in the spec, hand-written enums with `unknown(String)`). A document's `data` is returned by the live API as a JSON-encoded string although the documentation declares an object; the spec accepts both shapes via `anyOf`, as it does for `id`, which the documentation declares as an integer while the live API returns the uid string. Documents are addressed by string UID, so 404 handling follows FR-021.
- **FR-031**: SDK MUST expose the space-scoped board read (`GET /spaces/{space_id}/boards/{id}`). The response differs from `GET /boards/{id}`: it carries the board's placement on the space (`top`, `left`, `sort_order`, `space_id`), so per the FR-009 "different responses = different schemas" rule it is modelled as a separate `SpaceBoard` schema. The documentation declares the response as an array of objects; the live API returns a single object, and the spec follows the live shape with a `DOC_MISMATCH` annotation.
- **FR-032**: SDK MUST expose private comment files: attach a file to a comment (`POST /cards/{card_uid}/comments/{comment_uid}/files`), get a signed URL for a comment file (`GET .../files/{id}`), and delete a comment file (`DELETE .../files/{id}`). All three routes require "Restricted file access" enabled in company settings and address every entity by string UID, so a 404 surfaces per the FR-021 rule. The docs declare the attach body as `multipart/form-data` without naming the form field; the spec mirrors the `file` part of the card attach endpoint. The `response_type` query values (`json`, `inline`, `attachment`) follow the FR-020a rule: plain `string` in the spec, a hand-written enum with an `unknown(String)` case in `Enums.swift`. The SDK requests the `json` disposition by default — the other two answer with a redirect to the file content, which the SDK cannot represent.
- **FR-033**: SDK MUST expose iterations: card iterations history (`GET /cards/{card_uid}/iterations-history`), iteration CRUD in a space (`GET`/`POST /spaces/{space_uid}/iterations`, `GET`/`PATCH`/`DELETE /spaces/{space_uid}/iterations/{id}`), and iteration card records (`GET`/`POST /spaces/{space_uid}/iterations/{iteration_id}/cards`, `DELETE .../cards/{uid}`). The iterations API is documented as beta and addresses spaces, iterations and cards by string UIDs, so a 404 surfaces as `unexpectedResponse(404)` per the FR-021 rationale. The iteration `status` discriminator follows the FR-020a rule: plain `string` in the spec, a hand-written `IterationStatus` enum with an `unknown(String)` case in `Enums.swift`. The `committed` and `velocity` statistics inside `data` MUST stay free-form JSON objects — the documentation does not describe their fields, and reverse-engineering them from live responses is forbidden by FR-009.
- **FR-034**: SDK MUST expose private custom property files: attach a file to a card custom property (`POST /cards/{card_uid}/custom-properties/{property_uid}/files`), get a custom property file (`GET /cards/{card_uid}/custom-properties/{property_uid}/files/{id}`), and delete a custom property file (`DELETE /cards/{card_uid}/custom-properties/{property_uid}/files/{id}`). The GET method sends `response_type=json` by default and returns the signed URL; the documented 302 redirect (for `inline`/`attachment` response types) is not modelled because the transport follows redirects transparently. All three resources are addressed by string UIDs, so 404 handling follows FR-021. The `response_type` values follow the FR-020a rule: plain `string` in the spec, a hand-written enum with an `unknown(String)` case in `Enums.swift`.

### Non-Functional Requirements

- **NFR-001**: SDK MUST compile on macOS (ARM) and Linux (x86-64 and ARM)
- **NFR-002**: SDK MUST use `swift-tools-version: 6.2` with `.swiftLanguageMode(.v6)` on each target
- **NFR-003**: SDK MUST automatically retry requests on 429 (rate limit) with a delay (configurable max retries and delay). Implementation via `ClientMiddleware`.
- **NFR-004**: GitHub Actions workflows MUST have explicit names describing what they do (e.g. `build-and-test.yml`, not `ci.yml`)
- **NFR-005**: CI MUST cache SPM dependencies between runs to speed up builds
- **NFR-006**: Code MUST NOT use `nonisolated(unsafe)`. For mutable state in a Sendable context, use `Mutex` from `import Synchronization`
- **NFR-007**: All public types (structs, enums, protocols) and methods MUST have Swift doc comments (`///`) following DocC conventions. Doc comments MUST include `- Parameter`, `- Returns`, and `- Throws` tags where applicable.
- **NFR-008**: SDK source files MUST be grouped by Kaiten API documentation domains (for example: cards, boards, spaces, users) to keep endpoint parity checks maintainable.
- **NFR-009**: Retry behavior for rate limiting MUST use a bounded delay policy. Header-derived delays (for example `Retry-After` and `X-RateLimit-Reset`) MUST be clamped to a configurable upper bound to avoid unbounded blocking.

### Key Entities

- **Card**: id, title, description, state, column, members, customProperties, tags, created, updated
- **Board**: id, title, columns, lanes
- **Column**: id, title, sortOrder, subcolumns
- **Lane**: id, title, sortOrder
- **Space**: id, title (boards fetched separately via `listBoards(spaceId:)`)
- **Member**: id, userId, fullName, role
- **CustomProperty**: id, name, type, value (typed: string, number, select, multiselect, date, user)
- **CustomPropertySelectValue**: id, customPropertyId, value, color, condition (`active` / `inactive`), sortOrder, externalId, updated, created, authorId, companyId; live responses also carry uid and deleted (undocumented)
- **Automation**: id (string UID), name, type (`on_action` / `on_date` / `on_demand`), status (`active` / `disabled` / `removed` / `broken`), spaceUid, sortOrder, updaterId, trigger, actions, conditions
- **BlockerCategory**: uid (string UID), name, color; live responses also carry companyUid, created and count (undocumented)
- **CollectiveScoreValue**: id, value, customPropertyId, cardId, authorId; POST/PATCH responses also carry created, updated, updaterId and companyId, while GET list items instead carry an `author` object whose shape the documentation does not describe
- **CollectiveVoteValue**: id, customPropertyId, numberVote (nullable), emojiVote (nullable), cardId, authorId; create/update/remove responses also document companyId, created and updated, the list response documents the embedded author (User)

### User Story 7a — Manage Custom Property Select Values (Priority: P2)

A developer retrieves, creates, updates and removes the available select options for a select-type custom property, to populate dropdowns or validate user input.

**Why this priority**: Select values are needed for setting custom properties on cards — a key automation scenario.

**Independent Test**: Call `client.listCustomPropertySelectValues(propertyId: 299126)`, receive an array of select values.

**Acceptance Scenarios**:

1. **Given** a valid property ID of a select-type custom property, **When** I call `listCustomPropertySelectValues(propertyId:)`, **Then** I receive an array of `CustomPropertySelectValue` objects
2. **Given** a valid property ID and value ID, **When** I call `getCustomPropertySelectValue(propertyId:id:)`, **Then** I receive a single `CustomPropertySelectValue`
3. **Given** an invalid property ID, **When** I call `listCustomPropertySelectValues(propertyId:)`, **Then** I receive a `notFound` error
4. **Given** an invalid value ID, **When** I call `getCustomPropertySelectValue(propertyId:id:)`, **Then** I receive a `notFound` error
5. **Given** a valid property ID and value text, **When** I call `createCustomPropertySelectValue(propertyId:value:color:)`, **Then** I receive the created `CustomPropertySelectValue`
6. **Given** a valid property ID and value ID, **When** I call `updateCustomPropertySelectValue(propertyId:id:value:color:condition:sortOrder:deleted:)`, **Then** I receive the updated `CustomPropertySelectValue`
7. **Given** a valid property ID and value ID, **When** I call `removeCustomPropertySelectValue(propertyId:id:)`, **Then** I receive the removed `CustomPropertySelectValue` — the endpoint returns the removed value
8. The select value `condition` discriminator is declared as plain `string` in the OpenAPI spec per FR-020a; the typed surface is the `CustomPropertySelectValueCondition` enum in `Enums.swift` with an `unknown(String)` case

### User Story 7 — Create a Comment on a Card (Priority: P2)

A developer creates a new comment on a card with markdown text.

**Why this priority**: Write operations extend the SDK beyond read-only use, enabling automation workflows.

**Independent Test**: Call `client.createComment(cardId: 123, text: "Hello")`, receive a `Comment` with the created fields.

**Acceptance Scenarios**:

1. **Given** a valid card ID and text, **When** I call `createComment(cardId:text:)`, **Then** I receive a `Comment` with the created text
2. **Given** an invalid card ID, **When** I call `createComment(cardId:text:)`, **Then** I receive a `notFound` error
3. **Given** an invalid token, **When** I call `createComment(cardId:text:)`, **Then** I receive an `unauthorized` error

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: The MCP server can fetch all board cards with assignees and custom properties in a single SDK call
- **SC-002**: SDK compiles without errors on macOS (ARM) and Linux (x86-64 and ARM) in CI
- **SC-003**: All P1 user stories are covered by tests
- **SC-004**: Adding a new endpoint = adding it to the OpenAPI spec (code is regenerated automatically)
- **SC-005**: Cancellation-focused tests confirm cancelled operations are reported as cancellation, not network errors
- **SC-006**: Auto-pagination tests confirm no item loss/duplication when a page contains fewer than requested items
