# Project Management

Issues and project tracking for this repo live on GitHub.

- **Project board:** https://github.com/users/kluzny/projects/1/views/1
- **Issues:** https://github.com/kluzny/facility/issues

Use the `/gh` skill for all interactions with issues, pull requests, and the project board.

---

## Board phases

| Phase | Meaning |
|-------|---------|
| **Backlog** | Default landing spot for new issues. Not yet prioritized. |
| **Ready** | Prioritized and scoped — the current working todo list. Pull from here when choosing what to work on next. |
| **In Progress** | Has an active branch. One issue per branch; move here when you open the branch. |
| **In Review** | PR is open and waiting for code review or merge. Move here when the PR is created. |
| **Done** | Merged or closed. No action needed. |

---

## Workflow

All branches are cut from `master` and PRs target `master`. Never use `main`, `develop`, or any other base branch.

> The `/pr` skill auto-detects the base branch (trying `master` first, then `main`, then `develop`), so it will always resolve to `master` in this repo.

### Starting work

When asked to work an issue, complete **all three steps** before doing any implementation work. Do not skip the board update.

**Step 1 — Create and check out the branch:**
```bash
gh issue develop <number> --checkout
```

**Step 2 — Move the issue to In Progress** (mandatory — do not skip):
```bash
NUM=<number>
ITEM_ID=$(gh project item-list 1 --owner kluzny --format json \
  | jq -r --arg url "$(gh issue view $NUM --json url -q '.url')" \
  '.items[] | select(.content.url == $url) | .id')
gh project item-edit \
  --id "$ITEM_ID" \
  --project-id PVT_kwHOABREfs4BbZlM \
  --field-id PVTSSF_lAHOABREfs4BbZlMzhWKW0M \
  --single-select-option-id 47fc9ee4
```

**Step 3 — Confirm:** report the branch name and that the issue has been moved to In Progress before proceeding.

**Project IDs (pre-looked-up — do not re-query each time):**

| Thing | ID |
|-------|----|
| Project | `PVT_kwHOABREfs4BbZlM` |
| Status field | `PVTSSF_lAHOABREfs4BbZlMzhWKW0M` |
| Backlog option | `f75ad846` |
| Ready option | `61e4505c` |
| In progress option | `47fc9ee4` |
| In review option | `df73e18b` |
| Done option | `98236657` |

### Opening a PR
1. Push your branch and open a PR: `/pr` (or `gh pr create`). Include `Closes #<number>` in the PR body so the issue auto-closes on merge.
2. Move the issue to **In Review** using the IDs from the table above:
```bash
gh project item-edit \
  --id "$ITEM_ID" \
  --project-id PVT_kwHOABREfs4BbZlM \
  --field-id PVTSSF_lAHOABREfs4BbZlMzhWKW0M \
  --single-select-option-id df73e18b
```

### After merge
GitHub moves the issue to **Done** automatically when the linked PR merges. No manual step needed.

---

## Common `gh` commands

```bash
# List open issues
gh issue list

# View an issue
gh issue view <number>

# Create an issue
gh issue create --title "Title" --body "Description"

# Create a branch tied to an issue and check it out
gh issue develop <number> --checkout

# Open the project board in the browser
gh browse --projects

# List PRs
gh pr list

# View a PR
gh pr view <number>

# Check CI status on current branch
gh run list --branch $(git branch --show-current)
```

---

## Adding issues to the project board

New issues created via `gh issue create` land in **Backlog** automatically if the repo's project automation is configured. If an issue doesn't appear on the board, add it manually:

```bash
gh project item-add 1 --owner kluzny --url <issue-url>
```
