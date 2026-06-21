# Facility — Agent Guide

This repo is a collection of Claude Code skills and supporting documentation for agentic development. Skills live in `skills/<name>/` and are installed into Claude Code as `/<name>` slash commands.

## Repo layout

```
skills/<name>/
  SKILL.md              # skill entry point (loaded by Claude Code)
  references/           # detailed flag/command reference docs (optional)
docs/agents/            # agent-facing guidance for working in this repo
scripts/                # install helpers
```

## Drafting skills

When creating or editing a skill, see **[docs/agents/drafting_skills.md](docs/agents/drafting_skills.md)** for repo-specific conventions and patterns synthesized from existing skills.

The authoritative Claude Code skills reference is at **https://code.claude.com/docs/en/skills**.

## Installing skills locally

```bash
./scripts/install.sh           # symlink all skills
./scripts/install.sh shortcut  # symlink one skill
./scripts/install.sh --dry-run # preview without changes
```

Skills are symlinked, so edits in this repo are reflected immediately.
