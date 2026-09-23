---
description: Turn a user concern or piece of feedback into high-level, do-oriented agent guidance and record it in a repo's AGENTS.md — inline for short guidance, or split into docs/agents/<topic>.md and linked from a file-tree listing when it's large or complex.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash(mkdir *), Bash(ls *), Bash(find *)
---

**Announce at start:** "Running /guidance — recording this as agent guidance."

This skill operates on whatever repo it's invoked in, not on the `facility` repo itself (unless that happens to be the working directory).

## Phase 1 — Gather the Guidance

If the user supplied guidance as skill arguments, use that. Otherwise ask what guidance to record.

The input is often raw feedback or a concern ("you keep doing X", "I wish you'd checked Y first"), not already agent-ready instruction — that's expected, and Phase 2 is where it gets converted.

Pick a short kebab-case topic slug for it (e.g. `code-review`, `deploy-process`). Infer it from the content; if nothing obvious fits, ask the user for one.

## Phase 2 — Translate Intent into Agent Guidance

Don't transcribe the user's feedback verbatim. Find the underlying intent — the behavior they actually want going forward — and encode *that*, following these rules:

- **State what to do, not what happened.** Rephrase a complaint or observation as a forward-looking instruction. "You forgot to run tests before pushing" becomes "Run the test suite before pushing."
- **Prefer affirmative guidance.** Default to phrasing as a positive instruction (do X). Only phrase it as a prohibition ("don't"/"never") when the user's guidance is specifically about something that must *not* be done — a genuine constraint, not just the inverse of a "do" instruction.
- **Match specificity to what correctness requires.** Write the guidance as high-level as possible while still being unambiguous and actionable. Add concrete detail (exact commands, file paths, thresholds) only when the general instruction would otherwise be ambiguous or get executed inconsistently — not because the original feedback happened to include that detail.
- **Drop incident-specific framing.** Strip references to the specific event, PR, file, or moment that prompted the feedback (no "as seen in..." or "last time..."). The guidance should read as a standing rule that generalizes, not a postmortem note.
- **Keep the agent-facing voice.** Write it the way the rest of `AGENTS.md`/`docs/agents/` already reads — imperative, second-person-to-the-agent, no meta-commentary about where the rule came from.

If the translated intent is unclear or could go multiple ways, ask the user to confirm the distilled version before moving on — don't guess at intent silently when it's genuinely ambiguous.

### Scope: day-to-day operation, not setup or edge cases

Agent guidance should govern the regular, recurring operation and execution of coding tasks — how to work in this repo day to day. It is almost never the right place for:

- **One-time setup or environment instructions** (installing tools, provisioning accounts, initial configuration) — this belongs in a README or setup doc, not standing agent guidance.
- **One-off commands** run for a single occasion rather than a repeatable practice.
- **Peculiar or rare edge cases** that don't reflect normal operation.

If the guidance the user gave falls into one of these categories, don't fold it into `AGENTS.md`/`docs/agents/` by default — point out that it looks like setup/one-off/edge-case material and ask whether they still want it recorded as standing guidance anyway, or whether it belongs elsewhere (e.g. `README.md`, a setup doc). Only record it as agent guidance if the user explicitly confirms that's what they want.

## Phase 3 — Read Current State

- `Read` `AGENTS.md` at the repo root. If it doesn't exist, you'll create one from scratch in Phase 5.
- Check whether the guidance overlaps an existing section (in `AGENTS.md` or an existing `docs/agents/*.md`) — if so, prefer updating that section/file over creating a duplicate one.
- `find docs/agents -name '*.md'` (if the directory exists) to see what's already there.

## Phase 4 — Decide Placement

Default to **inline** in `AGENTS.md`. Split into a dedicated `docs/agents/<topic>.md` file only when the *translated* guidance from Phase 2 is particularly large or complex — as a rule of thumb, any of:

- It would run longer than roughly 15–20 lines once drafted, or covers multiple sub-topics/sections.
- It's a multi-step procedure, reference table, or set of examples rather than a short rule or two.
- The user explicitly asks for a separate doc, or says the topic is big.

Otherwise, keep it inline as a concise section or bullet, matching the tone and heading style already used in `AGENTS.md`. Most translated guidance should land here — the intent-first rewrite in Phase 2 tends to compress feedback into a sentence or two.

## Phase 5 — Draft

**Inline case:** Draft the exact section/paragraph to add or merge into `AGENTS.md`. Match existing heading levels and voice — don't restructure unrelated content.

**Dedicated-doc case:**
1. Draft the full contents of `docs/agents/<topic>.md` (starting with a top-level `# Title` heading).
2. Draft the `AGENTS.md` change:
   - If `AGENTS.md` already has a file-tree listing of `docs/agents/` (a fenced block listing files with trailing `# comment` descriptions), add a line for the new file there, keeping the description short and aligned with the others.
   - If no such listing exists yet, create one (see the `facility` repo's own `AGENTS.md` for the pattern), plus a one-line pointer sentence like: `See **[docs/agents/<topic>.md](docs/agents/<topic>.md)** for <short description>.`
   - If `AGENTS.md` doesn't exist yet, create a minimal one: a title, a one-paragraph repo description if inferable, and the `docs/agents/` section pointing at the new file.

## Phase 6 — Preview and Confirm

Show the user, verbatim, everything that will be written:
- The new/updated `AGENTS.md` content (or diff).
- The full contents of any new `docs/agents/<topic>.md` file.

Ask the user to choose:
- **Apply** — write the files as drafted
- **Revise** — take feedback and redraft before asking again
- **Cancel** — do nothing

Never write or edit any file before the user confirms.

## Phase 7 — Apply

- `mkdir -p docs/agents` if creating a new doc file there.
- `Write`/`Edit` `AGENTS.md` and (if applicable) `docs/agents/<topic>.md` exactly as confirmed.
- Report back which file(s) changed and a one-line summary of what was recorded.
