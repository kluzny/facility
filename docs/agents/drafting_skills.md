# Drafting Skills

Reference: [Claude Code Skills docs](https://code.claude.com/docs/en/skills)

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

Split large flag tables into `references/` files and link to them from SKILL.md. This keeps the primary skill file scannable and avoids filling the context window with rarely-needed detail.

---

## SKILL.md frontmatter

```yaml
---
name: Human-readable name
description: One-line description used in `/help` output and system reminders.
when_to_use: Trigger description shown alongside the skill in system reminders.
allowed-tools: Bash(command *), Read, Edit   # tool allowlist for this skill
---
```

- **`name`** — displayed in `/<name>` listings.
- **`description`** — shown in the skills list; keep it to one sentence that states what the skill does and when.
- **`when_to_use`** — more specific trigger language; complements `description` for routing decisions.
- **`allowed-tools`** — restrict the skill to only the tools it needs. Use glob patterns for CLI tools (e.g., `Bash(short *)` allows only `short` subcommands). Omit to allow all tools.

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

## Patterns from the shortcut skill

The [`skills/shortcut/`](../../skills/shortcut/) skill is the canonical example. Key decisions made there:

- **Granular `allowed-tools`:** `Bash(short *)` prevents the skill from running arbitrary shell commands — it can only invoke `short` subcommands.
- **Confirmation table by risk level:** Read operations (search, view, list) run freely; any write or delete requires a confirmation step.
- **References split by domain:** `story-commands.md` covers the story/search/create surface; `resource-commands.md` covers everything else (epics, iterations, labels, teams, etc.). SKILL.md has a Quick Reference for the most common operations and links to the detail files for everything else.
- **Format variable table in SKILL.md:** The `%id`, `%t`, `%s`, … variables are documented inline because they appear in nearly every example. The full annotated table lives in the reference files.
- **Branch integration documented explicitly:** The git branch flags (`--git-branch`, `--git-branch-short`) are called out as their own sub-section because they are a non-obvious but high-value feature.

---

## Checklist for a new skill

- [ ] Frontmatter: `name`, `description`, `when_to_use`, `allowed-tools`
- [ ] Announce at start line
- [ ] Authentication section (if the tool requires credentials)
- [ ] Defaults section (URLs, env vars, implicit field values)
- [ ] Command execution policy (read-only vs. confirm-before-mutate)
- [ ] Quick reference with copy-pasteable examples organized by task
- [ ] Format variables table (if applicable)
- [ ] `references/` files for detailed flag tables, linked from SKILL.md
- [ ] Entry in `README.md` skills table
