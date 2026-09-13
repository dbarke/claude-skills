---
name: sync-omarchy-config
description: Refresh the user's pushed Omarchy customizations repo (a bare git repo at ~/.omarchy-config.git with work tree $HOME, pushed to a private remote). Finds changed tracked files and new customizations worth tracking, updates the README/plugins/restore kit, checks for secrets, commits and pushes. Use when the user types /sync-omarchy-config, or asks to refresh, sync, update, back up or push their Omarchy config/dotfiles.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# /sync-omarchy-config — refresh the pushed Omarchy config

The repo is **bare**: `git --git-dir=$HOME/.omarchy-config.git --work-tree=$HOME`
(override the location with `OMARCHY_CONFIG_GIT_DIR`; a shell alias such as
`ocfg` may exist, but aliases don't work in your Bash tool, so use the full
form). Untracked files are hidden (`status.showUntrackedFiles no`), so new
customizations never show up in `git status` — that is what the scan is for.
The remote URL comes from `git remote get-url origin`; never hardcode it.

Repo-owned meta files:
- `~/.github/README.md` — what's tracked (table) and how to restore
- `~/.config/omarchy-config/plugins.txt` — shell plugins as `<id> <git url>`
- `~/.config/omarchy-config/restore.sh` — fresh-install restore (theme, font, timers)
- `~/.config/omarchy-config/ignore.txt` — paths the user decided not to track

Never modify anything under `/usr/share/omarchy/`. Don't change the user's
actual configs here — this skill only records them.

## First run (no repo yet)

If `scan.sh` reports no repo, offer to create one, and only proceed on a yes:

1. `git init --bare -b main ~/.omarchy-config.git` and set
   `status.showUntrackedFiles no` on it.
2. Add `alias ocfg='git --git-dir=$HOME/.omarchy-config.git --work-tree=$HOME'`
   to `~/.bashrc`.
3. Create the meta files above: `plugins.txt` from the installed plugins' git
   remotes, an empty-ish `ignore.txt`, a `restore.sh` (clone bare, back up
   files it would overwrite, `checkout -f`, reinstall plugins with
   `omarchy plugin add <url> --enable --yes`, set theme and font, enable user
   units), and a README with the tracked-files table and restore instructions.
4. Then run the normal steps below; everything is a candidate on first run.
5. Create the remote only with explicit consent, and **private** by default
   (`gh repo create <name> --private`), since configs hold names, emails and
   locations.

## Arguments

Free text, optional. `dry-run` = report only, commit nothing. Anything else is
a hint for the commit message.

## Steps

1. **Scan.** Run `~/.claude/skills/sync-omarchy-config/scan.sh`. It is read-only
   and reports: ahead/behind, changed tracked files, untracked candidates
   (configs differing from Omarchy defaults, user files in Hyprland/Omarchy
   dirs, personal scripts and user units, other configs edited since the last
   commit), plugin drift vs `plugins.txt`, current theme/font vs `restore.sh`,
   and enabled user units.

   If the branch is **behind** origin, stop and tell the user (another machine
   pushed); don't overwrite. Offer `pull` only after showing what came in.

2. **Review changed tracked files.** `git diff --stat`, then read the diff.
   Understand each change well enough to describe it in one line. If a tracked
   file was deleted, ask whether to `git rm` it or restore it.

3. **Triage untracked candidates.** For each, read it and decide:
   - **Track** — a deliberate customization (Hyprland overrides, toggles,
     workspace layouts, shell/menu config, personal scripts and their units,
     app configs the user tuned).
   - **Ignore** — generated, cache/state noise, owned by another repo, or
     identical to what an installer writes. Add it to `ignore.txt` with a short
     reason so it's never suggested again.
   - **Unsure** — ask the user with AskUserQuestion (batch them, multiSelect).

   Obvious calls don't need a question. Anything that installs from its own
   repo (shell plugins, script bundles with their own installer) is
   referenced, not copied.

4. **Secrets gate.** Before staging, grep every file you're about to add or that
   changed for tokens and credentials:
   `grep -nEi 'gh[pousr]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9-]{20,}|(api[_-]?key|token|secret|password|passwd|client_secret)\s*[=:]\s*\S{8,}|BEGIN [A-Z ]*PRIVATE KEY'`
   Never commit a match — ignore the file or ask the user. Also never track
   `*credentials*`, `~/.ssh`, `~/.config/gh`, browser profiles, or `*.bak.*`.

5. **Update the restore kit** when the scan shows drift:
   - Plugin installed but missing from `plugins.txt` → add `<id> <url>`
     (no git remote → tell the user it can't be restored that way). Listed but
     not installed → ask whether it was removed on purpose, then drop the line.
   - Theme/font differs from `restore.sh` → update the `omarchy theme set`
     (use the kebab-case name from `omarchy theme list`, e.g. `tokyo-night`)
     and `omarchy font set` lines.
   - Newly tracked user unit that is enabled → add a
     `systemctl --user enable --now <unit>` line.
   - Update the **What's tracked** table in `~/.github/README.md` for anything
     added or removed, and adjust descriptions whose meaning changed (e.g. the
     Hyprland row lists the notable overrides). Keep it terse.

6. **Stage and show.** `git add` the tracked changes, new files and edited meta
   files, then show `git status --short` and a one-line-per-file summary.
   If `dry-run`, stop here and unstage (`git reset -q`).

7. **Commit and push.** Commit message: a short imperative subject naming the
   gist (e.g. "Pin scrolling edges, track cliamp config"), a body with one line
   per notable change, then the attribution lines from the current
   system-reminder. Push with `git push`. If nothing changed at all, say the
   repo is already up to date and don't create an empty commit.

8. **Report.** Commit hash and subject, what was added/updated/ignored, any
   questions left open, and the remote's web URL.
