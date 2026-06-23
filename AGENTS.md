# Facility — Agent Guide

This repo is a collection of Claude Code skills and supporting documentation for agentic development. Skills live in `skills/<name>/` and are installed into Claude Code as `/<name>` slash commands.

## Repo layout

```
skills/<name>/
  SKILL.md              # skill entry point (loaded by Claude Code)
  references/           # detailed flag/command reference docs (optional)
docs/agents/            # agent-facing guidance for working in this repo
scripts/                # install/uninstall helpers
```

## Drafting skills

When creating or editing a skill, see **[docs/agents/drafting_skills.md](docs/agents/drafting_skills.md)** for repo-specific conventions and patterns synthesized from existing skills.

The authoritative Claude Code skills reference is at **https://code.claude.com/docs/en/skills**.

## Installing skills locally

```bash
./scripts/install.sh                  # symlink all skills
./scripts/install.sh --skill=all      # same as above, explicit
./scripts/install.sh --skill=shortcut # symlink one skill
./scripts/install.sh --dry-run        # preview without changes
```

Skills are symlinked, so edits in this repo are reflected immediately.

## Uninstalling

```bash
./scripts/uninstall.sh                  # remove all our symlinks
./scripts/uninstall.sh --skill=all      # same as above, explicit
./scripts/uninstall.sh --skill=shortcut # remove one skill
./scripts/uninstall.sh --dry-run        # preview without changes
```

Only removes symlinks that point back to this repo; warns about anything else.
