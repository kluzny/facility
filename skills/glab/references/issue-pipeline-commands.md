# GitLab CLI — Issues, Pipelines, Releases, Variables & More

Covers: issues, CI/CD pipelines, releases, CI/CD variables, snippets, and raw API access.

---

## `glab issue` — Issues

### `glab issue create`

```
glab issue create [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | Issue title |
| `-d, --description <text>` | Issue description |
| `-a, --assignee <username>` | Assign to user (repeatable) |
| `-l, --label <name>` | Add label (repeatable) |
| `-m, --milestone <id\|title>` | Set milestone |
| `-c, --confidential` | Mark as confidential |
| `--linked-mr <id>` | Link to a merge request |
| `--link-type <type>` | Link type: `relates_to`, `blocks`, `is_blocked_by` |
| `--no-editor` | Skip opening editor for description |
| `-w, --web` | Open creation form in browser |

### `glab issue list`

```
glab issue list [flags]
```

| Flag | Description |
|------|-------------|
| `-s, --state <state>` | `opened` (default), `closed`, `all` |
| `-l, --label <name>` | Filter by label (repeatable) |
| `-a, --author <username>` | Filter by author |
| `-A, --assignee <username>` | Filter by assignee |
| `-m, --milestone <id\|title>` | Filter by milestone |
| `-c, --confidential` | List confidential issues only |
| `-t, --type <type>` | `issue`, `incident`, `test_case` |
| `-i, --in <fields>` | Search in `title`, `description`, or `title,description` |
| `--limit <n>` | Max results (default 30) |
| `--page <n>` | Page number |
| `-o, --output <format>` | `text` or `json` |
| `-R, --repo <namespace/project>` | Target project |

### `glab issue view`

```
glab issue view <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-w, --web` | Open in browser |
| `--comments` | Show comments |
| `-o, --output <format>` | `text` or `json` |

### `glab issue note` — Add a Comment

```
glab issue note <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-m, --message <text>` | Comment body |
| `--unique` | Skip if identical note already exists |

### `glab issue update`

```
glab issue update <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | New title |
| `-d, --description <text>` | New description |
| `-a, --assignee <username>` | Set assignee (repeatable; `""` to unassign) |
| `-l, --label <name>` | Add label (repeatable) |
| `--remove-label <name>` | Remove label (repeatable) |
| `-m, --milestone <id>` | Set milestone (`0` to clear) |
| `--lock-discussion` | Lock discussion |
| `--unlock-discussion` | Unlock discussion |
| `--confidential` | Mark as confidential |
| `--public` | Remove confidential flag |

### Close / reopen / delete / subscribe

```bash
glab issue close <id>
glab issue reopen <id>
glab issue delete <id>           # permanent, always confirm
glab issue subscribe <id>
glab issue unsubscribe <id>
```

---

## `glab pipeline` / `glab ci` — CI/CD Pipelines

`glab ci` is an alias group for common pipeline operations. `glab pipeline` provides the full surface.

### `glab pipeline list`

```
glab pipeline list [flags]
```

| Flag | Description |
|------|-------------|
| `-s, --status <status>` | `created`, `waiting_for_resource`, `preparing`, `pending`, `running`, `success`, `failed`, `canceled`, `skipped`, `manual`, `scheduled` |
| `-b, --branch <branch>` | Filter by branch |
| `-u, --username <username>` | Filter by triggering user |
| `--limit <n>` | Max results (default 30) |
| `--page <n>` | Page number |
| `-o, --output <format>` | `text` or `json` |
| `-R, --repo <namespace/project>` | Target project |

### `glab pipeline view`

```
glab pipeline view [<id>] [flags]
```

If no ID given, shows the latest pipeline for the current branch.

| Flag | Description |
|------|-------------|
| `-b, --branch <branch>` | View latest pipeline on this branch |
| `-o, --output <format>` | `text` or `json` |

### `glab pipeline status`

```
glab pipeline status [<id>] [flags]
```

| Flag | Description |
|------|-------------|
| `-b, --branch <branch>` | Check latest pipeline on this branch |
| `--wait` | Block until pipeline finishes, then exit with its status |
| `--live` | Stream status updates (alternative to `--wait`) |

### `glab pipeline trace` — Stream Job Logs

```
glab pipeline trace [<job-id>] [flags]
```

If no job ID given, shows an interactive picker of jobs in the latest pipeline.

| Flag | Description |
|------|-------------|
| `-b, --branch <branch>` | Look up jobs from pipeline on this branch |
| `-R, --repo <namespace/project>` | Target project |

Alias: `glab ci trace [<job-id>]`

### `glab ci view` — Interactive TUI

```
glab ci view [flags]
```

Opens a terminal UI showing pipeline stages and jobs, with the ability to stream logs.

| Flag | Description |
|------|-------------|
| `-b, --branch <branch>` | View pipeline for this branch |
| `-R, --repo <namespace/project>` | Target project |

### `glab pipeline run` — Trigger a Pipeline

```
glab pipeline run [flags]
```

| Flag | Description |
|------|-------------|
| `-b, --branch <branch>` | Run pipeline on this branch (default: current) |
| `-v, --variables <key=value>` | Pipeline variable (repeatable) |
| `-V, --variables-file <file>` | Load variables from file (JSON or YAML) |
| `--ref <ref>` | Git ref to run on |
| `-R, --repo <namespace/project>` | Target project |

### `glab pipeline retry`

```
glab pipeline retry <id> [flags]
```

Retries all failed jobs in the pipeline.

### `glab pipeline delete`

```
glab pipeline delete <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-s, --status <status>` | Delete all pipelines with this status |
| `-R, --repo <namespace/project>` | Target project |

### Examples

```bash
# Watch the pipeline on the current branch
glab ci view

# Stream logs for the failing job (interactive picker)
glab pipeline trace

# Trigger a pipeline with variables
glab pipeline run -b main -v "DEPLOY_ENV=staging" -v "SKIP_TESTS=false"

# Wait until the pipeline finishes (useful in scripts)
glab pipeline status --wait -b main

# Delete all failed pipelines
glab pipeline delete --status failed
```

---

## `glab release` — Releases

### `glab release create`

```
glab release create <tag> [<files>...] [flags]
```

| Flag | Description |
|------|-------------|
| `-n, --notes <text>` | Release notes |
| `-F, --notes-file <file>` | Read notes from file |
| `--ref <branch\|sha>` | Git ref to tag (default: default branch) |
| `--milestone <title>` | Link to milestone (repeatable) |
| `--asset-link <json>` | Add asset link as JSON `{"name":"…","url":"…","type":"…"}` |
| `--released-at <date>` | Override release date (ISO 8601) |

### Other release sub-commands

```bash
glab release list [--limit n] [-o json]
glab release view <tag> [-w]
glab release download <tag> [-p <glob>] [-D <dir>] [-a <asset-name>]
glab release upload <tag> <file> [--name <n>] [--type package|runbook|image|other]
glab release delete <tag> [--with-tag]
glab release edit <tag> [--name <n>] [--notes <t>] [--released-at <date>]
```

---

## `glab variable` — CI/CD Variables

### `glab variable list`

```
glab variable list [flags]
```

| Flag | Description |
|------|-------------|
| `-g, --group <name>` | Target a group instead of a project |
| `-e, --env-scope <scope>` | Filter by environment scope |
| `--page <n>`, `--per-page <n>` | Pagination |
| `-R, --repo <namespace/project>` | Target project |

### `glab variable set`

```
glab variable set <name> [flags]
```

| Flag | Description |
|------|-------------|
| `-v, --value <text>` | Variable value (reads from stdin if omitted) |
| `-t, --type <type>` | `env_var` (default) or `file` |
| `-p, --protected` | Only expose on protected branches/tags |
| `-m, --masked` | Mask value in job logs (must meet masking rules) |
| `-r, --raw` | Store as raw (no variable expansion) |
| `-e, --scope <env>` | Environment scope (default `*` — all) |
| `-g, --group <name>` | Set at group level instead of project |
| `-R, --repo <namespace/project>` | Target project |

### `glab variable delete`

```
glab variable delete <name> [flags]
```

| Flag | Description |
|------|-------------|
| `-e, --scope <env>` | Environment scope to delete |
| `-g, --group <name>` | Delete from group |
| `-R, --repo <namespace/project>` | Target project |

### `glab variable get`

```
glab variable get <name> [flags]
```

| Flag | Description |
|------|-------------|
| `-e, --scope <env>` | Environment scope |
| `-g, --group <name>` | Get from group |
| `-o, --output <format>` | `text` or `json` |

### Examples

```bash
# List all project variables
glab variable list

# Set a masked, protected variable
glab variable set DEPLOY_KEY -v "abc123" --masked --protected

# Set a file-type variable
glab variable set KUBECONFIG -v "$(cat ~/.kube/config)" --type file

# Set for a specific environment
glab variable set API_URL -v "https://staging.example.com" --scope staging

# Delete a variable
glab variable delete OLD_SECRET
```

---

## `glab snippet` — Snippets

```bash
glab snippet list [--limit n] [--visibility public|internal|private|all]
glab snippet view <id> [-w]
glab snippet create [--title t] [--description d] [--filename f] [--visibility v]
glab snippet delete <id>
```

---

## `glab api` — Raw REST API

```
glab api <endpoint> [flags]
```

`:fullpath` in endpoint URLs is replaced with the current project's namespace/project path.

| Flag | Description |
|------|-------------|
| `-X, --method <method>` | HTTP method (default `GET`) |
| `-f, --field <key=val>` | Request field — string or JSON (repeatable) |
| `-H, --header <key:val>` | Add request header (repeatable) |
| `--input <file>` | Read request body from file (`-` for stdin) |
| `--paginate` | Fetch all pages automatically |
| `--jq <expr>` | Filter JSON output with jq |
| `--silent` | Suppress output |
| `--hostname <host>` | Target a specific GitLab hostname |

### Examples

```bash
# List MRs
glab api projects/:fullpath/merge_requests

# List pipelines, extract IDs
glab api --paginate projects/:fullpath/pipelines --jq '.[].id'

# Get current user
glab api /user

# Create an issue
glab api projects/:fullpath/issues -X POST \
  -f title="Bug report" \
  -f description="Detailed steps..." \
  -f labels="bug,backend"

# Trigger a pipeline with variables
glab api projects/:fullpath/pipeline -X POST \
  -f ref="main" \
  -f "variables[][key]=MY_VAR" \
  -f "variables[][value]=hello"

# Get a specific merge request
glab api projects/:fullpath/merge_requests/123
```

Refer to https://docs.gitlab.com/ee/api/rest/ for the full REST API reference.
