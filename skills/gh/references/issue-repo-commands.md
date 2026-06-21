# GitHub CLI — Issues, Runs, Repos, Releases & More

Covers: issues, Actions runs, repos, releases, gists, secrets, and raw API access.

---

## `gh issue` — Issues

### `gh issue create`

```
gh issue create [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | Issue title |
| `-b, --body <text>` | Issue body |
| `-F, --body-file <file>` | Read body from file |
| `-a, --assignee <login>` | Assign to user (`@me`) (repeatable) |
| `-l, --label <name>` | Add label (repeatable) |
| `-m, --milestone <name>` | Set milestone |
| `-p, --project <name>` | Add to project |
| `-w, --web` | Open creation form in browser |
| `-e, --editor` | Open editor to write body |

### `gh issue list`

```
gh issue list [flags]
```

| Flag | Description |
|------|-------------|
| `-s, --state <state>` | `open` (default), `closed`, `all` |
| `-l, --label <name>` | Filter by label (repeatable) |
| `-a, --author <login>` | Filter by author |
| `-A, --assignee <login>` | Filter by assignee |
| `-m, --milestone <name>` | Filter by milestone |
| `-S, --search <query>` | GitHub search syntax |
| `--limit <n>` | Max results (default 30) |
| `--json <fields>` | JSON output |
| `--jq <expr>` | Filter JSON |
| `--template <tmpl>` | Go template |
| `-w, --web` | Open in browser |

### `gh issue view`

```
gh issue view <number>|<url> [flags]
```

| Flag | Description |
|------|-------------|
| `-w, --web` | Open in browser |
| `--comments` | Include comments in output |
| `--json <fields>` | JSON output |
| `--jq <expr>` | Filter JSON |

### `gh issue comment`

```
gh issue comment <number>|<url> [flags]
```

| Flag | Description |
|------|-------------|
| `-b, --body <text>` | Comment body |
| `-F, --body-file <file>` | Read body from file |
| `--edit-last` | Edit your most recent comment |
| `--delete-last` | Delete your most recent comment |
| `-e, --editor` | Open editor to write body |

### `gh issue edit`

```
gh issue edit <number>|<url> [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | New title |
| `-b, --body <text>` | New body |
| `-F, --body-file <file>` | Read body from file |
| `--add-assignee <login>` | Add assignee (repeatable) |
| `--remove-assignee <login>` | Remove assignee (repeatable) |
| `--add-label <name>` | Add label (repeatable) |
| `--remove-label <name>` | Remove label (repeatable) |
| `--add-project <name>` | Add to project (repeatable) |
| `--remove-project <name>` | Remove from project (repeatable) |
| `-m, --milestone <name>` | Set milestone (`""` to clear) |

### Close / reopen / delete

```bash
gh issue close <number> [-c "Fixed in #123"] [--reason "completed"|"not planned"]
gh issue reopen <number> [-c "Reopening for regression"]
gh issue delete <number> --yes       # permanent, always confirm
gh issue transfer <number> <repo>    # move to another repo
gh issue pin <number>
gh issue unpin <number>
```

### `gh issue status`

Shows: issues assigned to you, mentioning you, and opened by you.

---

## `gh run` — Actions Workflow Runs

### `gh run list`

```
gh run list [flags]
```

| Flag | Description |
|------|-------------|
| `--workflow <name\|id\|file>` | Filter by workflow file name |
| `-b, --branch <branch>` | Filter by branch |
| `-u, --user <login>` | Filter by triggering user |
| `-e, --event <event>` | Filter by trigger event (`push`, `pull_request`, etc.) |
| `-s, --status <status>` | `queued`, `in_progress`, `completed`, `success`, `failure`, `cancelled`, `skipped`, etc. |
| `-c, --commit <sha>` | Filter by commit SHA |
| `--limit <n>` | Max results (default 20) |
| `--json <fields>` | JSON output |
| `--jq <expr>` | Filter JSON |
| `--created <date>` | Filter by created date (`>2026-01-01`) |

### `gh run view`

```
gh run view [<run-id>] [flags]
```

| Flag | Description |
|------|-------------|
| `--log` | Print full logs for all jobs |
| `--log-failed` | Print logs for failed jobs only |
| `--exit-status` | Exit with non-zero if run failed |
| `--job <id>` | View a specific job by ID |
| `-w, --web` | Open in browser |
| `--json <fields>` | JSON output |
| `--jq <expr>` | Filter JSON |
| `--verbose` | Show steps within jobs |

### `gh run watch`

```
gh run watch [<run-id>] [flags]
```

| Flag | Description |
|------|-------------|
| `--exit-status` | Exit with non-zero if run fails |
| `--interval <n>` | Polling interval in seconds (default 3) |

### `gh run rerun`

```
gh run rerun [<run-id>] [flags]
```

| Flag | Description |
|------|-------------|
| `--failed-only` | Only re-run failed jobs |
| `--job <id>` | Re-run a specific job |
| `-d, --debug` | Enable debug logging for the re-run |

### `gh run cancel`

```
gh run cancel [<run-id>]
```

Cancels an in-progress run. Uses current branch's run if no ID given.

### `gh run download`

```
gh run download [<run-id>] [flags]
```

| Flag | Description |
|------|-------------|
| `-n, --name <name>` | Artifact name to download (repeatable) |
| `-D, --dir <path>` | Destination directory (default `.`) |
| `-p, --pattern <glob>` | Filename pattern filter |
| `-R, --repo <owner/repo>` | Target repo |

### Examples

```bash
# All failing runs on main
gh run list --status failure -b main

# View logs for the latest run on this branch
gh run view --log

# Watch a specific run
gh run watch 987654321 --exit-status

# Re-run only failed jobs with debug logging
gh run rerun 987654321 --failed-only --debug

# Download artifacts named "test-results"
gh run download 987654321 -n test-results -D ./artifacts
```

---

## `gh repo` — Repositories

### Common sub-commands

```bash
gh repo clone <owner/repo> [-- <git-flags>]
gh repo fork [<owner/repo>] [--clone] [--remote] [--org <org>] [--fork-name <name>]
gh repo view [<owner/repo>] [-w] [-b <branch>] [--json <fields>]
gh repo list [<owner>] [--limit n] [--fork] [--source] [--archived]
gh repo sync [<owner/repo>] [-b <branch>] [--force]
gh repo rename [<new-name>]
gh repo archive
gh repo unarchive
gh repo delete <owner/repo> --yes
```

### `gh repo create`

```
gh repo create [<name>] [flags]
```

| Flag | Description |
|------|-------------|
| `--public` / `--private` / `--internal` | Visibility |
| `-c, --clone` | Clone after creation |
| `-d, --description <text>` | Repository description |
| `-h, --homepage <url>` | Homepage URL |
| `-g, --gitignore <template>` | Gitignore template to apply |
| `-l, --license <spdx>` | License template |
| `-p, --template <owner/repo>` | Create from a template repo |
| `--push` | Push local commits after creation |
| `--source <path>` | Local directory to use as source |
| `--remote <name>` | Remote name for `--source` (default: `origin`) |
| `--disable-issues` | Disable issues |
| `--disable-wiki` | Disable wiki |
| `--include-all-branches` | Copy all branches from template |
| `--add-readme` | Add a README file |

---

## `gh release` — Releases

### `gh release create`

```
gh release create [<tag>] [<files>...] [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | Release title (defaults to tag name) |
| `-n, --notes <text>` | Release notes text |
| `-F, --notes-file <file>` | Read notes from file (`-` for stdin) |
| `--generate-notes` | Auto-generate notes from merged PRs |
| `--notes-start-tag <tag>` | Start point for generated notes |
| `-d, --draft` | Save as draft |
| `-p, --prerelease` | Mark as pre-release |
| `--target <branch\|sha>` | Target commitish (default: default branch) |
| `--discussion-category <name>` | Link to a Discussions category |
| `--verify-tag` | Abort if the tag doesn't exist |
| `--latest` / `--no-latest` | Control "latest release" flag |

### Other release sub-commands

```bash
gh release list [--limit n] [--exclude-pre-releases] [--exclude-drafts] [--json <fields>]
gh release view <tag> [-w] [--json <fields>]
gh release download <tag> [-p <glob>] [-D <dir>] [-A <format>]
gh release upload <tag> <files...> [--clobber]
gh release delete <tag> [--yes] [--cleanup-tag]
gh release edit <tag> [--draft] [--prerelease] [--title <t>] [--notes <n>] [--tag <new-tag>]
```

---

## `gh gist` — Gists

```bash
gh gist list [--limit n] [--public] [--secret]
gh gist view <id\|url> [-w] [-r]              # -r: raw content only
gh gist create [<files>] [-d desc] [-p] [-f filename]
gh gist edit <id\|url> [-f filename] [-d desc]
gh gist clone <id\|url>
gh gist delete <id\|url>
```

`-p` / `--public` makes the gist public (default: secret).

---

## `gh secret` — Secrets

```bash
gh secret list [-a app] [-e env] [-R repo] [--org <org>]
gh secret set <name> [-b value] [-a app] [-e env] [--org <org>] [--repos <list>] [--visibility all|private|selected]
gh secret delete <name> [-a app] [-e env] [--org <org>]
```

`-a / --app`: `actions` (default), `codespaces`, `dependabot`

Pipe value via stdin: `echo "mytoken" | gh secret set MY_TOKEN`

---

## `gh api` — Raw REST / GraphQL

```
gh api <endpoint> [flags]
```

Use `{owner}` / `{repo}` as placeholders — gh substitutes from current git context.

| Flag | Description |
|------|-------------|
| `-X, --method <method>` | HTTP method (default `GET`) |
| `-f, --raw-field <key=val>` | String field — always sends as string (repeatable) |
| `-F, --field <key=val>` | Typed field — parses numbers, booleans, JSON (repeatable) |
| `-H, --header <key:val>` | Add request header (repeatable) |
| `--input <file>` | Read request body from file (`-` for stdin) |
| `--paginate` | Fetch all pages automatically |
| `--jq <expr>` | Filter output with jq |
| `--template <tmpl>` | Render with Go template |
| `--cache <duration>` | Cache GET response for duration (e.g. `1h`) |
| `--hostname <host>` | Target a specific GitHub hostname |
| `--include` | Include response headers in output |
| `-q, --silent` | Suppress output |

### GraphQL

```bash
gh api graphql -f query='
  query($owner:String!, $repo:String!) {
    repository(owner:$owner, name:$repo) {
      pullRequests(first:5, states:OPEN) {
        nodes { number title }
      }
    }
  }
' -f owner="{owner}" -f repo="{repo}"
```

### Examples

```bash
# List open PRs as JSON
gh api /repos/{owner}/{repo}/pulls

# Paginate all issues and extract titles
gh api --paginate /repos/{owner}/{repo}/issues --jq '.[].title'

# Create an issue
gh api /repos/{owner}/{repo}/issues -X POST -f title="Bug" -f body="Details" -f '["labels"]=["bug"]'

# Add a label to a PR
gh api /repos/{owner}/{repo}/issues/123/labels -X POST -F '["labels"]=["priority:high"]'

# Get rate limit status
gh api /rate_limit
```
