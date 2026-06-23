---
description: Stage changes and commit with a drafted single-line message. Works with any git remote.
disable-model-invocation: true
allowed-tools: Bash(git *)
---

**Announce at start:** "Running /commit — checking staged and unstaged changes."

## Gather Context

Run the following before doing anything else:

1. `git status --short` — see all staged and unstaged changes
2. `git diff --cached --stat` — staged files and their change counts

## Handle Unstaged Changes

If `git status --short` shows unstaged changes (lines starting with a space or `?`):

Ask the user to choose one of:
- **Stage all tracked** — run `git add -u`
- **Stage specific files** — ask which files, then run `git add <files>`
- **Proceed with staged only** — skip unstaged changes entirely

Do not run any `git add` command without the user's explicit choice.

## Draft the Commit Message

Run `git diff --cached` to read the full staged diff, then draft a message:

- **Default: single line**, imperative mood, ≤72 characters (e.g. `fix login timeout on session expiry`)
- Only offer a multi-line message (subject + blank line + body) when the diff clearly spans multiple unrelated concerns or includes a breaking change — and even then, confirm with the user first
- Match the capitalisation and punctuation style of recent commits in the repo (`git log --oneline -10`)

## Preview and Confirm

Show:
1. The proposed commit message (verbatim, in a code block)
2. The list of files being committed

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
