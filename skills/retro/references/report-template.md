# Report template

Use this structure for the final report. Fill every section from `stats.sh`, `inventory.sh`, chunk-reader results and your own verification. Omit a subsection only if it has nothing to say, and say so in one line.

Give each finding an evidence count (from the stats tables or merged chunk results) and, where it helps, one or two short verbatim quotes. Mark counts as approximate. Mark any claim you couldn't check with a direct read as **unverified**.

```markdown
# Retro — <YYYY-MM-DD>

**Sample:** history <first> .. <last> (<N> prompts across <M> projects);
transcripts <first> .. <last> (<S> sessions, retention-limited).
Filters: days=<N|all>, project=<NAME|all>, mode=<full|quick>.
Counts are regex-based and approximate.

## Part 1 — Analysis

### 1. Where work happens
Projects ranked by prompts and sessions; one line on what each is used for.

### 2. Top asks
Ask taxonomy merged across chunks: category, approx count, 1–2 example prompts.
Repeated near-verbatim prompts (from stats and chunk readers).

### 3. Workflows
Multi-step sequences that recur (e.g. "<read ticket> → <plan> → <implement> → <commit> → <pr>"), with frequency.

### 4. Skill and subagent usage
Which skills and agents ran and how often. Which installed ones never ran in the window.
Requested vs actual subagent models, flagging any surprise.

### 5. How Claude works
Tool mix (main vs subagent), Bash command ranking, edits that bypass Edit/Write,
test output piped through filters, notable CLI/make/script usage.

### 6. Friction
Rejections (by tool, with stated reasons), interruptions, repeated corrections (quoted),
guidance-rule bypasses (each verified against its rule text), unused allow rules.

## Part 2 — Proposals

Each item: **<letter><n>. <title>** — what to do, why (evidence pointer to Part 1), scope (global or `<project>`), effort (S/M/L).

### A. Hooks and settings
### B. New skills
### C. Changes to existing skills or agents
### D. Scripts
### E. Guidance (CLAUDE.md / AGENTS.md / docs)

## Trend since <previous report date>
Only when a previous report exists. Key counts then vs now (rejections, Edit bypasses,
guidance-rule bypasses, interruptions, repeated corrections), and which earlier proposals appear to have landed.

## Recommended order
A short ordered list of the proposals with the best evidence-to-effort ratio first.

**Which items should I implement?**
```

## Proposal rules

- Don't re-propose an existing skill, agent, hook or rule from the inventory. Propose a change to it under C or E instead.
- Prefer the lightest fix that addresses the evidence: guidance before a skill, and a skill before a hook. Use a hook only when guidance has demonstrably been ignored (a repeated bypass count).
- Tie every proposal to at least one Part 1 finding with a count.
