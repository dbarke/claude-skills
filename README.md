# claude-skills

Personal [Claude Code](https://claude.com/claude-code) skills, kept generic enough
for anyone to use.

| Skill | What it does |
|---|---|
| [`handoff`](skills/handoff/SKILL.md) | Writes the current session into a resumable handoff file (`docs/handoffs/<lane>.md`) with next actions, evidence, blockers and deliberate non-decisions, so a fresh session can continue. Supports several named lanes. |
| [`pickup`](skills/pickup/SKILL.md) | The other half: loads a handoff, checks how far the repo has drifted since it was written, surfaces the load-bearing sections and starts on the next action. |
| [`codex-review`](skills/codex-review/SKILL.md) | Asks Codex CLI for an independent code review on request and brings its findings back into Claude Code. Requires Codex CLI to be installed and signed in. |
| [`sync-omarchy-config`](skills/sync-omarchy-config/SKILL.md) | For [Omarchy](https://omarchy.org/) users: keeps a bare git repo of your desktop customizations up to date. A read-only [`scan.sh`](skills/sync-omarchy-config/scan.sh) finds changed and newly customized files (Hyprland overrides, shell bar, toggles, workspace layouts, scripts, user units, plugin drift); the skill triages them, blocks secrets, maintains a restore script and pushes. Can bootstrap the repo on first run. |

## Install

```bash
git clone https://github.com/dbarke/claude-skills.git
cd claude-skills
./install.sh                 # symlink all skills into ~/.claude/skills
./install.sh handoff pickup  # or only some
```

Symlinks mean `git pull` updates the skills in place. Existing skills with the same
name are never overwritten. Prefer copies? Copy `skills/<name>/` into
`~/.claude/skills/` (user-wide) or `.claude/skills/` (one project) instead.

Then invoke a skill with `/<name>` in Claude Code, or just describe the task and
Claude picks the matching skill.

## Layout

```
skills/<name>/SKILL.md   # frontmatter (name, description, tools) + instructions
skills/<name>/*          # any helper scripts the skill runs
```

## License

MIT
