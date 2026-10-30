---
name: nit
description: Triage review feedback on a GitHub PR — review threads, review bodies, and PR comments, weighed against the PR description. Filters outdated threads, deduplicates repeated comments, groups the rest by code locality, and prints a severity-ranked table. Auto-resolves outdated threads; never posts replies.
disable-model-invocation: true
allowed-tools: Bash(gh api graphql *) Bash(gh pr view *) Bash(git remote *) Bash(jq *)
---

**Announce at start:** "Running /nit — reading the PR description, pulling review threads, review bodies, and PR comments, and triaging feedback for..."

## What this skill does

- Reads the PR description first, so feedback it already answers (a recorded decision, a
  follow-up ticket, a breaking note, a stated scope) is marked as covered rather than ranked as
  open work.
- Reads every review thread on a PR, plus review summary bodies and top-level PR conversation
  comments — feedback often lives only in a review body with no inline threads.
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

**Run freely (read-only):** `gh api graphql` queries (fetching the description, threads, comments, and reviews), `gh pr view`, `git remote -v`.

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

## Phase 2 — Fetch the description and feedback

Run **both** fetch queries in [references/graphql.md](references/graphql.md) against the resolved
owner/repo/number — review threads, and the PR description + conversation comments + review
bodies. Skipping the second query misses the description and any PR whose feedback was left as a
review summary or a top-level comment.

**Read the description before any feedback.** Note what it commits the PR to, so Phase 3 can
weigh each point against it:

- **Decisions and accepted tradeoffs** — e.g. a "Decisions" section, or "acceptable because…".
- **Follow-up and deferred work** — tickets (`PD-1234`, `#123`) and what each one says it covers.
- **Breaking or behaviour-change notes** the reviewer might otherwise flag as a regression.
- **Scope** — what's called out as out of scope, or as an unrelated change included for review.
- **Claimed fixes** — Key Changes / bug-fix bullets that say an issue is resolved.

For the review threads query, paginate if `hasNextPage` is true. Parse the JSON response with `jq` (not
manual text parsing or another language's JSON parser) — e.g. filter to unresolved threads with:

```bash
jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

Discard threads where `isResolved` is already `true` — nothing to do with those.

For comments and review bodies, drop empty review bodies and minimized comments. Keep the PR
author's comments, but don't treat them as feedback rows — they're often pushback, a "fixed in
<sha>", or a "won't fix" on a reviewer's point, and are read in Phase 3. Also skip bot comments
that carry no review feedback (CI status, coverage reports, deploy previews) — judge by content,
since some bots do leave real review findings.

## Phase 3 — Filter, dedupe, group, rank

All of this is analysis, not tool calls:

1. **Filter outdated.** Split remaining threads into:
   - `outdated` — `isOutdated: true`. These go in the auto-resolve queue for Phase 4.
   - `active` — `isOutdated: false`. These go in the feedback table.

   Review bodies and PR comments are always `active` — they have no outdated flag. Split any
   comment or review body that lists several findings (numbered list, headings, bullets) into one
   item per finding, using the file/symbol it names for locality. If a review's `commit.oid`
   differs from `headRefOid`, note in its Feedback cell that it predates the latest push (e.g.
   `(at 820d4cb)`) — it may already be addressed.

   Match each PR-author comment to the reviewer point(s) it responds to (quoted text, a reply
   that names the finding or its number, or clear topical overlap). Pushback or a "won't fix"
   doesn't remove the row — note it in the Feedback cell (e.g. `— author disagrees: <gist>`) so
   it reads as an open discussion rather than a to-do. An author claim that it's already fixed
   gets `— author says fixed` the same way. Author comments that don't respond to any point
   (status updates, notes to self) are dropped.
2. **Weigh each point against the description.** Match it to what Phase 2 noted, and only on
   a specific match — a description that merely touches the same area doesn't count:
   - **Deferred to a ticket that names this case** → severity `covered`, note
     `— tracked in PD-1234`.
   - **Deferred to a related ticket that doesn't name this case** (e.g. "consolidate pagination"
     vs. a reviewer's "page=0 returns 500") → keep the reviewer's severity, note
     `— description names PD-1234 but not this case`. The fix is usually to spell the case out
     in the description so the reviewer stops re-raising it.
   - **Answered by a recorded decision, breaking note, or stated scope** → severity `covered`,
     note `— decided in description: <gist>`. A question the description answers is `covered`
     the same way (`— answered in description: <gist>`).
   - **Claimed fixed by a Key Changes bullet** → keep the severity, note
     `— description says fixed`, like an author comment would.
   - **The reviewer has already seen the description's answer and still objects** (they quote or
     cite it, or say "acceptable, but…" with a new concern) → keep their severity and note
     `— disputes description: <gist>`. Don't downgrade a point the reviewer has explicitly
     reopened.
   - **Feedback contradicts the description** (code doesn't do what it claims) → keep the
     severity and note `— contradicts description`; that's worth fixing in one or the other.
3. **Deduplicate `active` threads.** Merge threads that raise the same point — same wording,
   same paraphrase, or the same nit repeated at multiple call sites (e.g. "missing null check"
   flagged on three similar functions), including a point raised both inline and in a review
   body or comment. Keep one row per distinct point; record every thread
   it covers so Phase 4/5 can reference them.
4. **Group by code locality.** Cluster the deduplicated rows by the area of the codebase they
   touch — file path, shared directory, or a named feature/component if several files clearly
   belong to one feature. Pick whichever grouping best matches how this PR's diff is organized;
   don't force a grouping finer or coarser than the PR warrants.
5. **Rank by severity.** Classify each row using the reviewer's own signal first (explicit
   "blocking", "nit:", "must fix", "optional", "question" markers) and content second (security,
   correctness, and data-loss concerns outrank style/naming/wording):
   - `blocking` — must fix before merge (correctness, security, broken behavior)
   - `major` — should fix, meaningfully affects quality or maintainability
   - `minor` — worth fixing, low risk/impact
   - `nit` — style, naming, wording — reviewer's own "nit" framing lands here
   - `question` — needs an answer, not necessarily a code change
   - `covered` — set in step 2 only; the description already answers it, so at most the reviewer
     needs pointing at it

## Phase 4 — Print the table

Print one markdown table, sorted `blocking → major → minor → nit → question → covered`,
most-severe first:

| Severity | Area | Feedback | Reviewer(s) |
|----------|------|----------|-------------|
| blocking | `app/models/foo.rb` | Missing null check before `.bar` call | @alice |
| nit | `spec/` (×3) | Prefer `let` over instance var in specs | @bob |
| covered | `app/api/` | 400 on old query params breaks bookmarks — decided in description: old links unsupported | @alice |

Then print how many threads were outdated (going into the auto-resolve queue below), how many
were resolved already and skipped, how many review bodies and PR comments contributed rows, and
how many rows the description covers or only loosely covers (`description names … but not this
case`).

Rows that come from review bodies or PR comments have no file:line, so use the area the text
names (e.g. `capture.py`); fall back to `(general)` when it names none.

## Phase 5 — Auto-resolve outdated threads

Run the `resolveReviewThread` mutation from [references/graphql.md](references/graphql.md) for
every thread in the `outdated` queue — no confirmation needed, since this is scoped to threads
GitHub already flagged as outdated. Report how many resolved successfully, listing file:line for
each, and any that failed.
