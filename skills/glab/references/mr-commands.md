# GitLab CLI — Merge Request Commands Reference

## `glab mr create` — Open a Merge Request

```
glab mr create [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | MR title |
| `-d, --description <text>` | MR description |
| `-b, --target-branch <branch>` | Target (base) branch (default: project default) |
| `-s, --source-branch <branch>` | Source branch (default: current branch) |
| `-a, --assignee <username>` | Assign to user (repeatable) |
| `-r, --reviewer <username>` | Request review from user (repeatable) |
| `-l, --label <name>` | Add label (repeatable) |
| `-m, --milestone <id\|title>` | Set milestone |
| `--draft` / `--wip` | Mark as draft/WIP |
| `--fill` | Use first commit title/body as MR title/description |
| `--fill-commit-body` | Append all commit messages to description |
| `--squash-before-merge` | Set "Squash commits" option |
| `--remove-source-branch` | Delete source branch on merge |
| `--allow-collaboration` | Allow commits from upstream members |
| `--no-editor` | Skip opening editor for description |
| `--push` | Push current branch before opening MR |
| `-w, --web` | Open MR creation form in browser |

### Examples

```bash
# Basic
glab mr create -t "Fix null pointer in auth" -d "Resolves #42"

# Draft with reviewers
glab mr create --draft -t "WIP: OAuth refactor" -r alice -r bob

# From commit messages, squash on merge
glab mr create --fill --squash-before-merge --remove-source-branch

# Target a non-default branch
glab mr create -t "Hotfix" -b release/v2
```

---

## `glab mr list` — List Merge Requests

```
glab mr list [flags]
```

| Flag | Description |
|------|-------------|
| `-s, --state <state>` | `opened` (default), `closed`, `merged`, `all` |
| `-l, --label <name>` | Filter by label (repeatable) |
| `-a, --author <username>` | Filter by author |
| `-A, --assignee <username>` | Filter by assignee |
| `-r, --reviewer <username>` | Filter by reviewer |
| `-m, --milestone <id\|title>` | Filter by milestone |
| `-b, --target-branch <branch>` | Filter by target branch |
| `-s, --source-branch <branch>` | Filter by source branch |
| `--draft` | Filter to drafts only |
| `--limit <n>` | Max results (default 30) |
| `--page <n>` | Page number |
| `-o, --output <format>` | `text` (default) or `json` |
| `-R, --repo <namespace/project>` | Target project |

---

## `glab mr view` — View a Merge Request

```
glab mr view [<id>|<branch>] [flags]
```

If no argument is given, uses the MR associated with the current branch.

| Flag | Description |
|------|-------------|
| `-w, --web` | Open in browser |
| `--comments` | Show comments |
| `-o, --output <format>` | `text` or `json` |

---

## `glab mr diff` — Show MR Diff

```
glab mr diff [<id>] [flags]
```

| Flag | Description |
|------|-------------|
| `--unified <n>` | Lines of context around changes |

---

## `glab mr checkout` — Check Out an MR Locally

```
glab mr checkout <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-b, --branch <name>` | Local branch name to use |
| `--track` | Set upstream tracking |

---

## `glab mr approve` / `glab mr revoke`

```
glab mr approve <id> [flags]
glab mr revoke <id>
```

| Flag | Description |
|------|-------------|
| `--sha <sha>` | Approve only if HEAD matches this SHA (safety check) |

---

## `glab mr merge` — Merge a Merge Request

```
glab mr merge [<id>] [flags]
```

| Flag | Description |
|------|-------------|
| `--squash` | Squash commits on merge |
| `--rebase` | Rebase source onto target |
| `-m, --message <text>` | Custom merge commit message |
| `--remove-source-branch` | Delete source branch after merge |
| `--when-pipeline-succeeds` | Merge automatically when pipeline passes (default on) |
| `--no-when-pipeline-succeeds` | Merge immediately, skip pipeline check |
| `--sha <sha>` | Merge only if HEAD matches this SHA |

### Examples

```bash
gh mr merge 123 --squash --remove-source-branch
glab mr merge 123 --rebase
glab mr merge 123 --when-pipeline-succeeds  # wait for CI
```

---

## `glab mr note` — Add a Comment

```
glab mr note <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-m, --message <text>` | Comment body |
| `--unique` | Skip if identical note already exists |

---

## `glab mr update` — Edit MR Metadata

```
glab mr update <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | New title |
| `-d, --description <text>` | New description |
| `-a, --assignee <username>` | Set assignee (repeatable; `""` to unassign) |
| `-r, --reviewer <username>` | Set reviewer (repeatable) |
| `-l, --label <name>` | Add label (repeatable) |
| `--remove-label <name>` | Remove label (repeatable) |
| `-m, --milestone <id>` | Set milestone (`0` to clear) |
| `--draft` | Convert to draft |
| `--ready` | Mark as ready (remove draft) |
| `--lock-discussion` | Lock discussion |
| `--unlock-discussion` | Unlock discussion |
| `--squash` | Enable squash on merge |
| `--remove-source-branch` | Enable remove source branch on merge |
| `-R, --repo <namespace/project>` | Target project |

---

## `glab mr close` / `glab mr reopen`

```bash
glab mr close <id>
glab mr reopen <id>
```

---

## `glab mr status` — Overview of Your MRs

Shows: MRs assigned to you, review requests, and MRs you created.

```
glab mr status [flags]
```

| Flag | Description |
|------|-------------|
| `--mine` | Show only your MRs |
| `-o, --output <format>` | `text` or `json` |

---

## `glab mr subscribe` / `glab mr unsubscribe`

```bash
glab mr subscribe <id>
glab mr unsubscribe <id>
```

---

## MR JSON Fields (common)

| Field | Description |
|-------|-------------|
| `iid` | MR internal ID (project-scoped) |
| `id` | MR global ID |
| `title` | Title |
| `state` | `opened`, `closed`, `merged` |
| `draft` | Boolean |
| `author` | `{username, name}` |
| `assignees` | Array of `{username}` |
| `reviewers` | Array of `{username}` |
| `labels` | Array of label names |
| `target_branch` | Target branch name |
| `source_branch` | Source branch name |
| `web_url` | MR URL |
| `description` | MR description |
| `created_at` | ISO timestamp |
| `updated_at` | ISO timestamp |
| `merged_at` | ISO timestamp (if merged) |
| `merge_status` | `can_be_merged`, `cannot_be_merged`, etc. |
| `pipeline` | Most recent pipeline `{id, status}` |
| `diff_stats` | `{additions, deletions, changes}` |
| `milestone` | Milestone object |
| `user_notes_count` | Comment count |
| `upvotes` / `downvotes` | Vote counts |
