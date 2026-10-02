# Drafting Skills

Reference: [Claude Code Skills docs](https://code.claude.com/docs/en/skills) · [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

A skill is a `SKILL.md` file (plus optional supporting files) in `skills/<name>/`. Once installed, it is available as `/<name>` in Claude Code and is loaded into the model's context when triggered.

---

## File structure

```
skills/<name>/
  SKILL.md              # required — loaded by Claude Code
  references/           # optional — overflow docs linked from SKILL.md
    story-commands.md
    resource-commands.md
```

Keep the SKILL.md body under 500 lines. Move large flag tables, schemas, and examples into `references/` files and link to them from SKILL.md. They take up no context until read, which keeps the main file easy to scan.

- Link every reference file directly from SKILL.md. Don't chain references (SKILL.md → a.md → b.md), because nested files tend to get only partially read.
- Give any reference file longer than 100 lines a `## Contents` list at the top, so a partial read still shows everything the file covers.
- Name files and split them by domain (`story-commands.md`, `resource-commands.md`), not by generic labels (`doc2.md`).

---

## SKILL.md frontmatter

```yaml
---
name: skill-name
description: Does X and Y. Use when the user mentions A, B, or C.
when_to_use: Trigger description shown alongside the skill in system reminders.
allowed-tools: Bash(command *), Read, Edit   # tool allowlist for this skill
---
```

- **`name`** — lowercase letters, numbers, and hyphens only, max 64 characters, and no "anthropic" or "claude". Match the directory name and the naming pattern of the other skills in this repo.
- **`description`** — max 1,024 characters, in the third person ("Drafts commit messages…", not "I can help…" or "You can use…"). State what the skill does and when to use it, including the trigger terms a user would actually say. Claude picks a skill from many candidates by this field, so write it specifically. Vague descriptions ("Helps with documents") don't get picked.
- **`when_to_use`** — more specific trigger language that complements `description` for routing decisions.
- **`allowed-tools`** — restrict the skill to the tools it needs. Use glob patterns for CLI tools (e.g., `Bash(short *)` allows only `short` subcommands). Omit to allow all tools.

---

## Writing the body

- **Include only what Claude lacks.** Assume a capable reader. Leave out explanations of common tools, formats, and concepts, and keep only repo-specific defaults, gotchas, and decisions. Cut any paragraph that doesn't justify its token cost.
- **Match the freedom to how fragile the task is.** For judgment tasks (review, triage), give heuristics and let context decide. For fragile or sequence-critical operations, give the exact command and say not to change it.
- **Give one default, not a menu.** Name the preferred tool or approach, and add an escape hatch only for the specific case that needs something else.
- **Use one term per concept** throughout the skill and its references.
- **Leave out time-sensitive statements** ("before August, use…"). Document the current method, and move deprecated approaches into a collapsed "Old patterns" `<details>` block if they're still needed.
- **Number the steps of multi-step workflows.** For long or skip-prone workflows, give a checklist that Claude copies into its response and checks off.
- **Build in feedback loops** for steps where quality matters: validate → fix → re-validate, and proceed only once validation passes. The validator can be a script or a checklist in a reference doc.
- **Templates and examples:** give an exact template when the output format is strict, and a "sensible default, adapt as needed" template otherwise. When style matters (commit messages, PR bodies), give input → output example pairs.
- **MCP tools:** refer to them by fully qualified name, so they still resolve when several servers are connected.

---

## Bundled scripts

When a skill includes scripts:

- Handle errors in the script, with messages that name the problem and the valid alternatives, rather than failing and leaving Claude to diagnose it.
- Explain every constant (timeouts, retry counts) in a comment, and leave out unexplained magic numbers.
- Say explicitly whether Claude should **run** the script ("Run `scripts/validate.sh`…") or **read** it as reference.
- Use a script, not generated code, for deterministic operations such as validation and formatting.
- List required binaries in SKILL.md, and check that they're installed before relying on them.
- For batch or destructive operations, use plan → validate → execute: write the intended changes to an intermediate file, validate it with a script, then apply.

---

## Testing a skill

After `./scripts/install.sh --skill=<name>`, run the skill in a fresh session on realistic requests. Check that it triggers when it should and stays quiet when it shouldn't, and watch which files Claude reads. If a reference is never opened, signal it better or remove it. If one is read on every run, move its content into SKILL.md. If the skill will run on smaller models, check that it gives enough guidance for them.

---

## Standard sections

### Announce at start

Every skill should begin with an announce line so the user knows which skill is active:

```markdown
**Announce at start:** "I'm using the <name> skill to..."
```

### Authentication (if applicable)

Cover how to detect and recover from auth failures without storing credentials:

```markdown
## Authentication

If commands fail with auth errors:
1. Check config: `<command> status`
2. Instruct user to run `<command> login` interactively — never attempt login on their behalf
3. Never store tokens in code or commit them
```

### Defaults

Capture non-obvious defaults that the model would otherwise have to discover by running commands:

- URL formats for linking to created resources
- Default field values
- Environment variables that control behavior

### Command execution policy

Split commands into read-only (run freely) vs. mutations (require explicit user confirmation):

```markdown
## Command Execution Policy

**Run freely (read-only):** `cmd list`, `cmd view`, `cmd search`

**Require explicit user confirmation:**
- `cmd create` — creates a new resource
- `cmd delete` — destructive, always confirm
```

Destructive operations (delete, hard reset) should always require confirmation regardless of context.

### Quick reference

Provide copy-pasteable examples organized by task, not by command. Users scan for what they're trying to accomplish:

```markdown
## Quick Reference

### Do the common thing
\`\`\`bash
cmd search -t "keyword"
cmd search -s "In Progress" -o <owner>
\`\`\`

### Create a resource
\`\`\`bash
cmd create -t "Title" -s "State"
\`\`\`
```

### Format variables (if the tool supports them)

When the underlying CLI supports output format templates, document the variables in a table:

```markdown
## Format Variables

| Variable | Description |
|----------|-------------|
| `%id`    | Resource ID |
| `%t`     | Title       |
```

### Detailed reference (link to `references/`)

At the bottom of SKILL.md, link out to the detailed reference docs rather than inlining them:

```markdown
## Detailed Reference

- **Core commands** — [references/core-commands.md](references/core-commands.md)
- **Resource commands** — [references/resource-commands.md](references/resource-commands.md)
```

---

## Skill types: reference vs. task

Skills fall into two broad types. Knowing the type determines which frontmatter fields to reach for.

**Reference skills** add knowledge or tool access Claude uses on its own. Claude loads them automatically when your conversation matches the description.

```yaml
---
description: Work with Shortcut stories and epics via the short CLI.
when_to_use: Triggered when the user mentions Shortcut, stories, epics, or iterations.
allowed-tools: Bash(short *)
---
```

**Task skills** describe a specific workflow the user explicitly triggers — commits, PR drafts, deploys. Add `disable-model-invocation: true` to prevent Claude from running them automatically, and to keep their description out of Claude's context until invoked.

```yaml
---
description: Draft and apply a pull request description from the current branch.
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh *)
---
```

Task skills should always:
- Show the **complete proposed output** (commit message, PR body, etc.) before taking any write action
- Wait for explicit user confirmation before running mutations (`git commit`, `gh pr edit`, etc.)
- Ask before staging or modifying anything the user hasn't explicitly touched

---

## Patterns from the shortcut skill

The [`skills/shortcut/`](../../skills/shortcut/) skill is the canonical example. Key decisions made there:

- **Granular `allowed-tools`:** `Bash(short *)` prevents the skill from running arbitrary shell commands — it can only invoke `short` subcommands.
- **Confirmation table by risk level:** Read operations (search, view, list) run freely; any write or delete requires a confirmation step.
- **References split by domain:** `story-commands.md` covers the story/search/create surface; `resource-commands.md` covers everything else (epics, iterations, labels, teams, etc.). SKILL.md has a Quick Reference for the most common operations and links to the detail files for everything else.
- **Format variable table in SKILL.md:** The `%id`, `%t`, `%s`, … variables are documented inline because they appear in nearly every example. The full annotated table lives in the reference files.
- **Branch integration documented explicitly:** The git branch flags (`--git-branch`, `--git-branch-short`) are called out as their own sub-section because they are a non-obvious but high-value feature.

---

## Checklist for a new skill

- [ ] Frontmatter — reference skill: `name`, `description`, `when_to_use`, `allowed-tools`;
      task skill: `description`, `disable-model-invocation: true`, `allowed-tools`
- [ ] `allowed-tools` covers every tool and command the body actually instructs, including
      `Read` when the skill reads an agent file and each binary in a prescribed pipeline
- [ ] Announce at start line
- [ ] Authentication section (if the tool requires credentials)
- [ ] Defaults section (URLs, env vars, implicit field values)
- [ ] Command execution policy (read-only vs. confirm-before-mutate)
- [ ] Quick reference with copy-pasteable examples organized by task
- [ ] Format variables table (if applicable)
- [ ] `references/` files for detailed flag tables, linked from SKILL.md
- [ ] Entry in `README.md` skills table
- [ ] `name` is lowercase-hyphenated and matches the directory
- [ ] `description` is third person, states what + when, includes trigger terms, ≤1,024 chars
- [ ] SKILL.md body under 500 lines; references one level deep; reference files >100 lines have a `## Contents` list
- [ ] No time-sensitive statements; consistent terminology
- [ ] Multi-step workflows numbered; validation loops on quality-critical steps
- [ ] Bundled scripts handle their own errors, explain constants, and are marked run-vs-read
- [ ] Tested in a fresh session with realistic requests
