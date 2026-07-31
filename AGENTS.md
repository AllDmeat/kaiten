# KaitenSDK — Development Guidelines

## Language Policy

**English only.** All content in this repository MUST be in English:
- Code, comments, documentation
- Commit messages, PR titles and descriptions
- Issue titles and descriptions
- Specs, READMEs, and any other markdown files
- YAML descriptions in OpenAPI spec

No exceptions. Existing Russian content will be translated (see #163).

## Spec-First Development

Specifications in `specs/` are the single source of truth for what
is being built and how.

### Workflow

1. **Spec first** — before implementing new functionality,
   update or create a specification in `specs/`.
2. **Then implement** — code is written strictly according to the spec.
3. **Every change** to functionality MUST be accompanied by
   an update to the corresponding spec.

### Spec Structure

- `specs/001-kaiten-sdk-core/spec.md` — SDK: OpenAPI generation,
  typed errors, convenience wrappers
- `specs/002-kaiten-cli/spec.md` — CLI: thin wrapper over SDK,
  config file, subcommands

### Constitution

Architectural principles and constraints are documented in
`.specify/memory/constitution.md`. The constitution takes priority
over all other project practices.

### Rules for Agents

- DO NOT implement functionality not described in the spec.
- If a discrepancy between code and spec is found,
  clarify with the user which is correct.
- When adding new functionality — update the spec first,
  get confirmation, then implement.
- Always update READMEs when public APIs change. Any PR that
  modifies public API surface must include corresponding README
  updates. Specifically: the "API Reference" tables and "CLI Commands"
  section in README.md. No exceptions.

## Agent Plugin Releases

This repository is a plugin marketplace twice over — `.claude-plugin/marketplace.json`
for Claude Code and `.cursor-plugin/marketplace.json` for Cursor — and both point
at [`agent/`](agent), which is simultaneously a Gemini CLI extension. All three
hosts read the one skill in `agent/skills/kaiten/`: a single copy of the guidance
with several manifests describing it.

### Mandatory Rule

**Editing anything under `agent/` is not enough to ship it.** The `version`
field pins the plugin: while the string stays the same, Claude Code keeps
serving the copy users already have, and an improved skill reaches nobody.
There is no error and no warning — the update simply never arrives.

So every change to `agent/` must, in the same PR:

1. **Bump `version`** in **every** manifest that carries one, to the same value:
   - `.claude-plugin/marketplace.json` → both `metadata` and the plugin entry
   - `agent/.claude-plugin/plugin.json`
   - `agent/.cursor-plugin/plugin.json`
   - `agent/gemini-extension.json`

   (`.cursor-plugin/marketplace.json` has no version field — nothing to bump there.)

   Use semver against the previous plugin version. This line is independent of
   the CLI's own version — do not assume the two match. Missing one manifest
   leaves that host serving the old skill while the others update, which is
   harder to notice than nothing updating at all.
2. **Merge to `main`.** The marketplace is served from the default branch, so
   the merge is what publishes the new version.
3. **Cut a release.** Push a `*.*.*` tag to trigger
   [`release.yml`](.github/workflows/release.yml), so the CLI binary and the
   plugin that documents it ship together and the release notes record what
   changed for agents. For Gemini CLI the release is not optional — it is the
   only thing that carries the extension, since Gemini installs from a release
   asset rather than from the branch.

   Do not rename the `{platform}.kaiten.tar.gz` assets. Gemini resolves an asset
   by trying the `{platform}.{arch}.` prefix, then `{platform}.`, and only falls
   back to a generic asset when the release has exactly one. Because this
   release also ships CLI binaries, a differently-named archive silently stops
   matching, Gemini falls back to the repository source tarball — which has no
   `gemini-extension.json` at its root — and the install breaks.

Users then pick the change up with `/plugin update kaiten@kaiten`.

### Validate Before Merging

Run both, and treat warnings as errors:

```bash
claude plugin validate .
claude plugin validate ./agent --strict
```

This is not optional politeness. A skill whose YAML frontmatter fails to parse
still loads — with **empty metadata**, which silently disables its triggering
entirely. A single unquoted `: ` inside the `description` is enough to cause
it, and nothing at runtime reports the problem.

### Do Not Add `contextFileName` to the Gemini Manifest

`agent/gemini-extension.json` deliberately omits `contextFileName`, so Gemini
discovers `agent/skills/kaiten/SKILL.md` as a skill and activates it only when a
task is relevant. Pointing `contextFileName` at the same file would load it into
**every** session instead, taxing unrelated work with guidance about a tracker
that is not in play. The skill was built and measured around being triggered;
turning it into always-on context throws that away.

### Keep the Skill Free of Facts That Drift

The skill ships separately from the CLI and lags behind it, so it must not
restate anything the CLI can change under it: subcommand or flag counts, CLI
versions, pagination limits, or enumerations of subcommands. Prefer teaching
how to find the answer — for example, the page-envelope shape is identified by
the `(paginated)` marker in `kaiten --help` rather than by listing the
subcommands that return it. The skill states that `--help` outranks it; keep
that true.

## Kaiten API Documentation

Detailed guide for parsing Kaiten API documentation: [docs/kaiten-docs-parsing.md](docs/kaiten-docs-parsing.md)

### Mandatory Rule

**Before any change to the OpenAPI spec** (`openapi/kaiten.yaml`) — you must verify against the Kaiten API documentation (https://developers.kaiten.ru) how the endpoint actually works:
- Which query/path parameters it accepts
- Which response fields are required (`integer`, `string`) and which are nullable (`null | string`)
- Whether pagination is supported (`offset`/`limit`)

Do not modify the spec based on guesses or empirical data. Only based on documentation.

### Annotating Discrepancies Between Docs and Actual API

When the actual Kaiten API behaves differently from what the official documentation declares,
you **must** leave a `# DOC_MISMATCH:` comment in `openapi/kaiten.yaml` directly above the affected field.

**Format — always a single line:**

```yaml
# DOC_MISMATCH: docs=`string`, actual=`integer` — https://developers.kaiten.ru/...
# DOC_MISMATCH: docs=non-nullable `integer`, actual=`integer | null` — https://developers.kaiten.ru/...
# DOC_MISMATCH: not in docs, present in actual API responses — https://developers.kaiten.ru/...
# DOC_MISMATCH: docs=`enum` (no values listed), actual=`string`; observed: "a", "b" — https://developers.kaiten.ru/...
```

Rules:
- Place the comment **before** `type:`, not after `description:`
- The URL must point to the **specific documentation page** where the field is described
- One line per discrepancy

This prevents future contributors from re-introducing the same bugs.

## Code Formatting

This project uses [swift-format](https://github.com/swiftlang/swift-format) (bundled with the Swift toolchain) with default configuration.

**Before every commit**, run:

```bash
swift format format --in-place --recursive Sources/ Tests/
```

CI runs `swift format lint --strict --recursive Sources/ Tests/` on every PR. Unformatted code will fail the lint check.
