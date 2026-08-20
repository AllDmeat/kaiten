---
name: kaiten-reference
description: Maintain the user's local Kaiten reference file — a curated file of entity IDs and metadata (spaces, boards, columns, lanes, card types, custom properties, users) living next to the kaiten CLI config or wherever its `reference` key points. Use whenever that file needs to be read, created, filled, extended, or checked — when any Kaiten entity ID had to be resolved through the API (the file may be missing it, or may not exist yet and should be offered), when the user asks to save or record a Kaiten ID "for next time", or when deciding whether an ID found by name search can be trusted. Applies alongside the kaiten skill, not instead of it.
---

# kaiten-reference

Users of the `kaiten` CLI can keep a local reference file with the entity IDs and metadata they
actually work with: spaces, boards, columns, lanes, card types, custom properties, users — whatever
they need.

## Where the file lives

- **Default**: next to the CLI config — `~/.config/kaiten/reference.<ext>`, any extension
  (`reference.md`, `reference.json`, `reference.yaml`, …). Look for it there first.
- **Override**: an optional `reference` key in the config (`~/.config/kaiten/config.json`, or the
  file passed via `--config`) points anywhere else:

```json
{
  "url": "https://<company>.kaiten.ru/api/latest",
  "token": "<api-token>",
  "reference": "~/notes/kaiten-reference.json"
}
```

The CLI itself ignores the key and the file. Both exist for agents.

## Why the file outranks the API

Kaiten instances accumulate duplicates: spaces, boards, and card types with identical names.
Resolving an entity by name through the API can silently return the wrong one of two same-named
entities, and nothing in the response reveals the mistake. IDs a human has verified and written
down do not have this problem. So when the reference file has the ID, use it and do not re-resolve
it through the API.

## No file yet? Offer to start one

The file only helps once it exists, so do not wait to be asked. The moment a task forces you to
resolve an ID through the API and no reference file exists — neither at the default location nor
via the `reference` key — tell the user what you had to look up and offer to start the file with
it. Propose the default location, `~/.config/kaiten/reference.md`, unless the user prefers another
path (then also add the `reference` key to the config) or another format. Seed it only with IDs
the user confirms — do not bulk-dump the API into it: a reference full of unverified entries,
duplicates included, defeats its purpose.

## The file belongs to the user

There is no required format. It can be JSON, YAML, Markdown, plain text — whatever the user finds
convenient to read and edit by hand. It follows that you must never impose a structure on it:

- When appending, match the format and structure the file already has.
- Never reformat, reorder, or restructure the file unless the user asks for exactly that.
- Never delete or rewrite existing entries on your own.

## Keep it growing — with approval

1. **Read before writing.** Before adding anything, read the file and check whether the data is
   already there. A duplicate entry is worse than no entry — the next reader cannot tell which
   copy is the verified one.
2. **When the API taught you something the file lacks, offer to save it.** If a task forced you to
   resolve an ID or other metadata through the API and the reference file does not have it, do not
   let that knowledge evaporate at the end of the session. Tell the user what you found and propose
   the exact addition — show the lines you intend to write.
3. **Append only after explicit approval.** The file is the user's curated source of truth; an
   unverified ID written into it silently poisons every future session that trusts it. No approval,
   no write — mentioning the finding in conversation is enough until the user says yes.
