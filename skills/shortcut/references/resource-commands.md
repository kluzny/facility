# Shortcut CLI — Resource Commands Reference

Covers: epics, iterations, labels, teams, members, objectives, docs, projects, workflows, custom fields, and raw API access.

---

## `short epics` / `short epic` — Epics

### List Epics
```bash
short epics [options]
```

| Flag | Description |
|------|-------------|
| `-t, --title <query>` | Filter by title text |
| `-s, --started` | Show started epics only |
| `-c, --completed` | Show completed epics only |
| `-a, --archived` | Include archived |
| `-M, --milestone <ID>` | Filter by milestone (deprecated, prefer `--objectives`) |
| `--objectives <id\|name>` | Filter by linked objectives |
| `-d, --detailed` | Show more detail |
| `-f, --format <template>` | Custom format using epic `%` variables |

### Epic Sub-commands

```bash
short epic view <id>          # view epic details
short epic create [options]   # create a new epic
short epic update <id> [options]  # update an epic
short epic stories <id>       # list stories in the epic
short epic comments <id>      # list comments on the epic
```

### `short epic create` Flags

| Flag | Description |
|------|-------------|
| `-n, --name <text>` | Epic name **(required)** |
| `-d, --description <text>` | Description |
| `-s, --state <name>` | State: `to do`, `in progress`, `done` |
| `--deadline <YYYY-MM-DD>` | Deadline |
| `--planned-start <YYYY-MM-DD>` | Planned start date |
| `-o, --owners <id\|name>` | Owners (comma-separated) |
| `-T, --team <id\|name>` | Team assignment |
| `-l, --label <id\|name>` | Labels (comma-separated) |
| `--objectives <id\|name>` | Linked objectives (comma-separated) |
| `-I, --idonly` | Print only the ID |
| `-O, --open` | Open in browser |

`short epic update <id>` accepts all create flags plus `-a, --archived`.

### Epic Format Variables

| Variable | Description |
|----------|-------------|
| `%id` | Epic ID |
| `%t` | Title |
| `%m` | Milestone (deprecated) |
| `%obj` | Linked objectives |
| `%s` | State |
| `%dl` | Deadline |
| `%d` | Description |
| `%p` | Total points |
| `%ps` | Points started |
| `%pd` | Points done |
| `%c` | Completion % |
| `%ar` | Archived status |
| `%st` | Started status |
| `%co` | Completed status |

### Examples

```bash
# List in-progress epics
short epics -s

# Create an epic
short epic create -n "Q3 Auth Overhaul" -s "in progress" -o alice --deadline 2026-09-30

# Stories in an epic, tab-formatted
short epic stories 99 -f "%id\t%t\t%s"

# Update state and add deadline
short epic update 99 -s done --deadline 2026-06-30
```

---

## `short iterations` / `short iteration` — Iterations

### List Iterations
```bash
short iterations [options]
```

| Flag | Description |
|------|-------------|
| `-C, --current` | Active iterations only |
| `-S, --status <status>` | Filter: `unstarted`, `started`, `done` |
| `-T, --team <id\|name>` | Filter by team |
| `-t, --title <query>` | Filter by name |
| `-d, --detailed` | Show more detail |
| `-f, --format <template>` | Custom format |

### Iteration Sub-commands

```bash
short iteration view <id>           # view details
short iteration create [options]    # create new iteration
short iteration update <id> [opts]  # update iteration
short iteration delete <id>         # delete (destructive — confirm first)
short iteration stories <id>        # list stories in iteration
```

### `short iteration create` Flags

| Flag | Description |
|------|-------------|
| `-n, --name <text>` | Name **(required)** |
| `--start-date <YYYY-MM-DD>` | Start date **(required)** |
| `--end-date <YYYY-MM-DD>` | End date **(required)** |
| `-d, --description <text>` | Description |
| `-T, --team <id\|name>` | Team assignment |
| `-I, --idonly` | Print only the ID |
| `-O, --open` | Open in browser |

`short iteration update <id>` accepts all create flags. `short iteration view <id>` accepts `-O`.

### Iteration Format Variables

| Variable | Description |
|----------|-------------|
| `%id` | Iteration ID |
| `%t` | Name |
| `%s` | Status |
| `%start` | Start date |
| `%end` | End date |
| `%teams` | Assigned teams |
| `%stories` | Total story count |
| `%done` | Completed story count |
| `%points` | Total points |
| `%pdone` | Completed points |
| `%completion` | Completion % |
| `%url` | Iteration URL |

### Examples

```bash
# Active iteration(s)
short iterations -C

# All iterations for a team
short iterations -T Backend

# Create a 2-week sprint
short iteration create -n "Sprint 13" --start-date 2026-07-01 --end-date 2026-07-14 -T Backend

# Stories in an iteration
short iteration stories 55 -f "%id\t%t\t%s\t%o"

# Delete (always confirm first)
short iteration delete 55
```

---

## `short labels` / `short label` — Labels

### List Labels
```bash
short labels [options]
```

| Flag | Description |
|------|-------------|
| `-s, --search <query>` | Filter by name |
| `-a, --archived` | Include archived |

### Label Sub-commands

```bash
short label create [options]           # create label
short label update <idOrName> [opts]   # update label
short label stories <idOrName> [opts]  # list stories with label
short label epics <idOrName>           # list epics with label
```

### `short label create` Flags

| Flag | Description |
|------|-------------|
| `-n, --name <text>` | Label name **(required)** |
| `-d, --description <text>` | Description |
| `-c, --color <hex>` | Color (e.g., `#3366cc`) |
| `-I, --idonly` | Print only the ID |

`short label update` accepts all create flags plus `-a, --archived`. Identify the label by name or ID.

### Examples

```bash
# List all labels
short labels

# Create a colored label
short label create -n "security" -c "#cc0000"

# Stories tagged with a label
short label stories auth -f "%id\t%t\t%s"

# Archive an old label
short label update deprecated-api -a
```

---

## `short teams` / `short team` — Teams

### List Teams
```bash
short teams [options]
```

| Flag | Description |
|------|-------------|
| `-s, --search <query>` | Filter by name |
| `-a, --archived` | Include archived |

### Team Sub-commands

```bash
short team view <idOrName>     # view team details
short team stories <idOrName>  # list team's stories
```

### Examples

```bash
short teams
short teams -s backend
short team view Backend
short team stories Backend -f "%id\t%t\t%s"
```

---

## `short members` — Members

```bash
short members [options]
```

| Flag | Description |
|------|-------------|
| `-s, --search <query>` | Filter by name |
| `-d, --disabled` | Include disabled members |

```bash
short members
short members -s alice
```

---

## `short objectives` / `short objective` — Objectives

### List Objectives
```bash
short objectives [options]
```

| Flag | Description |
|------|-------------|
| `-t, --title <query>` | Filter by title |
| `-S, --state <state>` | Filter by state |
| `-s, --started` | Started only |
| `-c, --completed` | Completed only |
| `-a, --archived` | Include archived |
| `-d, --detailed` | Show more detail |
| `-f, --format <template>` | Custom format |

### Objective Sub-commands

```bash
short objective view <id>           # view details
short objective create [options]    # create objective
short objective update <id> [opts]  # update objective
short objective epics <id>          # list epics linked to objective
```

### `short objective create` Flags

| Flag | Description |
|------|-------------|
| `-n, --name <text>` | Name **(required)** |
| `-d, --description <text>` | Description |
| `-s, --state <name>` | State: `to do`, `in progress`, `done` |
| `--started-at <date>` | Override started date (ISO or YYYY-MM-DD) |
| `--completed-at <date>` | Override completed date |
| `-I, --idonly` | Print only the ID |
| `-O, --open` | Open in browser |

`short objective update <id>` accepts all create flags plus `-a, --archived`. `short objective view <id>` accepts `-O`.

### Examples

```bash
short objectives -s              # in-progress objectives
short objective create -n "Improve auth security" -s "in progress"
short objective epics 10         # epics tied to this objective
```

---

## `short docs` / `short doc` — Docs

### List Docs
```bash
short docs [options]
```

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | Search by title **(required for `-m`, `-f`, `-a`)** |
| `-m, --mine` | My docs only |
| `-f, --following` | Docs I follow |
| `-a, --archived` | Search archived docs |
| `-q, --quiet` | Suppress loading dialog |
| `-I, --idonly` | Print only IDs |

### Doc Sub-commands

```bash
short doc view <id> [opts]     # view doc
short doc create [options]     # create doc
short doc update <id> [opts]   # update doc
short doc delete <id> [opts]   # delete doc (destructive — confirm first)
```

### `short doc view` Flags

| Flag | Description |
|------|-------------|
| `--html` | Include HTML content |
| `-O, --open` | Open in browser |
| `-q, --quiet` | Print content only |

### `short doc create` Flags

| Flag | Description |
|------|-------------|
| `-t, --title <text>` | Title **(required)** |
| `-c, --content <text>` | Content **(required)** |
| `--markdown` | Treat content as markdown (default: HTML) |
| `-I, --idonly` | Print only the ID |
| `-O, --open` | Open in browser |

`short doc update <id>` accepts `-t`, `-c`, `--markdown`, `-O`. `short doc delete <id>` requires `--confirm`.

### Examples

```bash
# Search for a doc
short docs -t "onboarding"

# Create a markdown doc
short doc create -t "Sprint Retro" -c "## What went well..." --markdown

# View doc content
short doc view 77 -q

# Delete (requires --confirm)
short doc delete 77 --confirm
```

---

## `short workflows` — Workflow States

```bash
short workflows [options]
```

| Flag | Description |
|------|-------------|
| `-s, --search <query>` | Filter states by name |

Use this to discover valid state names before using `-s` in `short search` or `short story`.

```bash
short workflows
short workflows -s "in progress"
```

---

## `short projects` — Projects

```bash
short projects [options]
```

| Flag | Description |
|------|-------------|
| `-t, --title <query>` | Filter by name |
| `-a, --archived` | Include archived |
| `-d, --detailed` | Show more detail |

```bash
short projects
short projects -t backend
```

---

## `short custom-fields` / `short custom-field` — Custom Fields

```bash
short custom-fields [options]
short custom-field <id> [options]
```

| Flag | Description |
|------|-------------|
| `-s, --search <query>` | Filter by name |
| `-d, --disabled` | Include disabled fields |

---

## `short workspace` — Saved Searches / Workspaces

```bash
short workspace [NAME] [options]
```

| Flag | Description |
|------|-------------|
| `-l, --list` | List all saved workspaces |
| `-n, --name <name>` | Load named workspace |
| `-u, --unset <name>` | Remove a saved workspace |
| `-q, --quiet` | Suppress loading dialog |

Workspaces are saved searches. Use `short search ... -S <name>` to save, then `short workspace <name>` to replay.

```bash
short workspace -l
short workspace my-sprint
short workspace -u old-sprint
```

---

## `short api` — Raw API Access

```bash
short api <path> [options]
```

| Flag | Description |
|------|-------------|
| `-X, --method <method>` | HTTP method (default: `GET`) |
| `-H, --header <header>` | Add request header (repeatable) |
| `-f, --raw-field <key=value>` | Add body/query parameter (repeatable) |

Calls the [Shortcut REST API v3](https://shortcut.com/api/rest/v3) directly. Output is raw JSON — pipe to `jq` for processing.

### Examples

```bash
# Get a story
short api /stories/1234

# Search with pagination
short api /search/stories -f 'query=auth' -f 'page_size=25' | jq '.data[] | {id, name, state}'

# List members
short api /members | jq '.[] | {id, mention_name}'

# Create a story via API
short api /stories -X POST -f 'name=My story' -f 'project_id=123' -f 'story_type=bug'

# Get all iterations for a group
short api /iterations | jq '.[] | select(.status == "started") | {id, name}'
```

Refer to https://shortcut.com/api/rest/v3 for the full endpoint reference.
