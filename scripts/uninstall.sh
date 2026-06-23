#!/usr/bin/env bash
# Remove symlinks installed by install.sh — only if they point back to this repo.
# Usage:
#   ./scripts/uninstall.sh [--dry-run] [--skill=name|all] [--agent=name|all]
#
# If no --skill or --agent flags are given, removes everything.

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

resolve_symlink() {
  local dest="$1"
  local target link_dir
  target="$(readlink "$dest")"
  if [[ "$target" != /* ]]; then
    link_dir="$(cd "$(dirname "$dest")" && pwd)"
    # Navigate into dirname(target) then reconstruct — handles both file and
    # directory symlinks (cd into a file path would fail with the old approach)
    target="$(cd "$link_dir/$(dirname "$target")" 2>/dev/null && echo "$(pwd)/$(basename "$target")" || echo "$target")"
  fi
  echo "$target"
}

unlink_item() {
  local label="$1" dest="$2" expected_src="$3"

  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    echo "SKIP: $label (not installed at $dest)"
    return 0
  fi

  if [[ ! -L "$dest" ]]; then
    echo "WARN: $dest exists but is not a symlink — skipping (remove it manually if intended)"
    return 0
  fi

  local target
  target="$(resolve_symlink "$dest")"

  if [[ "$target" == "$expected_src" || "$target" == "$expected_src"/ ]]; then
    echo "unlink: $dest"
    run rm "$dest"
  else
    echo "WARN: $dest → $target (not ours — skipping)"
  fi
}

unlink_skill() {
  local name="$1"
  unlink_item "skill/$name" "$SKILLS_DEST/$name" "$SKILLS_SRC/$name"
}

unlink_agent() {
  local name="$1"
  unlink_item "agent/$name" "$AGENTS_DEST/$name.md" "$AGENTS_SRC/$name.md"
}

unlink_all_skills() {
  if [[ ! -d "$SKILLS_DEST" ]]; then return 0; fi
  for dest in "$SKILLS_DEST"/*/; do
    if [[ -d "$dest" || -L "$dest" ]]; then unlink_skill "$(basename "$dest")"; fi
  done
}

unlink_all_agents() {
  if [[ ! -d "$AGENTS_DEST" ]]; then return 0; fi
  for dest in "$AGENTS_DEST"/*.md; do
    if [[ -f "$dest" || -L "$dest" ]]; then unlink_agent "$(basename "$dest" .md)"; fi
  done
}

# No flags: remove everything
if [[ ${#SKILL_TARGETS[@]} -eq 0 && ${#AGENT_TARGETS[@]} -eq 0 ]]; then
  unlink_all_skills
  unlink_all_agents
  exit 0
fi

for target in "${SKILL_TARGETS[@]}"; do
  if [[ "$target" == "all" ]]; then
    unlink_all_skills
  else
    unlink_skill "$target"
  fi
done

for target in "${AGENT_TARGETS[@]}"; do
  if [[ "$target" == "all" ]]; then
    unlink_all_agents
  else
    unlink_agent "$target"
  fi
done
