---
name: Shortcut CLI
description: Work with Shortcut project management via the shortcut-cli (`short`) command. Use when the user asks about stories, epics, iterations, members, teams, labels, objectives, docs, or any Shortcut workspace operations.
when_to_use: Triggered by requests to view, create, search, update, or list Shortcut stories, epics, iterations, objectives, labels, teams, workflows, or docs. Also triggered when the user wants to create a git branch from a story, check Shortcut workspace state, or run searches.
allowed-tools: Bash(short *)
---

**Announce at start:** "I'm using the shortcut skill to..."

## Authentication

Shortcut CLI requires a personal API token. If commands fail with auth errors:
1. Check config: `short workspace` (shows current workspace or auth error)
2. If not configured, instruct user to run `short install` interactively
3. Or set env vars: `SHORTCUT_API_TOKEN`, `SHORTCUT_URL_SLUG`, `SHORTCUT_MENTION_NAME`
4. Never store tokens in code, never commit them, never attempt to authenticate on behalf of the user

## Defaults

- Story URL format: `https://app.shortcut.com/<workspace>/story/<id>` — always print after any story-specific operation
- Branch naming: `--git-branch` for full slug (`<mention>/<id>-title`), `--git-branch-short` for compact form
- Workspace: managed via `short workspace`; slug set in `SHORTCUT_URL_SLUG`

## Command Execution Policy

**Run freely (read-only):** `short search`, `short story <id>` (view), `short members`, `short workflows`, `short projects`, `short labels`, `short epics`, `short iterations`, `short teams`, `short objectives`, `short docs`, `short api` with `GET`

**Require explicit user confirmation:**
- `short create` — creates a new story
- `short story <id> -s/-e/-t/-d/...` — mutates an existing story
- `short epic create/update`, `short iteration create/update/delete`, `short label create/update`
- `short doc delete`, `short iteration delete` — destructive, always confirm

## Quick Reference

### Search Stories
```bash
short search -t "login bug"
short search -o <member> -s "In Progress" -y bug
short search --epic <epic-id>
short search -i <iteration-id>
short search -f "%id\t%t\t%s\t%o"   # custom format
short search -S my-saved-search      # load a saved workspace/search
```

### View a Story
```bash
short story 1234
short story 1234 -O                  # open in browser
short story 1234 --from-git          # infer ID from current branch name
short story 1234 -f "%id\t%t\t%s\t%u"
short story history 1234
short story comments 1234
short story tasks 1234
```

### Update a Story
```bash
short story 1234 -s "In Progress"
short story 1234 -e 5
short story 1234 -t "New title"
short story 1234 -c "Comment text"
short story 1234 -l "auth,backend"   # comma-separated labels
short story 1234 -o <member>
short story 1234 --deadline 2026-07-01
short story 1234 -y feature
```

### Git Branch Integration
```bash
short story 1234 --git-branch        # full: <mention>/<id>-title-slug
short story 1234 --git-branch-short  # shorter branch variant
```

### Create a Story
```bash
# Minimum: title + state OR project
short create -t "Fix login redirect" -s "Ready for Dev"
short create -t "Add OAuth" -y feature -e 5 -o <member> -l "auth,backend"
short create -t "DB migration spike" -y chore --epic <epic-id> -i <iteration-id>
```

### Resources at a Glance
```bash
short members                        # list all members
short workflows                      # list workflow states
short projects                       # list projects
short labels                         # list labels
short epics                          # list epics
short iterations -C                  # active iterations only
short teams                          # list teams
short objectives                     # list objectives
```

### Workspace Management
```bash
short workspace -l                   # list saved workspaces/searches
short workspace my-org               # switch to named workspace
short workspace -u old-ws            # remove saved workspace
```

### Raw API Access
```bash
short api /stories/1234
short api /search/stories -f 'query=auth' | jq '.data[] | {id, name}'
short api /stories -X POST -f 'name=My story' -f project_id=123
```

## Story Format Variables

For `-f`/`--format` on `search` and `story`:

| Variable   | Description          |
|------------|----------------------|
| `%id`      | Story ID             |
| `%t`       | Title                |
| `%a`       | Archived status      |
| `%T`       | Team name            |
| `%o`       | Owners               |
| `%r`       | Requester            |
| `%l`       | Labels               |
| `%u`       | URL                  |
| `%epic`    | Epic name            |
| `%i`       | Iteration            |
| `%p`       | Project              |
| `%y`       | Story type           |
| `%e`       | Estimate             |
| `%s`       | State                |
| `%c`       | Created timestamp    |
| `%updated` | Updated timestamp    |
| `%gb`      | Git branch name      |
| `%gbs`     | Git branch (short)   |
| `%j`       | Full JSON            |

## Detailed Reference

- **Story, search, and create flags** — [references/story-commands.md](references/story-commands.md)
- **Epics, iterations, labels, teams, objectives, docs, projects, workflows, API** — [references/resource-commands.md](references/resource-commands.md)
