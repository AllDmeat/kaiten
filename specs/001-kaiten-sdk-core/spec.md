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
- **FR-032**: SDK MUST expose private comment files: attach a file to a comment (`POST /cards/{card_uid}/comments/{comment_uid}/files`), get a signed URL for a comment file (`GET .../files/{id}`), and delete a comment file (`DELETE .../files/{id}`). All three routes require "Restricted file access" enabled in company settings and address every entity by string UID, so a 404 surfaces per the FR-021 rule. The docs declare the attach body as `multipart/form-data` without naming the form field; the spec mirrors the `file` part of the card attach endpoint. The `response_type` query values (`json`, `inline`, `attachment`) follow the FR-020a rule: plain `string` in the spec, a hand-written enum with an `unknown(String)` case in `Enums.swift`. The SDK requests the `json` disposition by default — the other two answer with a redirect to the file content, which the SDK cannot represent. Amended by FR-037: `response_type` is ignored by the live API and the GET returns file metadata, not just the URL.
- **FR-033**: SDK MUST expose iterations: card iterations history (`GET /cards/{card_uid}/iterations-history`), iteration CRUD in a space (`GET`/`POST /spaces/{space_uid}/iterations`, `GET`/`PATCH`/`DELETE /spaces/{space_uid}/iterations/{id}`), and iteration card records (`GET`/`POST /spaces/{space_uid}/iterations/{iteration_id}/cards`, `DELETE .../cards/{uid}`). The iterations API is documented as beta and addresses spaces, iterations and cards by string UIDs, so a 404 surfaces as `unexpectedResponse(404)` per the FR-021 rationale. The iteration `status` discriminator follows the FR-020a rule: plain `string` in the spec, a hand-written `IterationStatus` enum with an `unknown(String)` case in `Enums.swift`. The `committed` and `velocity` statistics inside `data` MUST stay free-form JSON objects — the documentation does not describe their fields, and reverse-engineering them from live responses is forbidden by FR-009. A card carries its iteration membership inline: `GET /cards/{id}` answers with an `iteration` array of records that merge the iteration's own identity (`id`, `space_uid`, `title`, `status`, `creator_uid`, `updater_uid`) with the card link (`card_uid`, `iteration_id`). The field is absent when the card belongs to no iteration, and the card list endpoint never returns it — not even with `additional_card_fields`. Neither shape matches `Iteration` or `IterationCard`, so per the FR-009 "different responses = different schemas" rule it is modelled as a separate `CardIteration` schema, every property optional. The card documentation does not mention the field at all, so it carries a `DOC_MISMATCH` annotation; each individual property is documented under the iterations endpoints, so the schema is typed rather than free-form. Its `status` follows the FR-020a rule, exposed through the same `IterationStatus` accessor as `Iteration`. `sprint_id` is a different, unrelated field: it belongs to the board-scoped sprints API and stays populated on cards that have no iteration.
- **FR-034**: SDK MUST expose private custom property files: attach a file to a card custom property (`POST /cards/{card_uid}/custom-properties/{property_uid}/files`), get a custom property file (`GET /cards/{card_uid}/custom-properties/{property_uid}/files/{id}`), and delete a custom property file (`DELETE /cards/{card_uid}/custom-properties/{property_uid}/files/{id}`). The GET method sends `response_type=json` by default and returns the signed URL; the documented 302 redirect (for `inline`/`attachment` response types) is not modelled because the transport follows redirects transparently. All three resources are addressed by string UIDs, so 404 handling follows FR-021. The `response_type` values follow the FR-020a rule: plain `string` in the spec, a hand-written enum with an `unknown(String)` case in `Enums.swift`. Amended by FR-037: `response_type` is ignored by the live API and the GET returns file metadata, not just the URL.
- **FR-037**: SDK MUST follow the current documentation of the restricted access file routes (card, comment and custom property files), amending FR-032 and FR-034.
  - **GET returns metadata.** `GET /cards/{card_uid}/files/{id}`, `GET /cards/{card_uid}/comments/{comment_uid}/files/{id}` and `GET /cards/{card_uid}/custom-properties/{property_uid}/files/{id}` return the file metadata (`id`, `name`, `size`, `mime_type`, `entity_type`, `created`, `updated`, `card_uid`, `comment_uid` / `custom_property_uid`, `author_uid`, `card_cover`) together with the signed `url`. The existing URL schemas (`PrivateCardFileUrlResponse`, `CommentFileSignedUrl`, `CustomPropertyFileUrl`) grow these fields, so the change is additive. Comment files also carry `kind`, which the documentation does not list (`DOC_MISMATCH`). `size` is `null | string`.
  - **Query parameters.** The documentation replaced `response_type` with two booleans: `redirect` (302 to the signed URL instead of JSON) and `download` (the signed URL serves the file as an attachment). Live, `response_type` is accepted and ignored. The spec keeps it with `deprecated: true` and a `DOC_MISMATCH` annotation, and lists `redirect` and `download`. The SDK exposes `download`. It does not expose `redirect`: the transport follows the 302 and the body becomes the file bytes, which the SDK cannot return as metadata. New methods (`getPrivateCardFile`, `getCommentFile` without `responseType`, `getCustomPropertyFile`) return the full metadata and never send `response_type`. The old methods (`getPrivateFile`, `getCommentFile(responseType:)`, `getCustomPropertyFileUrl`) and the three `*ResponseType` enums stay, deprecated.
  - **Update.** SDK MUST expose `PATCH` on the three file routes (`updatePrivateFile`, `updateCommentFile`, `updateCustomPropertyFile`). The body is `name` and `card_cover`, both optional; the response is the same metadata object as the attach route (`PrivateCardFile`, `CommentFile`, `CustomPropertyFile`), which carries `company_uid` and no `url`. The request body is verified against the documentation only.
  - **`comment_uid` accepts `new`.** The comment file routes document `comment_uid` as a UUID or the literal `new`, addressing a file uploaded to a comment that has not been created yet. The SDK passes the string through unchanged.
  - **Legacy files.** The restricted GET answers 404 for a file uploaded without restricted access (a `File` entry in `Card.files`), so the restricted routes do not replace the legacy ones for existing files. The documentation marks the legacy upload `PUT /cards/{card_id}/files` as deprecated (unavailable for companies created on or after 2026-05-21); the SDK marks `attachFile(cardId:fileData:filename:)` deprecated. `PATCH` and `DELETE /cards/{card_id}/files/{id}` are not deprecated in the documentation and remain the only way to manage legacy files, so they stay as they are. The `files[]` multipart upload on `POST`/`PATCH /cards/{card_id}/comments` is deprecated too (403 `public_api_legacy_file_upload_disabled` for companies created on or after 2026-05-21); the SDK never exposed it and MUST NOT add it.
  - **`PrivateFile`** (restricted entries in `Card.files`) gains `kind`, observed on comment files and absent from the documentation (`DOC_MISMATCH`).
- **FR-038**: SDK MUST expose the column, subcolumn and lane settings listed below on create and update (`default_tags`, documented on the updates, is outside this requirement). Columns and subcolumns (`POST /boards/{board_id}/columns`, `PATCH /boards/{board_id}/columns/{id}`, `POST /columns/{column_id}/subcolumns`, `PATCH /columns/{column_id}/subcolumns/{id}`) accept the stale-card warning (`last_moved_warning_after_days`, `_hours`, `_minutes`), `archive_after_days` (honoured only by `done` columns), `card_hide_after_days`, the `rules` bit mask (1 — checklists must be checked, 2 — display FIFO order) and `external_id`; the updates additionally accept `prev_column_id`/`next_column_id` for reordering and `pause_sla`. Lanes (`POST /boards/{board_id}/lanes`, `PATCH /boards/{board_id}/lanes/{id}`) accept the same stale-card warning. Subcolumns and columns share one request schema; the subcolumn wrappers send only what the subcolumn documentation lists, so `wip_limit` and `wip_limit_type` — documented for columns only, though subcolumn responses carry them — stay off `createSubcolumn`/`updateSubcolumn`. `external_id` is documented as `number | string | null`; the SDK takes a string, as for boards and spaces. On the updates, `card_hide_after_days`, `prev_column_id` and `next_column_id` are documented as nullable, where `null` turns card hiding off or moves the column to the beginning/end. They MUST support three states — absent (unchanged), `null`, and a value — through a `NullableInteger` schema overridden by a hand-written `ExplicitNullInteger`, the integer counterpart of `ExplicitNullNumber`; the public parameters are `Int??`, where `nil` leaves the field unchanged and `.some(nil)` sends `null`. The CLI follows the collective vote and score value commands: the matching options take an empty string `""` to send `null`. On create `card_hide_after_days` stays a plain integer, since there is nothing to clear. `wip_limit` on `PATCH /boards/{board_id}/columns/{id}` and `PATCH /boards/{board_id}/lanes/{id}` is documented as nullable too, where `null` removes the WIP limit. Its pre-existing `wipLimit: Int?` parameter and the generated `wip_limit: Int?` request property MUST keep their shape and meaning (`nil` leaves the limit unchanged), so `updateColumn` and `updateLane` add `clearWipLimit: Bool = false`: `true` sends `"wip_limit": null`, injected into the encoded body by a client middleware because the generated request type cannot encode `null`. Passing a `wipLimit` together with `clearWipLimit: true` MUST throw `KaitenError.conflictingArguments` before any request is sent. `updateSubcolumn` stays without `wip_limit`, as above. `months_to_hide_cards` is deprecated by the documentation in favour of `card_hide_after_days`: the `Column` response keeps it, marked `deprecated`, because the live API still returns it, and the SDK sends it on no request. `Column` also carries `subcolumns`, which the live API includes only on columns that have subcolumns. The documented `force` body attribute on `DELETE /boards/{board_id}/columns/{id}` and `DELETE /columns/{column_id}/subcolumns/{id}` removes the column with all related data; in the spirit of FR-011 the SDK MUST NOT expose it.
- **FR-039**: Space and board schemas MUST carry every attribute the documentation describes and every field the live API returns. `Space` gains `hidden_card_type_uids` (`array of string | null`); `allowed_card_type_ids`, which the documentation deprecates in favour of it, is marked `deprecated: true`. `settings` is nullable — the list page declares a non-nullable `object`, the live API usually returns `null`. Fields returned live but not documented carry a `DOC_MISMATCH` annotation: `work_calendar_id`, `author_uid`, `icon_color`, `icon_type`, `icon_value`, `import_uid`, `key`, `protected`, and — on the list only — `notifications_enabled`, `role` and `role_permissions`. `role` is an integer, as the API returns it. `role_permissions` and space `settings` stay free-form JSON objects (FR-009 forbids reverse-engineering nested shapes the documentation does not describe). `users` on the `POST /spaces` response is documented but cannot be verified without a mutation, so it is an optional array of free-form objects. `Board`, `SpaceBoard` and `BoardInSpace` declare `description` as `string | null` (the read endpoints document it so, and the live API returns `null`); `Board` additionally carries `top`, `left` and `sort_order` (documented on the create and update responses, absent from `GET /boards/{id}`), the documented `cards_deprecation_message`, and the live-only `uid`, `import_uid`, `locked` and `settings`; `SpaceBoard` gains `cards_deprecation_message`; `BoardInSpace` gains the live-only `space_id`, `board_id`, `uid`, `import_uid`, `locked`, `primary_path` and `settings`. Columns embedded in a board may carry `policies`, an array of free-form objects. Request bodies follow the documentation only, since mutations are never run against the live API: `createSpace` accepts `work_calendar_id`; `updateSpace` accepts `hidden_card_type_uids` and `settings`; `createBoard` accepts `top`, `left`, `columns` and `lanes` (whose items are dedicated `CreateBoardColumnRequest` / `CreateBoardLaneRequest` schemas built from the create-board page, not the column and lane endpoint schemas, so changes to those endpoints do not leak into board creation; the API rejects an empty array, which the SDK documents rather than validates); `updateBoard` accepts `top`, `left`, `type` (integer: `1` placed on the space by coordinates, `5` attached as a sidebar), `cell_wip_limits`, `move_parents_to_done`, `hide_done_policies`, `hide_done_policies_in_done_column`, `move_from_space_id` and `card_properties`. The documentation declares `cell_wip_limits` as an array, while every live response returns an object with a `limits` array: the three response fields carry a `DOC_MISMATCH`, and the request attribute stays untyped JSON, since its accepted shape cannot be verified without a mutation. `top`, `left` and `sort_order` are `null` for boards attached to a space as a sidebar, so they are nullable on `Board`, `SpaceBoard` and `BoardInSpace`.
- **FR-041**: SDK MUST expose every documented `GET /users` filter: besides `type`, `query`, `ids`, `limit`, `offset` and `include_inactive`, the list accepts `access_type_permissions` (`member` drops guests before pagination; `guest` applies to the `all` and `domain` types), `exclude_members_by_entity_uid` (drops direct, group and inherited members of an entity) and `exclude_directly_added_members_by_entity_uid` (drops users invited to the entity directly); all three were confirmed live to change the result. `access_type_permissions` stays a plain `String`, like the sibling `type` filter and the same filter on `GET /company/users`. `include_inactive` is documented as a response field as well, but the live API never returns it — it is a query flag only and is not part of the response model. The `User` schema MUST carry every field the list and current-user responses return. `GET /users/current` returns a superset of a list row (`telegram_id`, `telegram_settings`, `has_password`, and live-only `directory_synced_profile_fields`, `max_messenger_id`, `max_messenger_settings`); it is not split into a separate schema, because `getCurrentUser()` already returns `User` and the public API is changed only additively — the current-only fields are optional and absent from list rows. Personal settings (notification, messenger, email, work-time and personal settings, named permissions) are included: they are part of the documented response, and a model that drops them is incomplete per FR-008. `email_frequency` and `apps_permissions` are integers live, although the documentation declares an enum and a string, and are modelled as integers with `DOC_MISMATCH`. `email_settings` and `work_time_settings` reuse the `UserEmailSettings` and `UserWorkTimeSettings` schemas the update-user documentation describes. `notification_settings` stays a free-form JSON object even though the list documentation names its keys: the documented key list misspells one key and lacks about half of those the live API returns, so a typed model would silently drop most of the settings. Every other nested settings object (`slack_settings`, `telegram_settings`, `personal_settings`, `chat_settings`, `max_messenger_settings`, `named_permissions`, `own_named_permissions`, `beta_features` items) stays free-form — the documentation does not describe their fields, and reverse-engineering them from live responses is forbidden by FR-009.
- **FR-035**: Since 2026-10-01 Kaiten caps list responses at 100 items when no page size is given. Every list endpoint so capped MUST declare its documented pagination parameters, and its SDK method MUST expose them as optional parameters without changing the return type, enforcing the documented caps locally per FR-014:
  - `GET /spaces`, `GET /cards/{card_id}/comments`, `GET /cards/{card_id}/children`, `GET /cards/{card_id}/time-logs`, `GET /groups/{group_uid}/users` and `GET /cards/{card_id}/allowed-users`: `limit` (1–100) and `offset` (≥ 0).
  - `GET /spaces/{space_id}/users`: `limit` (1–500) and the `last_user_id` cursor. The live API ignores `offset` on this endpoint, and the documentation does not list it, so it MUST NOT be exposed. The cursor is the greatest user id of the previous page, not the last element: the default list is not ordered by id. The live API often returns pages shorter than `limit` while more users remain, so a short page MUST NOT be read as the end; the `limit` parameter carries a `DOC_MISMATCH` annotation saying so. The set of users a cursor walk returns can also differ with the page size — an API defect the SDK cannot correct, recorded in the same annotation.
  - Each of these endpoints MUST have an auto-pagination helper (`allSpaces`, `allCardComments`, `allCardChildren`, `allCardTimeLogs`, `allGroupUsers`, `allCardAllowedUsers`, `allSpaceUsers`). The space-users helper advances by the cursor, never by offset, and stops only on an empty page or when the cursor stops growing.
  - The allowed-users `DOC_MISMATCH` annotations recorded before the cut-over are stale for `limit` and `offset` (both honoured) and are removed; `orderBy` stays annotated because the list is always ordered by id whatever value is passed, and `search` stays annotated because it still has no observed effect.
  - `include_values` on `GET /company/custom-properties` is rejected with HTTP 400 by the public API when `true`. It is marked `deprecated: true` in the spec, and the SDK keeps the parameter only on `@available(*, deprecated)` overloads of `listCustomProperties` and `allCustomProperties`, alongside overloads that omit it.
- **FR-042**: SDK MUST close the remaining gaps between the documentation and the spec:
  - **Card iterations history details.** `GET /cards/{card_uid}/iterations-history` accepts `with_details`. With `true` the API excludes removed iterations and adds `iteration` (`id`, `is_accessible`, and `title`/`space_uid` only when the caller can read the iteration's space), `addedBy` and `removedBy` (omitted, not `null`, when the user is unknown). These three are optional properties of `IterationCard` rather than a separate schema: the rows are otherwise identical, and a separate schema would change the return type of `getCardIterationsHistory`. The SDK exposes `withDetails`; omitted, the parameter is not sent. `IterationCard` also gains `card_id` (documented for the iteration cards list) and the live-only `source` and `board_uid` (`DOC_MISMATCH`; `board_uid` was observed only as `null`).
  - **Embedded user.** `addedBy`, `removedBy` and the comment `author` share one `UserSummary` schema, the user object the iterations documentation lists field by field. It is not `User`, which models the full users list row.
  - **Comments.** `Comment` gains `author` and the undocumented `meta`, which was observed only as `null` and stays a free-form object (`DOC_MISMATCH`). `email_addresses_to` is `null | string`: the documentation declares a string, and the live API returned `null` on every comment checked. The documented `attacments` of the create and update responses is not returned by the live API under either spelling and is not modelled.
  - **Card children.** `GET` and `POST /cards/{card_id}/children` return a card, not the link record `CardChild` modelled. `CardChild` keeps its name and existing properties and gains the card fields the documentation and the live API return, reusing the nested schemas of `Card`, so `listCardChildren` and `addCardChild` keep their return types. Every property stays optional: the live API answers with a reduced row (identity, owner, type, board, lane, column, members, tags) for some children. `CardChild` is not replaced by `Card`, because `Card` does not carry the link fields `card_id` and `depends_on_card_id` and the change would not be source-compatible.
  - **Request attributes.** `createChecklist` accepts `itemsSourceChecklistId`, `excludeItemIds` and `sourceShareId`; `createCustomProperty` accepts `directoryId` (required by the API for `type=directory`, which `CustomPropertyType` gains), `formula` and `formulaSourceCard` (a free-form object); `updateCustomDirectory` accepts `expectedFieldIds`, checked only together with `fields`, and a mismatch answers HTTP 409 (code 16), which surfaces as `unexpectedResponse(statusCode: 409)` — the documentation defines no body for it; `updateCardBlocker` accepts `dueDate` (three-state through `NullableString`: absent, `null` to clear, or a value) and `dueDateTimePresent`. The documentation allows `null` for `due_date_time_present` too; the SDK sends only a boolean, since `false` and `null` both drop the time. Request attributes are verified against the documentation only.
  - **Response fields.** `Checklist` gains `deleted`, documented for the create response. `CustomProperty` gains the live-only `directory_id` (observed only as `null`) and `fts_version`; these and the previously unannotated `import_uid`, `is_used_as_progress` and `calculation_method` carry `DOC_MISMATCH`. `records_count` on custom directories is documented by the list endpoint and needs no annotation. `reverse_field_id` on custom directory fields appears only in the documentation's response examples and could not be checked live (the company has no directories); it stays, annotated.

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

**Independent Test**: Call `client.listCustomPropertySelectValues(propertyId: 56)`, receive an array of select values.

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
