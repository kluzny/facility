---
name: dr_pepper
description: Audit code comments for accuracy, relevance, and necessity — flags comments that restate the code, drift from project conventions, or add no value beyond a plain reading.
when_to_use: Trigger after writing or editing code that includes comments, when reviewing a diff or file for comment quality, or when the user asks to check, audit, or clean up comments.
allowed-tools: Bash(git diff *) Bash(git status *) Bash(git branch *) Bash(git show-ref *) Read Edit Agent
---

**Announce at start:** "Running dr_pepper — auditing comments for relevance."

## Command Execution Policy

**Run freely (read-only):** `git diff`, `git status`, `git branch --show-current`, `git show-ref`, reading files, spawning the audit subagent.

**Require explicit user confirmation:** any `Edit` that removes or rewrites a comment.

## Phase 1 — Determine Scope

- If the user named specific files, a PR, or "this diff" — use that.
- Otherwise default to uncommitted changes:
  1. `git status --short` — check for any changes.
  2. If uncommitted changes exist, scope is diff mode against the working tree: `git diff HEAD`.
  3. If there are no uncommitted changes, scope is diff mode against the base branch:
     - `git branch --show-current` — current branch.
     - `git show-ref refs/heads/master refs/heads/main refs/heads/develop 2>/dev/null | head -1 | sed 's|.* refs/heads/||'` — base branch, fall back to `master` if empty.
     - Use `git diff <base>...HEAD`.
  4. If there is no diff either way (e.g. on the base branch with nothing to compare), ask the user which files or directory to audit — that becomes file mode.

## Phase 2 — Audit (subagent)

Read `~/.claude/agents/dr-pepper-audit.md` and spawn an Agent whose prompt is that file's full contents, with the resolved scope appended, e.g.:

```
## Scope for this run

Diff mode: `git diff HEAD`
```

or

```
## Scope for this run

File mode: src/foo.rb, src/bar.rb
```

The agent returns:

```json
{
  "findings": [
    { "file": "...", "line": 42, "comment": "...", "verdict": "remove", "reason": "...", "suggested_replacement": null }
  ]
}
```

If `findings` is empty, tell the user the audited comments held up and stop here.

## Phase 3 — Preview and Confirm

Group findings by verdict and show each one: file:line, the current comment, the reason, and (for `rewrite`) the suggested replacement.

Ask the user to choose:
- **Apply all** — apply every finding as proposed
- **Apply removals only** — apply `remove` findings, skip `rewrite`
- **Pick individually** — walk through each finding and accept/skip/edit the replacement
- **Cancel** — do nothing

Never edit a file until the user has confirmed which findings to apply.

## Phase 4 — Apply

For each accepted finding, use `Edit` on the exact file:line — delete the comment entirely for `remove`, or replace its text with `suggested_replacement` (or the user's edited version) for `rewrite`. Preserve the surrounding code untouched.

Report back a short summary: how many comments were removed, rewritten, and left as-is.
