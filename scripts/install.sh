#!/usr/bin/env bash
# Symlink Claude skills from ./skills/ into ~/.claude/skills/
# Usage:
#   ./scripts/install.sh [--dry-run] [--skill=name|all]
#
# If --skill is omitted, installs all skills.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"
SKILLS_DEST="$HOME/.claude/skills"

DRY_RUN=false
SKILL_TARGETS=()

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    --skill=*)
      SKILL_TARGETS+=("${arg#--skill=}")
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

install_all_skills() {
  for src in "$SKILLS_SRC"/*/; do
    if [[ -d "$src" ]]; then link_skill "$(basename "$src")"; fi
  done
}

if [[ ${#SKILL_TARGETS[@]} -eq 0 ]]; then
  install_all_skills
  exit 0
fi

for target in "${SKILL_TARGETS[@]}"; do
  if [[ "$target" == "all" ]]; then
    install_all_skills
  else
    link_skill "$target"
  fi
done
