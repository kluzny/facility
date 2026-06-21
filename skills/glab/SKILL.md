---
name: GitLab CLI
description: Work with GitLab via the glab CLI — merge requests, issues, CI/CD pipelines, releases, and more.
when_to_use: Triggered by requests to create, view, list, merge, approve, or comment on GitLab merge requests or issues; check pipeline/CI job status or stream logs; clone or fork projects; create releases; open GitLab pages in the browser; or any glab CLI operation.
allowed-tools: Bash(glab *)
---

**Announce at start:** "I'm using the glab skill to..."

## Authentication

glab requires authentication with a GitLab account. If commands fail with auth errors:
1. Check status: `glab auth status`
2. Instruct the user to run `glab auth login` interactively — never attempt login on their behalf
3. For self-hosted instances: `glab auth login --hostname gitlab.example.com`
4. Token env vars (never store or commit): `GITLAB_TOKEN` or `OAUTH_TOKEN`

## Defaults

- MR URL format: `https://gitlab.com/<namespace>/<project>/-/merge_requests/<id>` — always print after create operations
- Default project: inferred from `git remote` in the current directory; override with `-R <namespace/project>`
- Default MR target branch: the project's default branch; override with `-b <branch>`
- MR source branch: the current branch; override with `-s <branch>`

## Command Execution Policy

**Run freely (read-only):** `glab mr list`, `glab mr view`, `glab mr diff`, `glab mr status`, `glab issue list`, `glab issue view`, `glab pipeline list`, `glab pipeline view`, `glab pipeline status`, `glab ci view`, `glab ci list`, `glab repo view`, `glab release list`, `glab release view`, `glab variable list`, `glab auth status`, `glab api` with `GET`

**Require explicit user confirmation:**
- `glab mr create` — opens a merge request (visible to the project)
- `glab mr merge` — merges an MR (irreversible once merged)
- `glab mr approve` / `glab mr revoke` — records an approval (visible to others)
- `glab mr close` / `glab mr reopen` — changes MR state
- `glab mr note`, `glab issue note` — posts a comment (visible to others)
- `glab issue create` — creates an issue
- `glab issue close` / `glab issue delete` — changes or removes an issue
- `glab pipeline run` / `glab pipeline retry` / `glab pipeline delete` — pipeline mutations
- `glab release create` / `glab release delete` — release operations
- `glab variable set` / `glab variable delete` — CI/CD variable management
- `glab repo fork` — forks a project

## Quick Reference

### Merge Requests

```bash
# Status overview
glab mr status

# List
glab mr list
glab mr list -s all --limit 20
glab mr list -a "@me" -l bug

# View / diff
glab mr view 123
glab mr view 123 -w                  # open in browser
glab mr diff 123

# Check out an MR branch locally
glab mr checkout 123

# Create (from current branch)
glab mr create -t "Fix login timeout" -d "Resolves #456"
glab mr create --draft -t "WIP: auth refactor"
glab mr create --fill                 # use commit title/body as description
glab mr create --push                 # push current branch then open MR

# Approve / revoke approval
glab mr approve 123
glab mr revoke 123

# Merge
glab mr merge 123 --squash --remove-source-branch
glab mr merge 123 --rebase
glab mr merge 123 --when-pipeline-succeeds

# Comment / update
glab mr note 123 -m "Merging after the deploy window"
glab mr update 123 -t "New title" -l "priority::high"

# Subscribe for notifications
glab mr subscribe 123
glab mr unsubscribe 123
```

### Issues

```bash
# List
glab issue list
glab issue list -s closed --limit 10
glab issue list -l bug -a "@me"

# View
glab issue view 42
glab issue view 42 -w                # open in browser

# Create
glab issue create -t "Null pointer in auth" -d "Steps to reproduce..."
glab issue create -w                  # open creation form in browser

# Comment / close / reopen
glab issue note 42 -m "Can reproduce on v2.3"
glab issue close 42
glab issue reopen 42

# Edit
glab issue update 42 -t "Updated title" -l "bug"
```

### CI/CD Pipelines

```bash
# List pipelines
glab pipeline list
glab pipeline list -b main --status failed --limit 10

# View pipeline details
glab pipeline view 12345
glab pipeline view -b main            # latest pipeline on a branch

# Stream job logs (interactive picker if no job ID given)
glab pipeline trace
glab pipeline trace <job-id>

# Interactive TUI
glab ci view
glab ci view -b main

# Trigger a new pipeline
glab pipeline run
glab pipeline run -b main -v "KEY=value"

# Retry / delete
glab pipeline retry 12345
glab pipeline delete 12345
```

### Repos / Projects

```bash
glab repo clone namespace/project
glab repo fork namespace/project --clone   # fork + clone in one step
glab repo view
glab repo view -w                          # open current project in browser
```

### Browse

```bash
glab browse                               # open project root in browser
glab browse -b feature-x                  # open a specific branch
glab browse 42                            # open issue #42
```

### Releases

```bash
glab release list
glab release view v1.2.0
glab release create v1.3.0 dist/*.tar.gz -n "Release notes" --ref main
glab release download v1.2.0 -p "*.tar.gz" -D ./downloads
```

### CI/CD Variables

```bash
glab variable list
glab variable set MY_TOKEN -v "abc123" --masked --protected
glab variable delete MY_TOKEN
```

### Raw API Access

```bash
glab api projects/:fullpath/merge_requests
glab api /user
glab api --paginate projects/:fullpath/pipelines --jq '.[].id'
glab api projects/:fullpath/issues -X POST -f title="Bug" -f description="Details"
```

`:fullpath` is replaced by glab with the current project's namespace/project path.

## Detailed Reference

- **Merge request flags and sub-commands** — [references/mr-commands.md](references/mr-commands.md)
- **Issues, pipelines, releases, variables, snippets, and API** — [references/issue-pipeline-commands.md](references/issue-pipeline-commands.md)
