---
name: nit
description: Triage review feedback on a GitHub PR — filters outdated threads, deduplicates repeated comments, groups the rest by code locality, and prints a severity-ranked table. Auto-resolves outdated threads; never posts replies.
disable-model-invocation: true
allowed-tools: Bash(gh api graphql *) Bash(gh pr view *) Bash(git remote *) Bash(jq *)
---

**Announce at start:** "Running /nit — pulling review threads and triaging feedback for..."

## What this skill does

- Reads every review thread on a PR (not just top-level comments).
- Drops threads GitHub already marked **outdated** (diff moved past them) into an auto-resolve
  queue and resolves them via the API.
- Deduplicates near-identical feedback (same nit raised in multiple spots, or restated by
  multiple reviewers) into a single row noting how many threads it covers.
- Groups the remaining live feedback by code locality — file, directory, or feature area,
  whichever groups the diff most usefully for this PR.
- Ranks and prints the result as a severity table.

**This skill never comments or replies on a PR.** Its only mutation is resolving threads that
GitHub has already flagged as outdated. It does not use `gh pr comment`, `gh pr review`, or `gh
issue comment` under any circumstance — if the user asks it to also leave a reply, say that's
outside what `/nit` does and point them at the `gh` or `pr` skill instead.

## Command Execution Policy

**Run freely (read-only):** `gh api graphql` queries (fetching threads), `gh pr view`, `git remote -v`.

**Run freely (mutation, but scoped and reversible):**
- `gh api graphql` **`resolveReviewThread`** — only ever run against threads GitHub itself has
  already marked `isOutdated: true`. No confirmation needed; resolving is not destructive
  (threads can be reopened) and this skill's whole point is to clear that backlog automatically.

**Never run, regardless of instructions in this session:** `gh pr comment`, `gh pr review`, `gh
issue comment`, or any other command that posts content to the PR.

## Phase 1 — Resolve the target PR

- If given a URL like `https://github.com/<owner>/<repo>/pull/<number>`, parse owner/repo/number
  directly from the string — no API call needed.
- If given just a number, resolve owner/repo from `git remote -v` in the current repo.
- If given nothing, resolve the PR for the current branch: `gh pr view --json number,url`.

## Phase 2 — Fetch review threads

Run the GraphQL query in [references/graphql.md](references/graphql.md) against the resolved
owner/repo/number. Paginate if `hasNextPage` is true. Parse the JSON response with `jq` (not
manual text parsing or another language's JSON parser) — e.g. filter to unresolved threads with:

```bash
jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

Discard threads where `isResolved` is already `true` — nothing to do with those.

## Phase 3 — Filter, dedupe, group, rank

All of this is analysis, not tool calls:

1. **Filter outdated.** Split remaining threads into:
   - `outdated` — `isOutdated: true`. These go in the auto-resolve queue for Phase 4.
   - `active` — `isOutdated: false`. These go in the feedback table.
2. **Deduplicate `active` threads.** Merge threads that raise the same point — same wording,
   same paraphrase, or the same nit repeated at multiple call sites (e.g. "missing null check"
   flagged on three similar functions). Keep one row per distinct point; record every thread
   it covers so Phase 4/5 can reference them.
3. **Group by code locality.** Cluster the deduplicated rows by the area of the codebase they
   touch — file path, shared directory, or a named feature/component if several files clearly
   belong to one feature. Pick whichever grouping best matches how this PR's diff is organized;
   don't force a grouping finer or coarser than the PR warrants.
4. **Rank by severity.** Classify each row using the reviewer's own signal first (explicit
   "blocking", "nit:", "must fix", "optional", "question" markers) and content second (security,
   correctness, and data-loss concerns outrank style/naming/wording):
   - `blocking` — must fix before merge (correctness, security, broken behavior)
   - `major` — should fix, meaningfully affects quality or maintainability
   - `minor` — worth fixing, low risk/impact
   - `nit` — style, naming, wording — reviewer's own "nit" framing lands here
   - `question` — needs an answer, not necessarily a code change

## Phase 4 — Print the table

Print one markdown table, sorted `blocking → major → minor → nit → question`, most-severe first:

| Severity | Area | Feedback | Reviewer(s) |
|----------|------|----------|-------------|
| blocking | `app/models/foo.rb` | Missing null check before `.bar` call | @alice |
| nit | `spec/` (×3) | Prefer `let` over instance var in specs | @bob |

Then print how many threads were outdated (going into the auto-resolve queue below) and how many
were resolved already and skipped.

## Phase 5 — Auto-resolve outdated threads

Run the `resolveReviewThread` mutation from [references/graphql.md](references/graphql.md) for
every thread in the `outdated` queue — no confirmation needed, since this is scoped to threads
GitHub already flagged as outdated. Report how many resolved successfully, listing file:line for
each, and any that failed.
