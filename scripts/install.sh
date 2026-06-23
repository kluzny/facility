#!/usr/bin/env bash
# Symlink Claude skills and sub-agents from this repo into ~/.claude/
# Usage:
#   ./scripts/install.sh [--dry-run] [--skill=name|all] [--agent=name|all]
#
# If no --skill or --agent flags are given, installs everything.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"
SKILLS_DEST="$HOME/.claude/skills"
AGENTS_SRC="$REPO_ROOT/agents"
AGENTS_DEST="$HOME/.claude/agents"

DRY_RUN=false
SKILL_TARGETS=()
AGENT_TARGETS=()

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    --skill=*)
      SKILL_TARGETS+=("${arg#--skill=}")
      ;;
    --agent=*)
      AGENT_TARGETS+=("${arg#--agent=}")
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

run() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

link_skill() {
  local name="$1"
  local src="$SKILLS_SRC/$name"
  local dest="$SKILLS_DEST/$name"

  if [[ ! -f "$src/SKILL.md" ]]; then
    echo "SKIP: skill/$name (no SKILL.md found at $src)"
    return 0
  fi

  echo "link: $dest → $src"

  if [[ -L "$dest" ]]; then
    run ln -sfn "$src" "$dest"
  elif [[ -e "$dest" ]]; then
    echo "  WARN: $dest exists and is not a symlink — skipping (remove it manually to replace)"
  else
    run mkdir -p "$SKILLS_DEST"
    run ln -s "$src" "$dest"
  fi
}

link_agent() {
  local name="$1"
  local src="$AGENTS_SRC/$name.md"
  local dest="$AGENTS_DEST/$name.md"

  if [[ ! -f "$src" ]]; then
    echo "SKIP: agent/$name (no $src found)"
    return 0
  fi

  echo "link: $dest → $src"

  if [[ -L "$dest" ]]; then
    run ln -sfn "$src" "$dest"
  elif [[ -e "$dest" ]]; then
    echo "  WARN: $dest exists and is not a symlink — skipping (remove it manually to replace)"
  else
    run mkdir -p "$AGENTS_DEST"
    run ln -s "$src" "$dest"
  fi
}

install_all_skills() {
  for src in "$SKILLS_SRC"/*/; do
    if [[ -d "$src" ]]; then link_skill "$(basename "$src")"; fi
  done
}

install_all_agents() {
  if [[ ! -d "$AGENTS_SRC" ]]; then return 0; fi
  for src in "$AGENTS_SRC"/*.md; do
    if [[ -f "$src" ]]; then link_agent "$(basename "$src" .md)"; fi
  done
}

# No flags: install everything
if [[ ${#SKILL_TARGETS[@]} -eq 0 && ${#AGENT_TARGETS[@]} -eq 0 ]]; then
  install_all_skills
  install_all_agents
  exit 0
fi

for target in "${SKILL_TARGETS[@]}"; do
  if [[ "$target" == "all" ]]; then
    install_all_skills
  else
    link_skill "$target"
  fi
done

for target in "${AGENT_TARGETS[@]}"; do
  if [[ "$target" == "all" ]]; then
    install_all_agents
  else
    link_agent "$target"
  fi
done
