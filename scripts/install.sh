#!/usr/bin/env bash
# Symlink Claude skills from ./skills/ into ~/.claude/skills/
# Usage:
#   ./scripts/install.sh [--dry-run] [skill ...]
#
#   --dry-run   show what would be linked without making changes
#   skill ...   install only the named skill(s); default: all

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"
SKILLS_DEST="$HOME/.claude/skills"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  shift
fi

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
    echo "SKIP: $name (no SKILL.md found at $src)"
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

if [[ $# -gt 0 ]]; then
  for skill in "$@"; do
    link_skill "$skill"
  done
else
  for src in "$SKILLS_SRC"/*/; do
    link_skill "$(basename "$src")"
  done
fi
