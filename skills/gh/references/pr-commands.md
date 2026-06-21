# GitHub CLI — Pull Request Commands Reference

## `gh pr create` — Open a Pull Request

```
gh pr create [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | PR title |
| `-b, --body <text>` | PR body text |
| `-F, --body-file <file>` | Read body from file (`-` for stdin) |
| `-B, --base <branch>` | Base branch (default: repo default) |
| `-H, --head <branch>` | Head branch (default: current branch) |
| `-d, --draft` | Mark as draft |
| `-w, --web` | Open browser to finish creation |
| `--fill` | Use first commit title/body as PR title/body |
| `--fill-first` | Use first commit message only |
| `--fill-verbose` | Include all commit messages in body |
| `-r, --reviewer <login>` | Request review from user or team (repeatable) |
| `-a, --assignee <login>` | Assign to user — `@me` for yourself (repeatable) |
| `-l, --label <name>` | Add label (repeatable) |
| `-m, --milestone <name>` | Set milestone |
| `-p, --project <name>` | Add to project |
| `--no-maintainer-edit` | Disable maintainer edit permission |
| `-e, --editor` | Open editor to write title/body |
| `--recover <file>` | Recover from failed PR create |

### Examples

```bash
# Basic
gh pr create -t "Fix null pointer in auth" -b "Resolves #42"

# Draft with reviewers
gh pr create --draft -t "WIP: OAuth refactor" -r alice -r backend-team

# From commit messages
gh pr create --fill

# Target a specific base
gh pr create -t "Hotfix" -B release/v2 -b "Cherry-pick of abc1234"
```

---

## `gh pr list` — List Pull Requests

```
gh pr list [flags]
```

| Flag | Description |
|------|-------------|
| `-s, --state <state>` | `open` (default), `closed`, `merged`, `all` |
| `-l, --label <name>` | Filter by label (repeatable) |
| `-a, --author <login>` | Filter by author (`@me` for yourself) |
| `-A, --assignee <login>` | Filter by assignee |
| `-B, --base <branch>` | Filter by base branch |
| `-H, --head <branch>` | Filter by head branch |
| `-S, --search <query>` | GitHub search syntax (`is:pr is:open label:bug`) |
| `--draft` | Filter to drafts only |
| `--limit <n>` | Max results (default 30) |
| `--json <fields>` | Output as JSON with these fields |
| `--jq <expr>` | Filter JSON output with jq expression |
| `--template <tmpl>` | Render with Go template |
| `-w, --web` | Open in browser |

### JSON fields (common)

`number`, `title`, `state`, `author`, `assignees`, `reviewRequests`, `labels`, `baseRefName`, `headRefName`, `url`, `createdAt`, `updatedAt`, `mergedAt`, `isDraft`, `mergeable`, `reviewDecision`, `statusCheckRollup`

### Examples

```bash
# Open PRs targeting main
gh pr list -B main

# My open PRs
gh pr list -a "@me"

# PRs needing my review
gh pr list --search "review-requested:@me"

# JSON: list title + URL
gh pr list --json number,title,url --jq '.[] | "\(.number)\t\(.title)\t\(.url)"'
```

---

## `gh pr view` — View a Pull Request

```
gh pr view [<number>|<url>|<branch>] [flags]
```

If no argument is given, uses the PR associated with the current branch.

| Flag | Description |
|------|-------------|
| `-w, --web` | Open in browser |
| `--comments` | Include comments in output |
| `--json <fields>` | Output as JSON |
| `--jq <expr>` | Filter JSON |
| `--template <tmpl>` | Go template output |

---

## `gh pr diff` — Show PR Diff

```
gh pr diff [<number>|<url>|<branch>] [flags]
```

| Flag | Description |
|------|-------------|
| `--color <when>` | `always`, `never`, `auto` |
| `--patch` | Output in patch format |
| `--name-only` | Only list changed file names |

---

## `gh pr checkout` — Check Out a PR Locally

```
gh pr checkout <number>|<url>|<branch> [flags]
```

| Flag | Description |
|------|-------------|
| `-b, --branch <name>` | Local branch name to use |
| `--detach` | Check out in detached HEAD state |
| `-f, --force` | Overwrite local changes |
| `--recurse-submodules` | Update submodules after checkout |

---

## `gh pr review` — Submit a Review

```
gh pr review [<number>|<url>|<branch>] [flags]
```

| Flag | Description |
|------|-------------|
| `-a, --approve` | Approve the PR |
| `-r, --request-changes` | Request changes |
| `-c, --comment` | Leave a comment review (no approval decision) |
| `-b, --body <text>` | Review body text |
| `-F, --body-file <file>` | Read body from file |

---

## `gh pr merge` — Merge a Pull Request

```
gh pr merge [<number>|<url>|<branch>] [flags]
```

| Flag | Description |
|------|-------------|
| `--merge` | Merge commit (default if no strategy given) |
| `--squash` | Squash and merge |
| `--rebase` | Rebase and merge |
| `-d, --delete-branch` | Delete head branch after merge |
| `--auto` | Enable auto-merge (merges when all checks pass) |
| `--disable-auto` | Disable auto-merge |
| `--admin` | Use admin privileges to bypass required reviews |
| `-b, --body <text>` | Merge commit body |
| `-F, --body-file <file>` | Read body from file |
| `-s, --subject <text>` | Merge commit subject (squash only) |
| `-t, --title <text>` | Merge commit title |

### Examples

```bash
gh pr merge 123 --squash --delete-branch
gh pr merge --auto --squash          # for current branch's PR
gh pr merge 123 --rebase
```

---

## `gh pr comment` — Add a Comment

```
gh pr comment [<number>|<url>|<branch>] [flags]
```

| Flag | Description |
|------|-------------|
| `-b, --body <text>` | Comment body |
| `-F, --body-file <file>` | Read body from file |
| `--edit-last` | Edit your most recent comment |
| `--delete-last` | Delete your most recent comment |
| `-e, --editor` | Open editor to write body |

---

## `gh pr edit` — Edit PR Metadata

```
gh pr edit [<number>|<url>|<branch>] [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | New title |
| `-b, --body <text>` | New body |
| `-F, --body-file <file>` | Read body from file |
| `-B, --base <branch>` | Change base branch |
| `--add-reviewer <login>` | Add reviewer (repeatable) |
| `--remove-reviewer <login>` | Remove reviewer (repeatable) |
| `--add-assignee <login>` | Add assignee (`@me`) (repeatable) |
| `--remove-assignee <login>` | Remove assignee (repeatable) |
| `--add-label <name>` | Add label (repeatable) |
| `--remove-label <name>` | Remove label (repeatable) |
| `--add-project <name>` | Add to project (repeatable) |
| `--remove-project <name>` | Remove from project (repeatable) |
| `-m, --milestone <name>` | Set milestone (`""` to clear) |

---

## `gh pr close` / `gh pr reopen` / `gh pr ready`

```bash
gh pr close <number> [-c "comment"] [-d]    # -d deletes branch
gh pr reopen <number> [-c "comment"]
gh pr ready <number>                         # convert draft → ready
gh pr ready <number> --undo                  # convert ready → draft
```

---

## `gh pr status` — Overview of Your PRs

```
gh pr status [flags]
```

Shows: PRs you created, PRs requesting your review, and PRs mentioning you.

| Flag | Description |
|------|-------------|
| `--conflict-status` | Show merge conflict status |
| `--json <fields>` | JSON output |

---

## PR JSON Fields Reference

Useful fields for `--json`:

| Field | Description |
|-------|-------------|
| `number` | PR number |
| `title` | PR title |
| `state` | `OPEN`, `CLOSED`, `MERGED` |
| `isDraft` | Boolean |
| `author` | `{login, name}` |
| `assignees` | Array of `{login}` |
| `reviewRequests` | Array of `{login}` or team |
| `reviewDecision` | `APPROVED`, `CHANGES_REQUESTED`, `REVIEW_REQUIRED` |
| `labels` | Array of `{name, color}` |
| `baseRefName` | Base branch name |
| `headRefName` | Head branch name |
| `url` | PR URL |
| `body` | PR description |
| `createdAt` | ISO timestamp |
| `updatedAt` | ISO timestamp |
| `mergedAt` | ISO timestamp (if merged) |
| `closedAt` | ISO timestamp (if closed) |
| `mergeable` | `MERGEABLE`, `CONFLICTING`, `UNKNOWN` |
| `statusCheckRollup` | Array of check results |
| `commits` | Array of `{oid, messageHeadline, authors}` |
| `files` | Array of `{path, additions, deletions}` |
| `comments` | Array of `{body, author, createdAt}` |
| `reviews` | Array of review objects |
| `headRepository` | `{name, owner: {login}}` |
