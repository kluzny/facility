---
description: Stage changes and commit with a drafted single-line message. Works with any git remote.
disable-model-invocation: true
allowed-tools: Bash(git *) Agent
---

**Announce at start:** "Running /commit — checking staged and unstaged changes."

## Phase 1 — Handle Staging

Run `git status --short` to see all changes.

If unstaged changes exist (lines starting with a space or `?`), ask the user to choose:
- **Stage all tracked** — run `git add -u`
- **Stage specific files** — ask which files, then run `git add <files>`
- **Proceed with staged only** — skip unstaged changes entirely

Do not run any `git add` command without the user's explicit choice.

## Phase 2 — Draft (subagent)

Once staging is resolved, read `agents/git-draft-commit.md` and spawn an Agent with its full contents as the prompt.

The agent returns a JSON object:

```json
{
  "staged_files": ["path/to/file"],
  "proposed_message": "imperative mood message",
  "concerns": []
}
```

## Phase 3 — Preview and Confirm

Show:
1. The proposed commit message (verbatim, in a code block)
2. The list of staged files
3. Any concerns the agent flagged — if present, ask whether to proceed or revise before offering the actions below

Then ask the user to choose:
- **Commit** — run `git commit -m "<message>"`
- **Edit message** — accept a revised message from the user, then commit
- **Cancel** — do nothing

Never run `git commit` until the user explicitly selects Commit or Edit message.

## Constraints

- Never use `--no-verify`
- Never use `--amend` unless the user explicitly requests it
- Never run `git add -A` or `git add .`
- Never commit without explicit user confirmation
