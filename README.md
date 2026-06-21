# Facility

A collection of Agents, Skills, and Markdown tooling for Agentic development.

## Installation

Clone the repo, then symlink the skills you want into your Claude skills directory:

```bash
# Install all skills
./scripts/install.sh

# Install a specific skill
./scripts/install.sh shortcut

# Preview what would be linked without making changes
./scripts/install.sh --dry-run
```

Skills are symlinked (not copied), so any edits you make in this repo are reflected immediately without re-running the installer.

**Requirements:** Claude Code v2.1.145+, Node.js (for skills that depend on CLI tools).

## Skills

Skills extend Claude Code with domain-specific knowledge and commands. Each skill lives in `skills/<name>/` and is available as `/<name>` in Claude Code once installed.

| Skill | Command | Description |
|-------|---------|-------------|
| [shortcut](skills/shortcut/) | `/shortcut` | Work with Shortcut project management via `shortcut-cli` |
| [gh](skills/gh/) | `/gh` | Work with GitHub via the `gh` CLI — PRs, issues, Actions, releases |
| [glab](skills/glab/) | `/glab` | Work with GitLab via the `glab` CLI — MRs, issues, pipelines, releases |

### shortcut

Integrates with [shortcut-cli](https://github.com/shortcut-cli/shortcut-cli) to let Claude search, view, create, and update Shortcut stories, epics, iterations, labels, teams, objectives, and docs.

**Prerequisite:**
```bash
npm install -g @shortcut-cli/shortcut-cli
short install
```

**What it covers:**
- Search and filter stories by owner, state, type, epic, iteration, label, and more
- View and update stories (state, estimate, title, comment, deadline, owners, labels)
- Create stories with full field support
- Create git branches from stories (`--git-branch`, `--git-branch-short`)
- Manage epics, iterations, labels, teams, objectives, and docs
- Raw API access via `short api`

Detailed flag reference is in [`skills/shortcut/references/`](skills/shortcut/references/).

### gh

Integrates with the [GitHub CLI](https://cli.github.com/) (`gh`) to let Claude work with pull requests, issues, Actions workflow runs, repos, releases, gists, and secrets.

**Prerequisite:**
```bash
# macOS
brew install gh
# Linux / other: https://github.com/cli/cli#installation
gh auth login
```

**What it covers:**
- Create, view, list, review, merge, and comment on pull requests
- Create, view, list, close, and comment on issues
- Monitor and re-run Actions workflow runs; stream logs
- Clone, fork, and manage repositories
- Create and manage releases and gists
- Manage Actions secrets
- Raw REST and GraphQL API access via `gh api`

Detailed flag reference is in [`skills/gh/references/`](skills/gh/references/).

### glab

Integrates with the [GitLab CLI](https://gitlab.com/gitlab-org/cli) (`glab`) to let Claude work with merge requests, issues, CI/CD pipelines, releases, and CI/CD variables.

**Prerequisite:**
```bash
# macOS
brew install glab
# Linux / other: https://gitlab.com/gitlab-org/cli#installation
glab auth login
```

**What it covers:**
- Create, view, list, approve, merge, and comment on merge requests
- Create, view, list, close, and comment on issues
- Trigger pipelines, view status, and stream job logs; interactive TUI via `glab ci view`
- Clone and fork projects
- Create and manage releases
- Manage CI/CD variables (project and group level)
- Raw REST API access via `glab api`

Detailed flag reference is in [`skills/glab/references/`](skills/glab/references/).

## (Un)License

This project is released into the public domain under the [Unlicense](UNLICENSE).
