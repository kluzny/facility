#!/usr/bin/env bash
# shellcheck disable=SC2016  # $names inside single quotes are jq variables
# Print the installed skills, agents, user settings and per-project Claude
# config as markdown, and write allow.tsv and forbidden.tsv into the workdir.
#
# Usage: inventory.sh <workdir>
#
# <workdir> is the directory printed by extract.sh; its projects.tsv lists the
# projects to inspect.

set -euo pipefail

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
# Projects beyond this many (by prompt count) add little to the inventory.
MAX_PROJECTS=15

WORK="${1:-}"
if [ -z "$WORK" ] || [ ! -f "$WORK/projects.tsv" ]; then
  echo "Usage: inventory.sh <workdir>  (the directory printed by extract.sh; needs projects.tsv)" >&2
  exit 2
fi
command -v jq >/dev/null 2>&1 || { echo "inventory.sh: jq is required" >&2; exit 1; }

# First value of key $2 in markdown file $1's frontmatter, truncated to 140 chars.
frontmatter() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    index($0, key ":") == 1 { sub("^" key ":[ ]*", ""); print substr($0, 1, 140); exit }
  ' "$1"
}

resolve() {
  if [ -d "$1" ]; then (cd -P "$1" && pwd -P); else printf '%s\n' "$1"; fi
}

list_skills() {
  local dir="$1" s
  [ -d "$dir" ] || { echo "_none_"; return; }
  echo "| Skill | Source | Description |"
  echo "|---|---|---|"
  for s in "$dir"/*/; do
    [ -f "$s/SKILL.md" ] || continue
    s="${s%/}"
    printf '| %s | %s | %s |\n' "${s##*/}" "$(resolve "$s")" "$(frontmatter "$s/SKILL.md" description)"
  done
}

list_agents() {
  local dir="$1" a
  [ -d "$dir" ] || { echo "_none_"; return; }
  echo "| Agent | Model | Description |"
  echo "|---|---|---|"
  for a in "$dir"/*.md; do
    [ -f "$a" ] || continue
    printf '| %s | %s | %s |\n' "$(basename -- "$a" .md)" "$(frontmatter "$a" model)" "$(frontmatter "$a" description)"
  done
}

settings_summary() {
  local f="$1"
  [ -f "$f" ] || return 0
  echo "**${f/#$HOME/~}**"
  echo
  jq -r '
    "- allow rules: \(.permissions.allow // [] | length), ask: \(.permissions.ask // [] | length), deny: \(.permissions.deny // [] | length)",
    (if (.permissions.deny // []) | length > 0 then "- deny: " + ((.permissions.deny) | map("`" + . + "`") | join(", ")) else empty end),
    (.hooks // {} | to_entries[] | .key as $e | .value[] | "- hook \($e) [\(.matcher // "*")]: " + ([.hooks[]?.command // empty] | join("; ") | .[0:160])),
    (if .enabledPlugins then "- plugins: " + (.enabledPlugins | to_entries | map(select(.value) | .key) | join(", ")) else empty end),
    (if has("cleanupPeriodDays") then "- cleanupPeriodDays: \(.cleanupPeriodDays)" else empty end)
  ' "$f" 2>/dev/null || echo "- (unreadable JSON)"
  echo
}

: > "$WORK/allow.tsv"
: > "$WORK/forbidden.tsv"

echo "# Inventory"
echo
echo "## User skills (${CLAUDE_HOME/#$HOME/~}/skills)"
echo
list_skills "$CLAUDE_HOME/skills"
echo
echo "## User agents (${CLAUDE_HOME/#$HOME/~}/agents)"
echo
list_agents "$CLAUDE_HOME/agents"
echo
echo "## User settings"
echo
settings_summary "$CLAUDE_HOME/settings.json"
if [ -f "$CLAUDE_HOME/settings.json" ] && ! jq -e 'has("cleanupPeriodDays")' "$CLAUDE_HOME/settings.json" >/dev/null 2>&1; then
  echo "- cleanupPeriodDays: unset (default 30, so transcripts cover about a month)"
  echo
fi
settings_summary "$CLAUDE_HOME/settings.local.json"
jq -r '.permissions.allow // [] | .[] | ["(user)", "settings.json", .] | @tsv' "$CLAUDE_HOME/settings.json" >> "$WORK/allow.tsv" 2>/dev/null || true

echo "## Projects"
echo
head -n "$MAX_PROJECTS" "$WORK/projects.tsv" | while IFS="$(printf '\t')" read -r slug path count; do
  [ -d "$path" ] || continue
  echo "### $slug ($count prompts) — ${path/#$HOME/~}"
  echo
  for g in CLAUDE.md AGENTS.md .claude/CLAUDE.md CLAUDE.local.md; do
    [ -f "$path/$g" ] && echo "- guidance: \`$g\` ($(wc -l < "$path/$g" | tr -d ' ') lines)"
  done
  [ -d "$path/docs/agents" ] && echo "- guidance dir: \`docs/agents/\` ($(command find "$path/docs/agents" -name '*.md' | wc -l | tr -d ' ') files)"
  if [ -d "$path/.claude/skills" ]; then
    echo "- project skills: $(for s in "$path"/.claude/skills/*/; do s="${s%/}"; printf '%s ' "${s##*/}"; done)"
  fi
  if [ -d "$path/.claude/agents" ]; then
    echo "- project agents: $(for a in "$path"/.claude/agents/*.md; do [ -f "$a" ] && printf '%s ' "$(basename -- "$a" .md)"; done)"
    for a in "$path"/.claude/agents/*.md; do
      [ -f "$a" ] || continue
      if [ -z "$(frontmatter "$a" name)" ] || [ -z "$(frontmatter "$a" description)" ]; then
        echo "  - \`.claude/agents/$(basename -- "$a")\` lacks name/description frontmatter"
      fi
    done
  fi
  for s in settings.json settings.local.json; do
    f="$path/.claude/$s"
    [ -f "$f" ] || continue
    echo "- \`.claude/$s\`: $(jq -r '"allow \(.permissions.allow // [] | length), deny \(.permissions.deny // [] | length), hooks \(.hooks // {} | keys | join(",") | if . == "" then "none" else . end)"' "$f" 2>/dev/null || echo unreadable)"
    jq -r --arg p "$slug" --arg s "$s" '.permissions.allow // [] | .[] | [$p, $s, .] | @tsv' "$f" >> "$WORK/allow.tsv" 2>/dev/null || true
  done
  echo

  # Heuristic "use X, not Y" / "never run Y" rules from the project's guidance.
  for g in CLAUDE.md AGENTS.md .claude/CLAUDE.md; do
    [ -f "$path/$g" ] || continue
    jq -Rr --arg p "$slug" --arg g "$g" '
      (gsub("[\t]"; " ") | .[0:160]) as $line
      | ((capture("(?i)(never|do not|don.t|avoid)\\s+(run|use|call|invoke)(ning)?\\s+`(?<f>[^`]+)`(.*?(instead|use)\\s+`(?<u>[^`]+)`)?")? // empty),
         (capture("(?i)use\\s+`(?<u>[^`]+)`[ ,]*(not|instead of|rather than)\\s+`(?<f>[^`]+)`")? // empty),
         (capture("(?i)`(?<u>[^`]+)`\\s+(instead of|rather than)\\s+`(?<f>[^`]+)`")? // empty))
      | [$p, .f, (.u // ""), $g, $line]
      | @tsv
    ' "$path/$g" >> "$WORK/forbidden.tsv" 2>/dev/null || true
  done
done

# Keep rules that name a shell command (code-style rules like `print()` aren't
# countable in bash history), and merge duplicates from symlinked CLAUDE.md/AGENTS.md.
awk -F'\t' '$2 !~ /[()\[\]|]/ && $2 ~ /^[A-Za-z.\/]/ {
    k = $1 "\t" $2 "\t" $3
    if (!(k in src)) { order[++n] = k; src[k] = $4; line[k] = $5 } else if (index(src[k], $4) == 0) { src[k] = src[k] ", " $4 }
  } END { for (i = 1; i <= n; i++) print order[i] "\t" src[order[i]] "\t" line[order[i]] }' "$WORK/forbidden.tsv" > "$WORK/forbidden.tmp"
mv "$WORK/forbidden.tmp" "$WORK/forbidden.tsv"
echo "## Guidance rules detected (heuristic)"
echo
if [ -s "$WORK/forbidden.tsv" ]; then
  echo "| Project | Avoid | Prefer | Source | Rule text |"
  echo "|---|---|---|---|---|"
  awk -F'\t' '{ gsub(/\|/, "\\|", $5); printf "| %s | `%s` | %s | %s | %s |\n", $1, $2, ($3 == "" ? "" : "`" $3 "`"), $4, $5 }' "$WORK/forbidden.tsv"
else
  echo "_none found_"
fi
