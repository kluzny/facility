---
description: Draft and apply a pull request or merge request description from the current branch. Works with GitHub (gh) and GitLab (glab).
disable-model-invocation: true
allowed-tools: Bash(gh *) Bash(glab *) Agent
---

**Announce at start:** "Running /pr — spawning agent to gather branch context and draft a description."

## Phase 1 — Draft (subagent)

Read `agents/git-draft-pr.md` and spawn an Agent with its full contents as the prompt.

The agent returns a JSON object:

```json
{
  "platform": "github",
  "branch": "feature-branch",
  "base": "master",
  "existing_pr": null,
  "suggested_title": "Short PR title",
  "draft": "## Summary\n\n...\n\n## Key Changes\n\n- ...",
  "ticket": "#3"
}
```

## Phase 2 — Preview and Confirm

Show the **complete draft text** verbatim — exactly as it would appear in the PR/MR description. Do not summarize or describe it.

If `existing_pr` is `null`, ask: "No open PR/MR found for this branch — would you like to create one?"

Then offer the appropriate actions based on platform and whether a PR/MR exists:

**GitHub (PR exists):**
- **Apply** — `gh pr edit <number> --body "<draft>"`
- **Add as comment** — `gh pr comment <number> --body "<draft>"`

**GitHub (no PR):**
- **Create PR** — confirm or revise the suggested title, then: `gh pr create --title "<title>" --body "<draft>"`

**GitLab (MR exists):**
- **Apply** — `glab mr update <number> --description "<draft>"`
- **Add as comment** — `glab mr note <number> --message "<draft>"`

**GitLab (no MR):**
- **Create MR** — confirm or revise the suggested title, then: `glab mr create --title "<title>" --description "<draft>"`

**Either platform:**
- **Revise** — accept changes from the user and re-spawn the agent if the diff needs re-reading, otherwise revise the draft inline
- **Cancel** — do nothing

Never create, apply, or comment until the user explicitly confirms their choice.
