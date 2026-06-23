# Drafting Sub-Agents

Reference: [Claude Code Sub-Agents docs](https://code.claude.com/docs/en/sub-agents)

A sub-agent is a single markdown file in `agents/<name>.md`. It defines a self-contained prompt that an orchestrating skill or agent passes to the Agent tool — the file content IS the prompt. Sub-agents run in an isolated context with no memory of the parent conversation, so everything they need must be in the prompt.

Sub-agents are distinct from skills:

| | Skills (`skills/<name>/SKILL.md`) | Sub-Agents (`agents/<name>.md`) |
|---|---|---|
| Invoked by | User (`/<name>`) or Claude auto-trigger | Parent skill/agent via Agent tool |
| Context | Loaded into main conversation | Isolated — fresh context per invocation |
| Interactive | Yes — back-and-forth with user | No — returns a single result |
| Installed to | `~/.claude/skills/` | `~/.claude/agents/` |

Use sub-agents for work that is heavy, read-only, and returns a structured result: reading large diffs, gathering context, drafting text. Keep interactive decisions and write operations in the parent skill.

---

## File structure

```
agents/
  git-draft-commit.md   # drafts a commit message from staged diff
  git-draft-pr.md       # drafts a PR/MR description from branch context
```

Each agent is a single `.md` file. No subdirectories, no frontmatter — just the prompt.

---

## Prompt structure

Every agent prompt should follow this layout:

```markdown
# agent-name

One sentence: what this agent does and what it returns.

## Steps

Numbered list of commands to run, in order.

## Rules / constraints

Bullet list of rules governing the output (style, length, what to omit).

## Output

The exact JSON schema to return. Include an example.
```

### Purpose line

The first paragraph after the title is the agent's contract — what goes in and what comes out. Write it as a single sentence:

> You are a subagent. Your only job is to <do X>. Return <Y> and nothing else.

This framing keeps the agent on-task and prevents it from adding unrequested commentary.

### Steps

List the exact shell commands to run, in order. Include the full command string so the agent doesn't have to construct it:

```markdown
## Steps

1. `git diff --cached --stat` — staged file list
2. `git diff --cached` — full staged diff
3. `git log --oneline -10` — recent commit style
```

Prefer explicit commands over descriptions like "check the diff" — the agent has no context from the parent conversation.

### Output

Always return JSON. Define the schema with an example block:

```markdown
## Output

Return a single JSON object — no markdown wrapper, no explanation, nothing else:

\`\`\`json
{
  "field": "value"
}
\`\`\`
```

Ending with "nothing else" is important: without it agents often add a summary sentence after the JSON.

---

## Calling a sub-agent from a skill

In the parent skill's `SKILL.md`:

1. Add `Agent` to `allowed-tools` in the frontmatter
2. Tell Claude to read the agent file and pass its contents as the prompt:

```markdown
Read `agents/git-draft-commit.md` and spawn an Agent with its full contents as the prompt.
```

3. Document the expected JSON shape inline so Claude knows what to extract:

```markdown
The agent returns:

\`\`\`json
{
  "staged_files": [...],
  "proposed_message": "...",
  "concerns": []
}
\`\`\`
```

Keeping the schema in both the agent file and the calling skill makes the contract explicit on both ends.

---

## Patterns from existing agents

### git-draft-commit

Reads `git diff --cached` and `git log --oneline -10`, returns a proposed single-line commit message matched to repo style. Runs only `git` commands. The parent `/commit` skill handles all staging decisions and user confirmation before and after.

### git-draft-pr

Reads the full branch diff, detects platform (GitHub/GitLab) from the remote URL, checks for an existing open PR/MR, parses the branch name for a ticket reference, and returns a complete PR/MR description draft plus metadata. The parent `/pr` skill handles confirmation and the create/edit mutation.

Key decisions:
- **Structured JSON output** — the parent skill extracts only what it needs (draft text, existing PR number, suggested title) without parsing prose
- **All heavy I/O in the agent** — `git diff`, `git log`, `gh pr list` stay out of the main context window
- **Write operations stay in the parent** — the agent never calls `git commit`, `gh pr create`, etc.

---

## Checklist for a new sub-agent

- [ ] File at `agents/<name>.md`
- [ ] Purpose line: "You are a subagent. Your only job is to … Return … and nothing else."
- [ ] Steps: explicit shell commands in order
- [ ] Rules / constraints section if output has style requirements
- [ ] Output: JSON schema with example block ending in "nothing else"
- [ ] Parent skill updated: `Agent` in `allowed-tools`, reads agent file, documents expected JSON shape
- [ ] Entry in `README.md` agents table (if user-visible)
- [ ] Installed via `./scripts/install.sh`
