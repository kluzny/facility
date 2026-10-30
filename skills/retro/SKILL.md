---
name: retro
description: Review Claude Code session history and transcripts for recurring asks, workflows, skill/subagent usage and friction, and propose skills, scripts, hooks and guidance. Report only; changes nothing.
argument-hint: "[days] [--project NAME] [--quick]"
disable-model-invocation: true
allowed-tools: Read Grep Glob Write Agent Bash(jq *) Bash(awk *) Bash(cut *) Bash(sort *) Bash(uniq *) Bash(head *) Bash(wc *) Bash(~/.claude/skills/retro/scripts/*)
---

**Announce at start:** "Running /retro: mining Claude Code history and transcripts for recurring work and friction. This reports only and changes nothing."

## Arguments

- `[days]`: a bare number N (or `--days N`) limits the run to the last N days. The default is all history. Transcripts only cover the retention window regardless.
- `--project NAME`: only projects whose path contains NAME.
- `--quick`: skip fan-out and work from the stats plus a 200-prompt sample.

## Command execution policy

**Run freely (read-only):** the bundled scripts, `jq`/`awk`/`cut`/`sort`/`uniq`/`head`/`wc` against the working directory, and reading skill, agent, settings and guidance files.

**Never:**
- Edit skills, agents, settings, hooks or project files. Proposals are for the user to pick.
- Write anywhere except the working directory and the optional report copy in step 6.
- Send transcript content to an external service, or quote anything that looks like a credential.

**Requires:** `jq`. The scripts check for it and exit if it's missing.

## Phases

Copy this checklist into your response and tick it off:

```
- [ ] 1 Extract
- [ ] 2 Stats
- [ ] 3 Inventory
- [ ] 4 Fan-out (skip with --quick)
- [ ] 5 Verify
- [ ] 6 Report
- [ ] 7 Trend (if a previous report exists)
- [ ] 8 Stop and ask
```

### 1. Extract

Run `~/.claude/skills/retro/scripts/extract.sh [N] [--project NAME]`, passing the days argument through as given. It creates a fresh `mktemp` working directory and prints its path as the last line. Every later step reads from there, by full path. The file formats are in [references/jq-recipes.md](references/jq-recipes.md).

If it prints `no records matched`, report that along with the filters used, and stop.

### 2. Stats

Run `~/.claude/skills/retro/scripts/inventory.sh <workdir>` first, because it writes `allow.tsv` and `forbidden.tsv`, which stats reads. Then run `~/.claude/skills/retro/scripts/stats.sh <workdir>`. Work from these markdown tables. Don't read the raw JSONL. For a question the tables don't answer, run an ad hoc query from the recipes file.

### 3. Inventory

The `inventory.sh` output from step 2 lists:
- user skills (with sources) and agents (with models), each with its description;
- user settings: permissions, deny rules, hooks, plugins, `cleanupPeriodDays`;
- per-project guidance files, `.claude/` skills, agents and settings;
- heuristic "avoid X / prefer Y" rules taken from project guidance.

Read individual files only when a finding depends on their content.

### 4. Fan-out

Skip this step for `--quick`. Instead, read `<workdir>/sample.tsv` and the per-project `h_<slug>.tsv` files for the top projects.

Otherwise, Glob `<workdir>/chunks/*.tsv`. Each chunk is ≤350KB of history rows packed by project. There are at most 4 chunks, and `meta.tsv` records how many older prompts were dropped to fit. Read `~/.claude/agents/retro-chunk-reader.md`, then spawn one Agent per chunk **in a single message** so they run in parallel. Each prompt is that file's full contents with this appended:

```
Chunk file: <workdir>/chunks/chunk_NN.tsv
Projects: <slugs in this chunk>
Inventory: <skill and agent names with one-line descriptions, hook events, from step 3>
```

Each agent returns:

```json
{"chunk": "", "lines_read": 0,
 "taxonomy": [{"category": "", "count": 0, "examples": [""]}],
 "repeated_prompts": [{"prompt": "", "project": "", "count": 0}],
 "workflows": [{"sequence": "", "project": "", "frequency": ""}],
 "friction": [{"theme": "", "count": 0, "quotes": [""]}],
 "commands": [{"command": "", "project": "", "purpose": "", "count": 0}],
 "candidates": [{"kind": "skill|script|hook|guidance|skill-change", "name": "", "scope": "", "trigger": "", "behavior": "", "evidence": ""}]}
```

If an agent's `lines_read` falls well short of the chunk's line count (`wc -l`), note the gap in the report. Merge the results across chunks: sum the counts of matching categories, dedupe candidates by intent, and drop any candidate that duplicates an inventory item, recasting it as a `skill-change` if it adds something.

### 5. Verify

Before a structural claim goes into the report, check it with a direct `Read` or `Grep` of the file in question. Structural claims include things like "a guidance file says X", "a config is wrong", "an agent lacks frontmatter" or "a skill is unused".
- Check each guidance-rule bypass row against its rule text in `inventory.sh` output. The rule may be scoped, for example to "via Bash tool" or "in production", or the match may be a false positive.
- For a skill reported as unused, also check the slash-command table, since a skill can run by slash command without a `Skill` tool call.
- Drop claims you can't check, or mark them **unverified**.

### 6. Report

Print the report using [references/report-template.md](references/report-template.md). Give each finding an evidence count and short quotes. State the sample: the history range versus the transcript range, the filters used, and that counts are regex-based and approximate. If `cleanupPeriodDays` is unset or low, point out that transcript-level findings cover only that window.

Save a copy to `<cwd>/tmp/retro-YYYY-MM-DD.md` only if `<cwd>/tmp/` already exists or the user asks.

### 7. Trend

Use Glob to find the latest `<cwd>/tmp/retro-*.md` before today's. If one exists, compare its key counts with this run's:
- rejections;
- edits that bypass Edit/Write;
- guidance-rule bypasses;
- interruptions;
- repeated corrections.

Say which earlier proposals appear to have landed (a new skill now in use, a bypass count that dropped) and which didn't move.

### 8. Stop

End with **"Which items should I implement?"** Don't implement anything in this skill run.

## Detailed reference

- **Data sources, workdir files and ad hoc queries**: [references/jq-recipes.md](references/jq-recipes.md)
- **Report structure and proposal rules**: [references/report-template.md](references/report-template.md)
