---
name: pickup
description: Resume work from a handoff file written by /handoff. Reads docs/handoffs/, selects the lane (by slug argument, or the single active one), verifies the repo still matches what the handoff recorded, and states the next action. Use when the user types /pickup, /pickup <slug>, or asks to resume or continue previous work.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

# /pickup — resume from a handoff

Load a handoff written by `/handoff` and get to work. You have no memory of
the session that wrote it; the file is the only source.

## Arguments

```
/pickup                resume the active lane
/pickup <slug>         resume that lane, active or not
/pickup --list         list every lane with status, date and title; do not resume
```

## Finding the handoff

Look in `<repo root>/docs/handoffs/*.md`, and `<repo root>/.handoffs/*.md` if
that directory is the one in use. Read each file's frontmatter for `lane`,
`status`, `updated` and `title`.

Selection:

1. **`<slug>` given** — use `docs/handoffs/<slug>.md`. If absent, list what
   does exist and stop. Never guess at a near-match; a wrong lane is worse
   than no lane.
2. **No argument, exactly one `status: active`** — use it.
3. **No argument, several active** — list them with title and date, ask which.
   Do not pick the newest on your own.
4. **No argument, none active** — say so and list the inactive lanes, newest
   first, in case one should be reopened.

**Legacy files.** A handoff with no frontmatter (e.g. an older
`CURRENT_STATE.md`) is still valid — read it, treat it as active, and mention
that it predates the lane format. Offer to migrate it to a named lane, but
only act on a yes.

## After reading, before acting

The handoff describes the repo as it was on its `updated` date. Check what has
moved since, and report any drift **before** starting work:

```bash
git branch --show-current
git log --oneline -5
git status --short
```

Compare against the frontmatter `branch` and `commit`. Drift worth reporting:

- **HEAD has moved** — say how many commits and whether they look related.
- **Different branch** than recorded.
- **Uncommitted changes** the handoff did not mention.
- **The handoff is stale** — more than a couple of weeks old, or its *Start
  here* actions reference files that no longer exist.

State drift plainly and continue; do not refuse to work because of it. A
handoff being somewhat out of date is normal, not an error.

## Then

1. **Summarize** — the lane, its one-line title, when it was written, and the
   next action, in a few lines. The user has just cleared their context too
   and needs re-orienting.
2. **Surface the load-bearing sections** — *Blocked*, *Never exercised* and
   *Deliberately not built* exist to prevent specific mistakes. Read them
   before touching code. Never "fix" something listed under *Deliberately not
   built* without asking.
3. **Verify a claim or two** before building on it. If the handoff says the
   tests passed, run them. Evidence in the file is evidence about the past.
4. **Confirm the next action** and begin. If several are listed, take the
   first unless the user redirects.

## Rules

- **Report what the file actually says**, including where it is vague. Do not
  fill gaps with plausible invention — an unclear handoff is a fact about the
  handoff, and worth telling the user.
- **Do not update the handoff on pickup.** It is updated by `/handoff`,
  at the end of the next session, not at the start.
- **`--list` resumes nothing.** Print the table and stop.
