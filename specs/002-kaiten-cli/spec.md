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
