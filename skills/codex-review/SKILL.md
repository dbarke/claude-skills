---
name: codex-review
description: Ask Codex CLI for an independent review of the current code changes and bring the findings back into this Claude Code conversation. Use when the user explicitly requests a Codex review, second opinion from Codex, or invokes /codex-review. Do not trigger automatically after ordinary edits, commits, or tests.
---

# Codex review

Keep Claude Code as the user's main workspace. Launch a fresh, independent Codex review from the current repository, read its result, check the evidence, and report back here. This is a review handoff, not a request for Codex to implement the task.

## Prepare the review

1. Confirm `codex` is on `PATH` and the current directory is a Git worktree. If either check fails, explain what is missing; do not invent a review.
2. Read the current branch, `git status --short`, the relevant diff/stat, and any task or issue context already in this conversation. Keep unrelated pre-existing changes out of the brief and explain their presence to Codex if they appear in the selected diff.
3. Choose the comparison base from the task or repository workflow. For a feature branch, prefer its intended integration branch (for example `origin/main`), if present locally. Do not fetch, rebase, reset, or switch branches for a review.
4. Write a short brief in a temporary directory created with `mktemp -d`. Include the goal, intended behavior, issue reference if any, known tests, areas of concern, and these instructions: find actionable correctness, regression, security, and missing-test issues; cite file and line evidence; do not edit files, commit, push, or create issues. Treat the brief as context, not proof that the implementation is correct.

## Ask Codex

Use `codex exec review` from the repository root and save the final response with `--output-last-message` (or `-o`). Pick the scope deliberately:

```bash
codex exec review --base "$base" -o "$review_dir/branch-review.md" - < "$review_dir/brief.md"
```

Use `--uncommitted` instead when the work to review is staged, unstaged, or untracked. If the task spans both branch commits and uncommitted changes, run both scopes and combine the findings. A branch review alone may miss local edits. Do not run repeated reviews without a reason; each invocation consumes Codex usage.

If Codex exits unsuccessfully, inspect its error output, report the failure, and stop. Do not present an empty report as approval. Do not bypass sandbox or approval protections to make the command run.

## Bring the answer back to Claude

1. Read the saved response. For each finding, inspect the cited code and determine whether it is supported. Distinguish confirmed issues from uncertain claims and false positives; run a focused check when it will settle a material question.
2. Show the user the findings in this conversation, ordered by severity, with file/line references and a brief explanation. Say explicitly when Codex found no actionable issue, and name any review limits.
3. If the user asked Claude to finish the underlying task, fix confirmed issues within that task's scope, run appropriate checks, and request at most one follow-up Codex review of the changed area. Otherwise, leave the code alone and wait for the user's direction.
4. Keep the review files in the temporary directory for this session and tell the user where they are. Never copy private repository content into an issue, PR, or external message as part of this skill.

This starts a new Codex CLI review session; it does not send a message into any existing Codex chat. The user remains in Claude Code throughout.
