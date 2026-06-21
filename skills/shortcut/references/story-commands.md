# Shortcut CLI — Story, Search & Create Commands

## `short search` — Search Stories

```
short search [SEARCH OPERATORS] [options]
```

### Filter Flags

| Flag | Description |
|------|-------------|
| `-t, --text <name>` | Text search in story names |
| `-o, --owner <name>` | Stories with this owner (mention name or ID) |
| `-s, --state <id\|name>` | Stories in this workflow state |
| `-y, --type <name>` | Story type: `feature`, `bug`, `chore` |
| `-l, --label <id\|name>` | Stories with this label |
| `--epic <id\|name>` | Stories in this epic |
| `-i, --iteration <id\|name>` | Stories in this iteration |
| `-p, --project <id>` | Stories in this project |
| `-e, --estimate <op><n>` | Filter by estimate: `=5`, `>3`, `<8` |
| `-c, --created <op><date>` | Created date filter: `>2026-01-01` |
| `-u, --updated <op><date>` | Updated date filter |
| `-a, --archived` | Include archived stories |

### Output Flags

| Flag | Description |
|------|-------------|
| `-f, --format <template>` | Custom output format using `%` variables |
| `-r, --sort <field>` | Sort results by field |

### Workspace Flags

| Flag | Description |
|------|-------------|
| `-S, --save <name>` | Save current search as a named workspace |
| `-n, --name <name>` | Load a saved workspace by name (equivalent to `short workspace <name>`) |

### Examples

```bash
# Text search with state filter
short search -t "payment" -s "In Progress"

# My open bugs
short search -y bug -o <my-mention-name>

# Stories in current sprint/iteration
short search -i "Sprint 42"

# Tabular output: ID, title, state, owners
short search -t "auth" -f "%id\t%t\t%s\t%o"

# Save a search for reuse
short search -o <me> -s "In Progress" -S my-active
short workspace my-active   # re-run it later
```

---

## `short story <id>` — View & Edit a Story

```
short story [options] <id>
short story <subcommand> <id>
```

### Display Flags

| Flag | Description |
|------|-------------|
| `-f, --format <template>` | Custom format using `%` variables |
| `-I, --idonly` | Print only the story ID |
| `-q, --quiet` | Suppress loading dialog |
| `-O, --open` | Open story in browser |
| `--from-git` | Parse story ID from current git branch name |

### Update Flags

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | Update title |
| `-d, --description <text>` | Update description |
| `-s, --state <id\|name>` | Change workflow state |
| `-e, --estimate <n>` | Set estimate (points) |
| `-y, --type <name>` | Change type: `feature`, `bug`, `chore` |
| `-l, --label <id\|name>` | Add labels (comma-separated) |
| `-o, --owners <id\|name>` | Set owners (comma-separated) |
| `-T, --team <id\|name>` | Assign to team |
| `--epic <id\|name>` | Assign to epic |
| `-i, --iteration <id\|name>` | Assign to iteration |
| `-c, --comment <text>` | Add a comment |
| `--deadline <YYYY-MM-DD>` | Set due date |
| `--task <text>` | Create a task on the story |
| `--task-complete <text>` | Toggle task completion by name |
| `--follower <id\|name>` | Update followers |
| `--requester <id\|name>` | Set requester |
| `--external-link <url>` | Add external link |
| `-a, --archived` | Archive the story |

### Position Flags

| Flag | Description |
|------|-------------|
| `--move-after <id>` | Reposition story after another story |
| `--move-before <id>` | Reposition story before another story |
| `--move-up <n>` | Move up n positions in workflow |
| `--move-down <n>` | Move down n positions in workflow |

### Download Flags

| Flag | Description |
|------|-------------|
| `-D, --download` | Download all story attachments |
| `--download-dir <path>` | Target directory for downloads |

### Git Integration Flags

| Flag | Description |
|------|-------------|
| `--git-branch` | Create/checkout branch with full slug |
| `--git-branch-short` | Create/checkout branch with short slug |

### Sub-commands

```bash
short story history <id>                        # story history log
short story comments <id>                       # list all comments
short story tasks <id>                          # list tasks
short story sub-tasks <id>                      # list sub-tasks
short story relation add <id> <id> --type <t>  # add story relation
```

### Examples

```bash
# View a story
short story 1234

# Infer ID from current branch
short story --from-git

# Transition + add comment in one command
short story 1234 -s "Done" -c "Merged in #456"

# Create and check out git branch
short story 1234 --git-branch
# → checks out: <mention>/1234-story-title-slug

# Open in browser
short story 1234 -O

# Bulk update: assign to me, set state
short story 1234 -o <mention-name> -s "In Progress"
```

---

## `short create` — Create a Story

```
short create [options]
```

### Flags

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | Story title **(required)** |
| `-y, --type <name>` | Type: `feature` (default), `bug`, `chore` |
| `-d, --description <text>` | Description text |
| `-e, --estimate <n>` | Estimate in points |
| `-s, --state <id\|name>` | Initial workflow state *(required if --project not set)* |
| `-p, --project <id\|name>` | Project *(required if --state not set)* |
| `--epic <id\|name>` | Assign to epic |
| `-i, --iteration <id\|name>` | Assign to iteration |
| `-l, --label <id\|name>` | Labels (comma-separated) |
| `-o, --owners <id\|name>` | Owners (comma-separated) |
| `-T, --team <id\|name>` | Team assignment |
| `-I, --idonly` | Print only the new story ID |
| `-O, --open` | Open story in browser after creation |
| `--git-branch` | Create and checkout a git branch for the story |
| `--git-branch-short` | Create and checkout a short git branch |

### Examples

```bash
# Minimal
short create -t "Fix null pointer in auth" -s "Ready for Dev"

# Full
short create \
  -t "Add OAuth2 login" \
  -y feature \
  -e 5 \
  -s "Ready for Dev" \
  -o alice,bob \
  -l "auth,backend" \
  --epic 99 \
  -i "Sprint 12"

# Create a chore and get just the ID back
short create -t "Update deps" -y chore -s "Backlog" -I

# Create and immediately branch
short create -t "Fix login timeout" -y bug -s "In Progress" --git-branch
```

---

## Story Format Variables Reference

These variables work in `-f`/`--format` on both `short search` and `short story`:

| Variable   | Description               | Example output             |
|------------|---------------------------|----------------------------|
| `%id`      | Story ID                  | `1234`                     |
| `%t`       | Title                     | `Fix login redirect`       |
| `%a`       | Archived (true/false)     | `false`                    |
| `%T`       | Team name                 | `Backend`                  |
| `%o`       | Owners (mention names)    | `alice, bob`               |
| `%r`       | Requester                 | `charlie`                  |
| `%l`       | Labels                    | `auth, backend`            |
| `%u`       | Story URL                 | `https://app.shortcut.com/…` |
| `%epic`    | Epic name                 | `Q3 Auth Overhaul`         |
| `%i`       | Iteration name            | `Sprint 12`                |
| `%p`       | Project name              | `Backend`                  |
| `%y`       | Story type                | `feature`                  |
| `%e`       | Estimate                  | `5`                        |
| `%s`       | State                     | `In Progress`              |
| `%c`       | Created timestamp         | `2026-06-01T10:00:00Z`     |
| `%updated` | Updated timestamp         | `2026-06-20T14:22:00Z`     |
| `%gb`      | Git branch name (full)    | `alice/1234-fix-login`     |
| `%gbs`     | Git branch name (short)   | `1234-fix-login`           |
| `%j`       | Full story as JSON        | `{…}`                      |

### Format examples

```bash
# Tab-separated list: id, title, state
short search -t "auth" -f "%id\t%t\t%s"

# CSV-style with URL
short search -o alice -f "%id,%t,%s,%u"

# Get git branch for a story
short story 1234 -f "%gb"
```
