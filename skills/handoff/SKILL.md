---
name: handoff
description: Crystallize the current session into a resumable handoff file under docs/handoffs/ so a fresh session can continue via /pickup. Supports multiple named lanes and active/inactive marking. Use when the user types /handoff, or asks to write a handoff, checkpoint the session, or save state before /clear.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

# /handoff — crystallize this session for the next one

Write a handoff file that lets a **fresh session with no memory of this
conversation** resume the work. The reader is an agent who was not here.

## Arguments

```
/handoff                  update the lane in play, or create one if none
/handoff <slug>           write to that lane (create or overwrite)
/handoff done <slug>      mark that lane inactive; write no new content
/handoff done             mark the lane in play inactive
```

`<slug>` is kebab-case, matching the work rather than the date:
`billing-webhooks`, `node-22-upgrade`, `rls-recursion`. Never `handoff` or `notes`.

## Where files live

`docs/handoffs/<slug>.md`, relative to the repository root (`git rev-parse
--show-toplevel`). Create the directory if absent. If the repo has no `docs/`
convention at all, use `.handoffs/` at the root instead and say so.

## Determining the lane

1. An explicit `<slug>` argument always wins.
2. Otherwise, if exactly one **active** handoff exists, update it.
3. Otherwise, if the current branch matches a lane slug, use it.
4. Otherwise derive a slug from the work actually done this session and say
   which you chose. Do NOT silently overwrite another lane.

Lanes are independent — several may be active at once. Marking one inactive
never touches another.

## Before writing

Gather facts; do not write from memory alone.

```bash
git rev-parse --show-toplevel
git branch --show-current
git log --oneline -5
git status --short
```

Re-read anything you are about to assert. If you claim tests pass, either you
ran them this session or you write who ran them and when — never imply a
verification that did not happen.

## File format

Frontmatter is required and machine-read by `/pickup`:

```markdown
---
lane: <slug>
status: active
updated: <YYYY-MM-DD>
branch: <branch>
commit: <short sha>
title: <one line, what this lane is>
---
```

Then the body, in this order. Omit a section only when it would be genuinely
empty — an empty *Blocked* is worth stating as "nothing".

### Start here: the N things left
The next actions, most important first, each one concrete enough to begin
without re-deriving anything. Name files and line numbers. If an action is
waiting on a person, say so here and repeat it under *Blocked*.

### What happened this session
What changed and, more importantly, **why** — the rulings and the reasoning,
which the diff cannot show. Include decisions that were made and rejected.

### Where things stand — evidence, not adjectives
Facts a reader can check, not confidence. Prefer a table or list of commands
actually run and what they printed:

```
npx vitest run      -> 436 passed, 48 files
npx tsc --noEmit    -> clean
vercel ls --prod    -> ● Ready, 32s build
```

"The tests pass" is worthless without the number and the command.

### Blocked
Anything that cannot proceed, and precisely what would unblock it — an answer
from a person, a credential, a deploy. Say who is blocking and on what.

### Never exercised
Paths that exist in code but have never actually run — the things most likely
to break first, and invisible in a diff. This section earns its keep.

### Deliberately not built
Choices made against doing something, with the reason. This stops the next
agent from "fixing" a deliberate decision. Cite who ruled and when.

### Known and accepted
Live defects or rough edges that were seen and consciously tolerated.

## Rules

- **Write for a stranger.** No "as discussed", no "the usual fix", no pronouns
  whose referent left with this conversation.
- **Dates absolute.** "2026-09-12", never "yesterday" or "last week".
- **Never invent verification.** If something is unproven, it belongs under
  *Never exercised*, not under evidence.
- **Do not commit** the handoff unless the user asks. Write the file, report
  the path, stop.
- **Overwriting an existing active lane**: read it first and carry forward
  anything still true — especially *Blocked*, *Never exercised* and
  *Deliberately not built*, which survive across sessions. A handoff that
  drops them loses the most expensive knowledge in the file.

## Marking inactive

`/handoff done <slug>` sets `status: inactive` in the frontmatter and changes
nothing else. Do not delete the file — a finished lane is a record. If the
user asks to delete, confirm first.

## Finishing

Report the path written, the lane, its status, and a one-line summary of what
the next session will pick up. Then suggest `/clear`, and note that
`/pickup <slug>` resumes it.
