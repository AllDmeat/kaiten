---
name: kaiten
description: Read and change anything in Kaiten (kaiten.ru project management / kanban tracker) through the `kaiten` CLI — cards, boards, spaces, columns, lanes, sprints, checklists, comments, members, tags, blockers, custom properties, users. Use this skill whenever Kaiten comes up in any form, and do not wait for a perfectly-phrased request — it applies to a kaiten.ru URL, a card or board or sprint ID, "what's on the board", "move this card to done", "who's on this ticket", "what did the team ship this sprint", "add a comment/checklist/tag", any request to read or update the team's Kaiten tracker, and any invocation of the `kaiten` command itself. It applies when the user never types the word "Kaiten" but is plainly talking about their Kaiten tracker — a board or card ID they already work with, or their team's tracker in general. It does NOT apply to other trackers — a request naming Jira, Linear, YouTrack, Trello, Asana, Notion, GitHub Issues or the like is out of scope even though they share the card/board/sprint/column vocabulary, and the answer there is that the named tracker is what the user asked about, not Kaiten. The CLI ships a large, flat set of subcommands whose names and flags cannot be guessed correctly, so this skill exists to make you read its `--help` first and work from what it says instead of inventing commands.
---

# kaiten

`kaiten` is a CLI over the [Kaiten](https://kaiten.ru) project management API. Its subcommands are a
single flat list, and there is no interactive mode.

## The help is the API. Read it before you type a command.

The subcommand names do not follow a guessable pattern. There is no noun-then-verb grouping, so
`kaiten cards list --board 42` and `kaiten card get 123` are both fabrications that fail. The real
names are flat and irregular: `list-cards`, `get-card`, `get-card-comments`, `list-card-children`,
`get-board-columns`, `list-custom-property-select-values`. A single subcommand can take dozens of
flags, and releases keep adding subcommands.

Nobody, including you, can hold that surface in their head. So do this every time:

```bash
kaiten --help                    # once per session: all subcommands with one-line abstracts
kaiten <subcommand> --help       # before the first call to a subcommand you have not used yet
```

Both are cheap and instant — they make no network calls and need no credentials. Running them is
always faster than guessing wrong, reading an "Unknown option" error, and guessing again.

**Flag names do not carry across subcommands.** The most common way this goes wrong is reading the
help for one subcommand and reusing its flags on a neighbour that sounds related:

```
get-board-columns --board-id 42     get-checklist --card-id 7 --checklist-id 3
get-board-lanes   --board-id 42     get-card-history --card-id 7
get-board         --id 42           get-card --id 7
```

`kaiten get-board --board-id 42` fails, even though the two subcommands directly above it take
exactly that flag. Do not try to derive a rule from this — `get-checklist` already breaks the
obvious one. The naming is not predictable, which is precisely why the help exists: read the help of
each subcommand before its first real call, including when you just read the help of what looks like
its sibling.

**The help output outranks this document.** This file tells you things the help cannot, but it ships
separately from the CLI and drifts behind it. Wherever the two disagree, the help is right and this
file is stale. That is also why you should not paste flag lists from here into a command — get them
from `--help`.

## Go through `kaiten`, not around it

Once you are working with Kaiten, route every read and write through this CLI. Do not `curl` the
Kaiten REST API directly, and do not write a throwaway HTTP client — the CLI already solves token
handling, `429` back-off, and the pagination envelope, and reaching past it reintroduces exactly
those problems. The acceptable companions are `jq` for filtering the JSON and ordinary shell.

If the CLI genuinely has no subcommand for what is being asked, say so and stop rather than
improvising a raw API call.

## Credentials

Credentials live in a config file, not in flags or environment variables. Default location:

```
~/.config/kaiten/config.json
```

```json
{
  "url": "https://<company>.kaiten.ru/api/latest",
  "token": "<api-token>"
}
```

`--config <path>` (available on every subcommand) points at a different file.

Read the failure rather than working around it, because the two failure modes need opposite
responses:

- **Missing URL or missing token** — the config file is absent or incomplete. Tell the user, and
  point them at `https://<company>.kaiten.ru/profile/api-key` for a token.
- **`Network error: …` or an authentication rejection** — the config was found and used; the problem
  is the environment or the credentials in it. Report that and stop.

In neither case should you go hunting for other config files, pass `--config` at paths you guessed,
or re-run the same command hoping for a different result. A command that failed to reach the server
will fail the same way the second time, and a config you found by searching the filesystem is not
one the user asked you to authenticate as. Do not echo the token into the transcript.

## You start with no IDs — walk down to them

Almost every useful subcommand takes a numeric ID that the user will not give you. Get IDs from the
API rather than guessing or reusing a number from earlier in the conversation:

```bash
kaiten list-spaces                          # → space IDs
kaiten list-boards --space-id <space>       # → board IDs
kaiten get-board-columns --board-id <board> # → column IDs
kaiten list-cards --board-id <board>        # → card IDs
```

Same idea elsewhere: resolve a person with `kaiten list-users --query <name>` before passing
`--owner-id` / `--member-ids`, and find the sprint with `kaiten list-sprints --active` before
`kaiten get-sprint-summary --id`.

## Output: always JSON, in one of two shapes

Every subcommand prints compact JSON to stdout — a single line, keys sorted — so pipe it to `jq`.
There are two shapes and mixing them up is the most common way these pipelines break:

- Subcommands whose abstract in `kaiten --help` ends in **`(paginated)`** return a page envelope:
  `{"items": [...], "offset": …, "limit": …, "hasMore": …}`. Filter with `jq '.items[]'`.
- **Everything else** returns a bare array or a bare object. Filter with `jq '.[]'`.

That `(paginated)` marker is the reliable signal, and it is worth checking rather than assuming,
because accepting `--offset` / `--limit` is not the same thing. Several subcommands take those flags
and still return a bare array with no `hasMore` — to page one of those, keep going until a response
comes back shorter than the `--limit` you asked for.

## Related entities are omitted until you ask for them

A response carries that entity's own scalars plus `*_id` references to its neighbours. The entities
behind those references — the person behind `owner_id`, the board behind `board_id`, and collections
such as members, tags, children or files — are left out unless you name them:

```bash
kaiten get-card --id 7                       # scalars and *_id references only
kaiten get-card --id 7 --expand owner,tags   # those two come back as full objects
kaiten get-card --id 7 --expand all          # every related entity in this response
```

**A missing key says nothing about the tracker.** This is the trap worth internalising, because it
produces confident false answers rather than errors: a card whose output has no `owner` key still
has an owner, and "this card is unassigned" read off a default response is a fabrication. Whenever
the fact you need is about a neighbouring entity rather than the one you fetched, expand it or fetch
it — never infer it from silence. The same goes for counting: `members` being absent is not zero
members, though a `*_count` or `*_total` scalar, when the response has one, is a real answer.

**Ask for the fields you need rather than reaching for `all`.** These payloads are large — a single
expanded owner is a whole user record — and `all` on a list of cards multiplies that by every row.
Naming two or three fields keeps a board-sized response readable instead of burying the answer.

**To find out what a subcommand offers, ask it for a field that does not exist:**

```bash
kaiten get-card --id 7 --expand '?'
# Error: Unknown --expand field: '?'. Available: board, column, lane, members, owner, …
```

Quote the `?` — unquoted it is a shell glob and never reaches the CLI. Any other name that
cannot be a field does the same job: `--expand nope`.

That list is computed from the response in front of you, so it is accurate for that call in a way no
document can be — including this one, which is why no list of expandable fields appears here.

**Expansion goes exactly one level deep.** `--expand children` returns a card's children as objects,
but each child is trimmed by the same rule, so the children's own children are not there. This is
deliberate: cards nest into cards, and unbounded expansion would return the shape of the graph
rather than the answer. To go deeper, run the next command against the ID you just got back.

**A name absent from that `Available:` list means the response does not contain it** — which is not
the same as the data not existing. Relations frequently have a subcommand of their own, so check
`kaiten --help` for one before concluding anything; a few subcommands also take a flag that asks the
server to include extra fields, and their `--help` says so. Guessing again with a different spelling
is the one thing that will not help.

## Paging a full board

Each subcommand's `--help` states its maximum `--limit`, and anything board-sized will exceed it, so
plan on a loop:

```bash
limit=100   # confirm the max in `kaiten list-cards --help`
offset=0
while :; do
  page=$(kaiten list-cards --board-id 42 --limit "$limit" --offset "$offset")
  echo "$page" | jq -c '.items[]'
  [ "$(echo "$page" | jq -r '.hasMore')" = "true" ] || break
  offset=$((offset + limit))
done
```

## Rate limiting is already handled

`429 Too Many Requests` is retried inside the SDK, honouring `Retry-After`, with the back-off shared
across concurrent requests. Do not add `sleep` calls, retry loops, or hand-rolled throttling — they
only slow the run down. If a rate-limit error does surface, it already survived the retry: report it
instead of wrapping it in another loop.

## Small things that bite

- There is no `--version` flag.
- Multi-value flags take one comma-separated string, not a repeated flag: `--states 1,2` and
  `--type-ids 7,9`. Repeating a flag keeps only the last value, silently.
- Dates are ISO 8601.
- Flags like `--states` and `--condition` take magic integers, and each subcommand's `--help` spells
  out what they mean. Read it there rather than assuming the numbering carries across flags.
- `delete-card`, `delete-comment` and the `remove-*` subcommands act immediately, with no
  confirmation prompt and no undo. Confirm with the user before running one.

## If the CLI is missing

If `kaiten` is not on `$PATH`, download the binary for the platform from
[Releases](https://github.com/AllDmeat/kaiten-sdk/releases). Do not substitute `curl` against the
API, and do not suggest building from source — that is the contributor flow, not the user flow.
