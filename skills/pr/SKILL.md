---
description: Draft and apply a pull request or merge request description from the current branch. Works with GitHub (gh) and GitLab (glab).
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh *) Bash(glab *)
---

**Announce at start:** "Running /pr — gathering branch context to draft a PR/MR description."

## Detect Platform

Run `git remote get-url origin 2>/dev/null` to read the remote URL, then:

- URL contains `github.com` → **GitHub** — use `gh`, call it "pull request" / "PR"
- URL contains `gitlab` → **GitLab** — use `glab`, call it "merge request" / "MR"
- Neither matched → note that platform detection failed; still draft the description, but skip the Apply step and tell the user to apply it manually

## Check for Existing PR / MR

After detecting the platform, check whether an open PR/MR already exists for the current branch:

- **GitHub:** `gh pr list --head <branch> --state open --json number,title,url --limit 1`
- **GitLab:** `glab mr list --source-branch <branch> --state opened`

**If one exists:** record its number/URL and proceed to draft. The Apply action will update the existing PR/MR.

**If none exists:** after showing the draft, ask the user: "No open PR/MR found for this branch — would you like to create one?" If yes, use Create as the action instead of Apply (see Preview and Confirm). If no, offer the remaining options as normal.

## Gather Context

Run all of the following before drafting anything:

1. `git branch --show-current` — current branch name
2. Detect base branch — run this single command and use the first ref printed; fall back to `master` if output is empty:
   `git show-ref refs/heads/master refs/heads/main refs/heads/develop 2>/dev/null | head -1 | sed 's|.* refs/heads/||'`
3. `git log <base>..HEAD --oneline` — commits on this branch
4. `git log <base>..HEAD --stat` — file-level change summary
5. `git diff <base>...HEAD` — full code diff

## Detect Ticket or Story

Parse the branch name for a project management reference. Match any of these patterns (case-insensitive):

- `[A-Z]{2,10}-\d+` — e.g. `SC-123`, `PROJ-456`, `ABC-789`
- `#\d+` — bare issue number

If a match is found, record it for the Ticket / Story section. If nothing matches, omit that section entirely — do not block or error.

## Draft the Description

Write the full PR/MR description using this exact format:

```
## Summary

<2–4 sentences explaining what changed and why — focus on purpose and impact, not implementation details>

## Key Changes

- <behavioral or workflow change>
- <important implementation decision>
- <breaking change or migration note, if any>

## Ticket / Story

- <ID> — <branch slug or short description>
```

Omit the **Ticket / Story** section if no ID was detected.

**Do not include:**
- Line or file counts
- Generic statements about code quality or test coverage
- Whitespace or formatting trivia
- Line-by-line implementation detail

## Preview and Confirm

Show the **complete draft text** above — exactly as it would appear in the PR/MR description. Do not summarize or describe it; show it verbatim so the user can read and copy it.

Then ask the user to choose one action:

**GitHub (PR exists):**
- **Apply** — `gh pr edit --body "<draft>"`
- **Add as comment** — `gh pr comment --body "<draft>"`

**GitHub (no PR):**
- **Create PR** — ask for a title (suggest one from the branch/commits), then run `gh pr create --title "<title>" --body "<draft>"`

**GitLab (MR exists):**
- **Apply** — `glab mr update --description "<draft>"`
- **Add as comment** — `glab mr note --message "<draft>"`

**GitLab (no MR):**
- **Create MR** — ask for a title (suggest one from the branch/commits), then run `glab mr create --title "<title>" --description "<draft>"`

**Either platform:**
- **Revise** — accept changes from the user and re-draft
- **Cancel** — do nothing

Never create, apply, or comment until the user explicitly confirms their choice.
