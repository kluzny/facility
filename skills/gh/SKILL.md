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

## Quick Reference

### Pull Requests

```bash
# Status overview (your PRs + review requests)
gh pr status

# List
gh pr list
gh pr list -s all --limit 20
gh pr list -a "@me" -l bug -B main

# View / diff
gh pr view 123
gh pr view 123 -w                   # open in browser
gh pr diff 123

# Check out a PR branch locally
gh pr checkout 123

# Create (from current branch)
gh pr create -t "Fix login timeout" -b "Resolves #456"
gh pr create --draft -t "WIP: auth refactor"
gh pr create --fill                  # use commit title/body

# Review
gh pr review 123 --approve
gh pr review 123 --request-changes -b "Please fix the null check"
gh pr review 123 --comment -b "One nit, otherwise LGTM"

# Merge
gh pr merge 123 --squash --delete-branch
gh pr merge 123 --rebase
gh pr merge --auto --squash          # auto-merge once checks pass

# Comment / edit
gh pr comment 123 -b "Merging after the deploy window"
gh pr edit 123 -t "New title" -l "priority:high" -r alice

# Convert draft → ready
gh pr ready 123
```

### Issues

```bash
# Status overview
gh issue status

# List
gh issue list
gh issue list -s closed --limit 10
gh issue list -l bug -a "@me"

# View
gh issue view 42
gh issue view 42 -w                 # open in browser

# Create
gh issue create -t "Null pointer in auth" -b "Steps to reproduce..."
gh issue create -w                   # open creation form in browser

# Comment / close / reopen
gh issue comment 42 -b "Can reproduce on v2.3"
gh issue close 42 -c "Fixed in #123"
gh issue reopen 42

# Edit
gh issue edit 42 -t "Updated title" -l "bug,p1" -a "@me"
```

### Actions / CI Runs

```bash
# List recent runs
gh run list
gh run list --workflow ci.yml -b main --status failure --limit 10

# View a run
gh run view 987654321
gh run view 987654321 -w             # open in browser
gh run view --log 987654321          # print full logs
gh run view --log-failed 987654321   # only failed job logs

# Stream logs live
gh run watch 987654321

# Re-run
gh run rerun 987654321 --failed-only
gh run cancel 987654321
```

### Repos

```bash
gh repo clone owner/repo
gh repo fork owner/repo --clone      # fork + clone in one step
gh repo view owner/repo
gh repo view -w                      # open current repo in browser
```

### Browse

```bash
gh browse                            # open repo root in browser
gh browse 123                        # open issue or PR #123
gh browse src/main.go                # open file in browser
gh browse --branch feature-x         # open a specific branch
```

### Releases

```bash
gh release list
gh release view v1.2.0
gh release create v1.3.0 dist/*.tar.gz -t "v1.3.0" -n "Release notes"
gh release create v1.3.0 --generate-notes --target main
gh release download v1.2.0 -p "*.tar.gz" -D ./downloads
```

### Raw API Access

```bash
gh api repos/{owner}/{repo}/pulls
gh api /user
gh api --paginate /repos/{owner}/{repo}/issues --jq '.[].title'
gh api graphql -f query='{ viewer { login } }'
gh api /repos/{owner}/{repo}/issues -X POST -f title="Bug" -f body="Details"
```

## Detailed Reference

- **Pull request flags and sub-commands** — [references/pr-commands.md](references/pr-commands.md)
- **Issues, Actions runs, repos, releases, secrets, and API** — [references/issue-repo-commands.md](references/issue-repo-commands.md)
