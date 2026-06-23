#!/usr/bin/env bash
# Remove symlinks installed by install.sh — only if they point back to this repo.
# Usage:
#   ./scripts/uninstall.sh [--dry-run] [--skill=name|all]
#
# If --skill is omitted, removes all skills.

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

unlink_skill() {
  local name="$1"
  local dest="$SKILLS_DEST/$name"
  local expected_src="$SKILLS_SRC/$name"

  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    echo "SKIP: $name (not installed at $dest)"
    return 0
  fi

  if [[ ! -L "$dest" ]]; then
    echo "WARN: $dest exists but is not a symlink — skipping (remove it manually if intended)"
    return 0
  fi

  local target
  target="$(readlink "$dest")"

  # Resolve relative symlinks to absolute path for comparison
  if [[ "$target" != /* ]]; then
    target="$(cd "$(dirname "$dest")" && cd "$target" 2>/dev/null && pwd || echo "$target")"
  fi

  if [[ "$target" == "$expected_src" || "$target" == "$expected_src"/ ]]; then
    echo "unlink: $dest"
    run rm "$dest"
  else
    echo "WARN: $dest → $target (not ours — skipping)"
  fi
}

unlink_all_skills() {
  if [[ ! -d "$SKILLS_DEST" ]]; then return 0; fi
  for dest in "$SKILLS_DEST"/*/; do
    if [[ -d "$dest" || -L "$dest" ]]; then unlink_skill "$(basename "$dest")"; fi
  done
}

if [[ ${#SKILL_TARGETS[@]} -eq 0 ]]; then
  unlink_all_skills
  exit 0
fi

for target in "${SKILL_TARGETS[@]}"; do
  if [[ "$target" == "all" ]]; then
    unlink_all_skills
  else
    unlink_skill "$target"
  fi
done
