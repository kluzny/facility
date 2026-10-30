# jq recipes and data formats

## Contents

- Sources and record types
- Noise filters
- Joins and splits
- Working-directory files
- Ad hoc queries
- Pitfalls

Read this when a question isn't answered by `stats.sh` and you need an ad hoc query against the working directory. Query the workdir files, not `~/.claude/projects`, so you work from the filtered window.

## Sources and record types

| Source | Covers | Key fields |
|---|---|---|
| `~/.claude/history.jsonl` | every typed prompt, long retention | `display` (prompt text), `project` (path), `timestamp` (epoch **ms**), `sessionId`, `pastedContents` |
| `~/.claude/projects/<encoded-cwd>/<session>.jsonl` | full main-thread transcript, kept for `cleanupPeriodDays` (default 30) | one record per line, `type` below, `timestamp` is ISO-8601 |
| `<session>/subagents/agent-<id>.jsonl` | one subagent's transcript | same record types, `isSidechain: true` |
| `<session>/subagents/agent-<id>.meta.json` | how the subagent was spawned | `agentType`, `description`, `model` (requested), `toolUseId` |

The transcript `type` values that matter:

- **`user`**: either a typed prompt (`message.content` is a string, or an array with `text` parts) or tool results (`message.content` is an array of `tool_result`, and the record carries `toolUseResult`).
- **`assistant`**: `message.content[]` holds `text` and `tool_use` items (`id`, `name`, `input`). `message.model` is the model that actually ran.
- **Others to ignore**: `mode`, `permission-mode`, `file-history-snapshot`, `attachment`, `api-request*`, `summary`.

The encoded dir name replaces non-alphanumerics in the launch path with `-`. It's lossy, so use the records' `cwd` field to recover the project path.

## Noise filters

A `user` record is a typed prompt only if all of these hold:

- `isMeta` is not true, `toolUseResult` is absent, and `isSidechain` is not true;
- the text doesn't start with `<local-command`, `<system-reminder`, `<task-notification`, `<command-` (slash-command wrappers), `[Request interrupted` or `This session is being continued`;
- it isn't a session-control command: `/exit`, `/clear`, `/new`, `/compact`, `/model`. History records `/new` where transcripts record `/clear`, because `/new` is the built-in alias.

Transcripts record slash commands as `<command-name>/x</command-name>`. `extract.sh` routes them to `slash.tsv`, not the prompt files.

## Joins and splits

**Rejections.** A rejected tool use is a `tool_result` with `is_error: true` whose text starts `The user doesn't want to proceed`. Plain `is_error` results are mostly `Exit code 1` failures, not rejections. Join on `tool_result.tool_use_id` = `tool_use.id` to find which call was rejected. Text after `the user said:` is the user's stated reason. On `AskUserQuestion` a rejection means the user wanted to clarify, not a refusal. On `ExitPlanMode` it means plan feedback.

**Main vs subagent.** Count `isSidechain: true` tool use separately. Subagent Bash volume otherwise inflates the main-thread picture.

**Requested vs actual model.** The `model` passed to the Agent tool overrides an agent file's frontmatter, so trust `message.model` in the subagent transcript. `subagent_models.tsv` records both.

## Working-directory files

All TSVs are produced with jq `@tsv`, so tabs and newlines inside fields appear as `\t` and `\n`.

| File | Columns / shape |
|---|---|
| `meta.tsv` | key, value: source, days, project filter, history and transcript date ranges, prompts dropped from chunks |
| `projects.tsv` | slug, path, history prompt count |
| `history.tsv` | project slug, date, prompt (all projects, chronological) |
| `h_<slug>.tsv` | same, one project |
| `p_<slug>.tsv` | project, session, ISO timestamp, prompt (transcript prompts) |
| `slash.tsv` | project, session, date, command (transcripts) |
| `tools.jsonl` | `{project, session, sidechain, ts, id, name, input}`; string inputs truncated to 300 chars |
| `bash_cmds.txt` | project, sidechain, command (up to 4000 chars) |
| `rejections.tsv` | project, session, tool, input summary, stated reason |
| `interrupts.tsv` | project, session, date |
| `subagent_models.tsv` | project, agent type, description, requested model, actual model |
| `sample.tsv` | evenly spaced history prompts for `--quick` |
| `chunks/chunk_NN.tsv` | history rows packed by project for fan-out |
| `allow.tsv` | project, settings file, allow rule (written by `inventory.sh`) |
| `forbidden.tsv` | project, avoided command, preferred command, source file, rule text (written by `inventory.sh`) |

## Ad hoc queries

Use full paths (`<workdir>/…`) rather than `cd`ing into the working directory.

Calls to a given tool, by project:

```bash
jq -r 'select(.name == "<Tool>") | .project' <workdir>/tools.jsonl | sort | uniq -c | sort -rn
```

Inputs of a given skill or agent type:

```bash
jq -r 'select(.name == "Skill") | .input | tojson' <workdir>/tools.jsonl | sort | uniq -c | sort -rn | head
jq -r 'select(.name == "Agent" and .input.subagent_type == "<type>") | .input.description' <workdir>/tools.jsonl
```

Bash commands matching a pattern, in one project:

```bash
awk -F'\t' '$1 == "<project>" && $3 ~ /<regex>/' <workdir>/bash_cmds.txt | cut -f3 | cut -c1-160 | head -20
```

Prompts around a theme:

```bash
awk -F'\t' 'tolower($3) ~ /<word>/' <workdir>/history.tsv | cut -c1-200 | head -30
```

Sessions with the most interruptions:

```bash
cut -f1,2 <workdir>/interrupts.tsv | sort | uniq -c | sort -rn | head
```

## Pitfalls

- Encoded project dirs start with `-`. Prefix them with `./`, or `find`, `du` and `basename` read them as flags.
- `find` may be aliased to another tool. Use `command find`.
- In zsh, a word starting with `=` is expanded, so `echo ======` fails. Use `echo '---'`.
- Transcript `timestamp` has fractional seconds. Strip them before `fromdateiso8601`.
