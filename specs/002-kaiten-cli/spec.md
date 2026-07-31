# Feature Specification: Kaiten CLI

**Feature Branch**: `002-kaiten-cli`
**Created**: 2026-02-16
**Status**: Draft
**Input**: User description: "An executable target — a thin wrapper over the SDK with no logic, forwards commands to the SDK"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - CLI Access to Kaiten (Priority: P1)

A DevOps engineer or developer uses the CLI to access Kaiten data
without writing code. The CLI is a thin wrapper over the SDK — it
parses the `--config` argument and the config file, assembles a unified set
of parameters, and passes them to the SDK. No business logic.

**Why this priority**: The sole purpose of this feature is to
provide CLI access to the SDK.

**Independent Test**: Run the binary with `--config`
and a subcommand (e.g. `list-spaces`). Structured output in
stdout confirms it works.

**Acceptance Scenarios**:

1. **Given** a valid `--config` file path, **When** the
   user runs a subcommand (e.g. `list-spaces`), **Then** the
   CLI outputs structured data to stdout.
2. **Given** a valid config file exists at
   `~/.config/kaiten/config.json`, **When** the user runs
   a subcommand without `--config`, **Then** the CLI reads parameters
   from the config file.
3. **Given** both default and custom config files exist with different values,
   **When** the user specifies `--config`, **Then** the specified config path
   takes priority over the default config path.
4. **Given** neither selected config file nor default config file provide a required
   parameter, **When** the user runs a subcommand, **Then** the
   CLI exits with a clear error message indicating which parameter
   is missing and where it can be set (config file).
5. **Given** the SDK returns an error, **When** the user runs a
   subcommand, **Then** the CLI outputs a human-readable error
   message to stderr and exits with a non-zero exit code.
6. **Given** invalid CLI filter or pagination input (for example,
    unknown enum value, malformed CSV IDs, or invalid `offset/limit`),
   **When** the user runs a subcommand, **Then** the CLI fails fast
   with a clear validation error and MUST NOT silently drop invalid values.
7. **Given** a command option mapped to an SDK enum (for example card
   `position`, `condition`, `textFormatTypeId`), **When** the user passes
   an unknown raw value, **Then** the CLI MUST fail with a validation
   error and MUST NOT coerce it to `nil`.
8. **Given** CLI help text lists allowed enum values, **When** a user
   passes any value shown in help, **Then** validation MUST accept it;
   help text and parser-accepted values MUST stay in sync.

---

### Edge Cases

- What if the CLI is run without a subcommand? The CLI MUST print
  help and exit with a non-zero code.
- What if the config file exists but contains invalid JSON? The CLI
  MUST output an error describing the configuration problem.
- What if the config file does not exist and no `--config` is passed?
  The CLI MUST output an error with instructions: pass `--config` or
  create `~/.config/kaiten/config.json`.
- What if enum-like options are invalid (for example lane condition,
  column type, card state)? The CLI MUST fail with a validation error
  listing allowed values.
- What if comma-separated IDs/conditions contain invalid tokens?
  The CLI MUST fail and identify the invalid token; partial parsing
  is not allowed.
- What if pagination is invalid (`offset < 0`, `limit <= 0`,
  or above endpoint max)? The CLI MUST fail locally before calling SDK.
- What if a command exposes a parameter supported by the SDK (for example lane `rowCount`)?
  The CLI MUST forward the value to the SDK method and MUST NOT ignore it.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The CLI MUST be a thin wrapper over the SDK with no
  business logic of its own. The CLI parses the `--config` argument and the
  config file, assembles a unified Input, and passes it to the SDK.
- **FR-002**: The CLI MUST provide a subcommand for each SDK
  convenience method with corresponding arguments.
- **FR-002a**: The CLI MUST support a `--config` argument that points
  to the configuration file path. If omitted, CLI uses the default
  `~/.config/kaiten/config.json`.
- **FR-003**: The CLI MUST resolve connection parameters in
   priority order: explicit `--config` path > default config path.
   URL and token MUST be read from the selected config file.
   Environment variables are NOT used.
- **FR-004**: The CLI MUST output structured data to stdout and
  errors to stderr.
- **FR-005**: The CLI MUST exit with code 0 on success and
  non-zero on error.
- **FR-006**: Configuration is stored in two files in a shared
  directory `~/.config/kaiten/` (all platforms):
  - **`config.json`** — connection settings (url, token):
    ```json
    {
      "url": "https://company.kaiten.ru/api/latest",
      "token": "your-api-token"
    }
    ```
  - **`preferences.json`** — user preferences (favorite boards,
    spaces). Managed by KaitenMCP. The CLI does not read or write
    this file.

  The CLI reads only `config.json`.
- **FR-007**: The CLI MUST use `swift-configuration`
  (`ConfigReader` + `FileProvider<JSONSnapshot>`) to read the
  config file. `swift-configuration` is a dependency of the CLI
  target only, not the SDK.
- **FR-008**: The CLI MUST NOT expose destructive delete commands for
  spaces, boards, or lanes.
- **FR-009**: The CLI MUST validate user-provided enum and list inputs
  before invoking SDK methods. Invalid enum values, malformed CSV tokens,
  or partially parseable lists MUST produce a validation error; silent
  dropping of invalid tokens is forbidden.
- **FR-010**: The CLI MUST validate pagination parameters before SDK
  invocation. Invalid values (`offset < 0`, `limit <= 0`, or values
  above endpoint/documented caps) MUST fail fast with a clear error.
- **FR-011**: If `config.json` exists but cannot be parsed or read,
  the CLI MUST return a configuration error. Configuration read errors
  MUST NOT be silently ignored.
- **FR-012**: CLI command arguments MUST stay behaviorally aligned with
  the mapped SDK method signature. If a CLI option is defined for a
  command (for example lane `rowCount` in update-lane), it MUST be
  forwarded to the SDK call.
- **FR-013**: CLI MUST keep help text and runtime validation aligned for enum-like options.
  Any value documented as allowed in help MUST be accepted by validation;
  stale/mismatched allowed-value lists are forbidden.
- **FR-014**: For options that map to SDK enums (for example card `position`,
  `condition`, `textFormatTypeId`), unknown values MUST produce validation errors.
  Silent dropping via optional coercion is forbidden.
- **FR-015**: CSV/list-style ID filters MUST use strict token parsing consistently
  across commands (including `list-users --ids`); malformed tokens MUST fail locally.
- **FR-016**: The only supported connection argument is `--config`.
  URL and token input is allowed only via selected config file (`--config` path or default config path).
- **FR-017**: SDK inputs that are free-form JSON objects rather than scalars
  (card custom properties) MUST still be reachable from the CLI, as a single
  option carrying a JSON object string. The CLI MUST parse and validate that
  string locally before invoking the SDK method: input that is not a JSON
  object, or that does not decode into the mapped payload, MUST produce a
  validation error rather than being dropped or forwarded.

- **FR-018**: Command output MUST omit nested entities by default, keeping
  only scalar fields and `*_id` references. A `--expand` option MUST accept a
  comma-separated list of nested field names, or `all`, to include them.
  Expansion MUST stop after one level: an expanded value MUST itself be
  stripped of its own nested fields, so that response size follows the
  request rather than the shape of the entity graph. `Card.children` and
  `Card.parents` are arrays of cards, so unbounded expansion would not
  terminate on a cyclic graph.
- **FR-019**: The set of names `--expand` accepts MUST be derived from the
  response rather than from a per-command list, so it cannot drift out of
  sync with the API. An unknown name MUST produce a validation error listing
  the names the response does offer; silently ignoring it is forbidden.
  A response that contains entities but no nested fields MUST reject any
  `--expand` value.
- **FR-019a**: An empty result set MUST accept `--expand` rather than reject
  it. There is nothing to validate a name against, and failing here would
  make a filter that legitimately matched no rows return an error instead of
  an empty list.
- **FR-019b**: A field whose value is an empty collection MUST be treated as
  expandable even though it is kept by default. Judging expandability by the
  value's type alone would make the same `--expand` name succeed on one row
  and fail on the next depending on whether that row's collection happens to
  be populated. The cost is that a scalar ID array (`tag_ids` and the like)
  also appears expandable while empty, where expanding it is a no-op; a
  response cannot distinguish an empty list of IDs from an empty list of
  entities. Deriving the set from the OpenAPI schema at build time would
  remove that cost and is the intended long-term fix.
- **FR-020**: JSON output MUST be compact rather than pretty-printed, with
  keys sorted so that output is stable across runs.
- **FR-021**: Where a collection of entities is omitted, the CLI MUST replace
  it with an array of their ids **under the same key**, so the response still
  states that the relation exists. A single relation needs no such treatment —
  dropping `owner` leaves `owner_id` behind — but a collection had no
  fallback, and a card with members was indistinguishable from a card with
  none. Keeping the key means an empty collection and a populated one report
  the same field, which renaming to `member_ids` would not achieve.
  A consequence is that the element type depends on `--expand`: ids by
  default, entities when expanded. That is accepted; it is what `--expand`
  means, and it beats two field names for one relation.
  The CLI MUST NOT invent ids, and id arrays Kaiten sends itself (`tag_ids`,
  `parents_ids`) MUST be passed through untouched.
- **FR-021a**: Only entities may be trimmed, and the presence of an `id` is
  what identifies one. A nested value carrying no `id` is data rather than a
  reference — a card's `properties` holds custom field values shaped
  `{"id_714": [1088]}` — and MUST be passed through whole, whether it is an
  object or a collection. No `properties_id` exists to stand in for it, so
  dropping it would lose the values themselves rather than a reference to
  them, which is precisely the silent loss this trimming exists to prevent.
  Such fields MUST NOT be offered to `--expand`: never having been collapsed,
  there is nothing to restore.
- **FR-022**: Where the CLI knowingly passes through a field that
  misreports, the help of the affected subcommand MUST say so.
  `children_ids` and `children_count` undercount — both have been observed
  reporting eight children for a card that has eleven, and expanding
  `children` returns the same short list — so `get-card`, `list-cards` and
  `list-card-children` each state it. The CLI MUST NOT issue extra requests
  to repair such a field: the cost is per row, and documenting the limit
  keeps one command one request.
- **FR-023**: A subcommand's help MUST describe the behaviour of its own
  endpoint and nothing else. It MUST NOT direct the reader to other
  subcommands: `kaiten --help` already lists them, cross-references are the
  first thing to rot, and a subcommand's help is not a guide to the CLI.
  Help MUST NOT explain the shell, `jq`, or how to consume the output, and
  MUST NOT carry worked examples or the evidence behind a stated limit —
  none of that is this CLI's behaviour to document. Properties shared by
  every response belong once in the root command's discussion.

### Non-Functional Requirements

- **NFR-001**: The CLI MUST compile and run on macOS (ARM) and
  Linux (x86-64 and ARM).
- **NFR-002**: CLI command source files MUST mirror the SDK/API domain
  grouping from Kaiten documentation (for example: cards, boards,
  spaces, users) while preserving existing command behavior.
- **NFR-003**: Security-sensitive inputs in CLI UX/documentation MUST follow
  least-exposure principles. Examples and docs MUST avoid recommending
  command-line token literals as the primary workflow.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The CLI can be used in automation scripts — each
  subcommand accepts all input via selected config file and
  produces machine-readable output.
- **SC-002**: The CLI contains no duplication of SDK logic — each
  subcommand only calls the corresponding SDK method.
- **SC-003**: The CLI compiles and runs on macOS (ARM) and
  Linux (x86-64 and ARM).
