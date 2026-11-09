---
name: GitHub CLI
description: Work with GitHub via the gh CLI — pull requests, issues, Actions workflows, releases, and more.
when_to_use: Triggered by requests to create, view, list, merge, review, or comment on GitHub pull requests or issues; check Actions/CI run status; clone or fork repos; create releases; open GitHub pages in the browser; or any gh CLI operation.
allowed-tools: Bash(gh *)
---

**Announce at start:** "I'm using the gh skill to..."

## Authentication

gh requires authentication with a GitHub account. If commands fail with auth errors:
1. Check status: `gh auth status`
2. Instruct the user to run `gh auth login` interactively — never attempt login on their behalf
3. For GitHub Enterprise: `gh auth login --hostname <host>`
4. Print current token (do not store or commit it): `gh auth token`

## Defaults

- PR/issue URL format: `https://github.com/<owner>/<repo>/pull/<number>` — always print after create operations
- Default repo: inferred from `git remote` in the current directory; override with `-R <owner>/<repo>`
- Default base branch: inferred from repo settings; override with `-B <branch>`
- JSON output: `--json <fields>` selects fields; `--jq <expr>` filters; `--template <tmpl>` uses Go templates

## Command Execution Policy

**Run freely (read-only):** `gh pr list`, `gh pr view`, `gh pr status`, `gh pr diff`, `gh issue list`, `gh issue view`, `gh issue status`, `gh run list`, `gh run view`, `gh run watch`, `gh repo view`, `gh release list`, `gh release view`, `gh gist list`, `gh gist view`, `gh auth status`, `gh api` with `GET`

**Require explicit user confirmation:**
- `gh pr create` — opens a pull request (visible to the repo)
- `gh pr merge` — merges a PR (irreversible once merged)
- `gh pr close` / `gh pr reopen` / `gh pr ready` — changes PR state
- `gh pr review --approve` / `--request-changes` — records a review (visible to others)
- `gh pr comment`, `gh issue comment` — posts a comment (visible to others)
- `gh issue create` — creates an issue
- `gh issue close` / `gh issue delete` — changes or removes an issue
- `gh run rerun`, `gh run cancel` — CI mutations
- `gh release create` / `gh release delete` — release operations
- `gh secret set` / `gh secret delete` — secret management
- `gh repo create` / `gh repo delete` / `gh repo fork` — repo-level operations

## Detailed Reference

- **Pull request flags and sub-commands** — [references/pr-commands.md](references/pr-commands.md)
- **Issues, Actions runs, repos, releases, secrets, and API** — [references/issue-repo-commands.md](references/issue-repo-commands.md)
