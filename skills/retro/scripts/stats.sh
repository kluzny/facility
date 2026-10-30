#!/usr/bin/env bash
# shellcheck disable=SC2016  # $names inside single quotes are jq/awk variables
# Print every deterministic count from an extract.sh working directory as
# markdown tables. Counts are regex-based and approximate.
#
# Usage: stats.sh <workdir>
#
# Run inventory.sh first so allow.tsv and forbidden.tsv exist; without them the
# guidance-bypass and unused-allow-rule tables are skipped.

set -euo pipefail

# Rows per ranking table; enough to show the long tail without flooding context.
TOP=25
# A prompt typed this many times is a candidate for a skill or alias.
REPEAT_MIN=3

WORK="${1:-}"
if [ -z "$WORK" ] || [ ! -f "$WORK/history.tsv" ] || [ ! -f "$WORK/tools.jsonl" ]; then
  echo "Usage: stats.sh <workdir>  (the directory printed by extract.sh)" >&2
  exit 2
fi
command -v jq >/dev/null 2>&1 || { echo "stats.sh: jq is required" >&2; exit 1; }
cd "$WORK"

# Strip `cd x &&`, VAR=value and `timeout N` so the real command leads.
AWK_NORM='
function norm(c) {
  sub(/^[ \t]+/, "", c)
  while (match(c, /^(cd [^&;]+(&&|;) *|[A-Z_][A-Z0-9_]*=[^ ]* +|timeout [0-9]+ +)/)) c = substr(c, RLENGTH + 1)
  return c
}'

table() { # header... ; rows on stdin as TSV
  local h sep=""
  h="$(printf '| %s ' "$@")|"
  for _ in "$@"; do sep="$sep|---"; done
  echo "$h"
  echo "$sep|"
  awk -F'\t' '{ line = "|"; for (i = 1; i <= NF; i++) { gsub(/\|/, "\\|", $i); line = line " " $i " |" } print line }'
}

section() { printf '\n## %s\n\n' "$1"; }

echo "# Retro stats"
section "Sample"
table Key Value < meta.tsv
echo
echo "_History covers prompts only; transcripts (tools, rejections, models) cover the retention window. Counts are regex-based and approximate._"

section "Prompts by project"
{
  awk -F'\t' '{ h[$1]++ } END { for (p in h) print p "\th\t" h[p] }' history.tsv
  for f in p_*.tsv; do
    [ -f "$f" ] || continue
    awk -F'\t' '{ n++; s[$2] = 1 } END { c = 0; for (k in s) c++; print $1 "\tp\t" n "\t" c }' "$f"
  done
} | awk -F'\t' '$2 == "h" { h[$1] = $3; all[$1] = 1 } $2 == "p" { p[$1] = $3; s[$1] = $4; all[$1] = 1 }
    END { for (k in all) printf "%s\t%d\t%d\t%d\n", k, h[k], p[k], s[k] }' \
  | sort -t "$(printf '\t')" -k2,2rn | head -n "$TOP" | table Project "History prompts" "Transcript prompts" Sessions

section "Slash commands (history, excluding session control)"
awk -F'\t' '$3 ~ /^\// { split($3, w, /[ \\]/); n[w[1]]++ } END { for (k in n) print k "\t" n[k] }' history.tsv \
  | sort -t "$(printf '\t')" -k2,2rn | head -n "$TOP" | table Command Count

section "Repeated prompts (history, typed ≥$REPEAT_MIN times)"
awk -F'\t' -v min="$REPEAT_MIN" '$3 !~ /^\// {
    p = tolower($3); gsub(/[ \t]+/, " ", p); sub(/^ /, "", p); sub(/ $/, "", p)
    if (length(p) < 4) next
    k = $1 "\t" substr(p, 1, 100); n[k]++
  } END { for (k in n) if (n[k] >= min) print k "\t" n[k] }' history.tsv \
  | sort -t "$(printf '\t')" -k3,3rn | head -n "$TOP" | table Project Prompt Count

section "Tool calls (main thread vs subagents)"
jq -r '[.name, (if .sidechain then "sub" else "main" end)] | @tsv' tools.jsonl \
  | awk -F'\t' '{ t[$1] = 1; c[$1, $2]++ } END { for (k in t) printf "%s\t%d\t%d\n", k, c[k, "main"], c[k, "sub"] }' \
  | sort -t "$(printf '\t')" -k2,2rn | head -n "$TOP" | table Tool Main Subagent

section "Skill tool calls"
jq -r 'select(.name == "Skill") | [.project, (.input.skill // .input.command // "?")] | @tsv' tools.jsonl \
  | sort | uniq -c | sort -rn | head -n "$TOP" | awk '{ n = $1; sub(/^ *[0-9]+ /, ""); print $0 "\t" n }' \
  | table Project Skill Count

section "Agent tool calls"
jq -r 'select(.name == "Agent" or .name == "Task") | [(.input.subagent_type // "general-purpose"), (.input.model // "inherit"), ((.input.description // "") | .[0:60])] | @tsv' tools.jsonl \
  | awk -F'\t' '{ k = $1 "\t" $2; n[k]++; if (!(k in ex)) ex[k] = $3 } END { for (k in n) print k "\t" n[k] "\t" ex[k] }' \
  | sort -t "$(printf '\t')" -k3,3rn | head -n "$TOP" | table "Subagent type" "Model param" Count "Example description"

section "Subagent models (from subagent transcripts)"
if [ -s subagent_models.tsv ]; then
  awk -F'\t' '{ n[$2 "\t" $4 "\t" $5]++ } END { for (k in n) print k "\t" n[k] }' subagent_models.tsv \
    | sort -t "$(printf '\t')" -k4,4rn | head -n "$TOP" | table "Agent type" Requested "Actual model" Count
else
  echo "_no subagent transcripts in window_"
fi

section "Bash commands by first word"
awk -F'\t' "$AWK_NORM"' { c = norm($3); split(c, w, /[ \\]/); n[w[1]]++ } END { for (k in n) print k "\t" n[k] }' bash_cmds.txt \
  | sort -t "$(printf '\t')" -k2,2rn | head -n "$TOP" | table Command Count

section "Bash commands by first two words (subcommands, make targets, scripts)"
awk -F'\t' "$AWK_NORM"' { c = norm($3); split(c, w, /[ \\]/); k = w[1] " " w[2]; n[k]++ } END { for (k in n) print k "\t" n[k] }' bash_cmds.txt \
  | sort -t "$(printf '\t')" -k2,2rn | head -n 40 | table Command Count

section "File edits bypassing Edit/Write"
{
  awk -F'\t' '
    $3 ~ /python3? +(-c|- *<<)/ && $3 ~ /(\.write\(|write_text\()/ { py[$1]++; all[$1] = 1 }
    $3 ~ /(^|[ ;&|])sed +(-[a-zA-Z]+ +)*-i/ { sd[$1]++; all[$1] = 1 }
    $3 ~ /perl +-[a-z]*i/ { pl[$1]++; all[$1] = 1 }
    END { for (k in all) printf "%s\tb\t%d\t%d\t%d\n", k, py[k], sd[k], pl[k] }' bash_cmds.txt
  jq -r 'select(.name == "Edit" or .name == "Write" or .name == "MultiEdit" or .name == "NotebookEdit") | .project + "\te"' tools.jsonl
} | awk -F'\t' '$2 == "b" { py[$1] = $3; sd[$1] = $4; pl[$1] = $5; all[$1] = 1 } $2 == "e" { e[$1]++; all[$1] = 1 }
    END { for (k in all) if (py[k] + sd[k] + pl[k] > 0) printf "%s\t%d\t%d\t%d\t%d\n", k, py[k], sd[k], pl[k], e[k] }' \
  | sort -t "$(printf '\t')" -k2,2rn | table Project "python write" "sed -i" "perl -i" "Edit/Write tool"

section "Guidance-rule bypasses (heuristic: avoided command at command position, preferred absent)"
if [ -s forbidden.tsv ]; then
  awk -F'\t' "$AWK_NORM"'
    NR == FNR { np++; rp[np] = $1; ra[np] = $2; ru[np] = $3; next }
    { c = norm($3)
      for (i = 1; i <= np; i++) {
        if (rp[i] != $1) continue
        if (ru[i] != "" && index(c, ru[i]) > 0) continue
        s = " " c; a = ra[i]
        if (index(s, " " a) == 0) continue
        if (substr(s, 1, length(a) + 2) == " " a " " || s == " " a || index(s, "exec " a) || index(s, "&& " a) || index(s, "; " a) || index(s, "| " a) || index(s, "run " a)) hit[i]++
      } }
    END { for (i = 1; i <= np; i++) if (hit[i]) printf "%s\t`%s`\t%s\t%d\n", rp[i], ra[i], (ru[i] == "" ? "" : "`" ru[i] "`"), hit[i] }' forbidden.tsv bash_cmds.txt \
    | sort -t "$(printf '\t')" -k4,4rn | table Project Avoid Prefer Count
else
  echo "_no rules (run inventory.sh <workdir> first, or no project guidance matched)_"
fi

section "Test runs piped through output filters"
# A segment counts when its runner (first word, or the target/subcommand of a
# build tool) names a test or spec, and its output is piped to grep/tail/head.
awk -F'\t' "$AWK_NORM"' {
    c = norm($3); ns = split(c, seg, /(&&|;|\\n)/)
    for (i = 1; i <= ns; i++) {
      s = norm(seg[i]); if (s !~ /\| *(grep|tail|head)/) continue
      split(s, w, / +/)
      runner = w[1]
      if (w[1] ~ /^(make|bundle|npm|npx|yarn|pnpm|uv|cargo|go|poetry|bin\/rails|rake)$/) runner = w[2] " " w[3]
      if (runner ~ /(test|spec)/) { n[$1]++; if (!($1 in ex)) ex[$1] = substr(s, 1, 100); break }
    }
  } END { for (k in n) print k "\t" n[k] "\t" ex[k] }' bash_cmds.txt \
  | sort -t "$(printf '\t')" -k2,2rn | table Project Count Example

section "Rejected tool uses"
awk -F'\t' '{ n[$1 "\t" $3]++ } END { for (k in n) print k "\t" n[k] }' rejections.tsv \
  | sort -t "$(printf '\t')" -k3,3rn | head -n "$TOP" | table Project Tool Count
echo
echo "Rejections with a stated reason:"
echo
awk -F'\t' '$5 != "" { print $1 "\t" $3 "\t" substr($4, 1, 80) "\t" substr($5, 1, 160) }' rejections.tsv \
  | head -n "$TOP" | table Project Tool Input Reason

section "Interruptions"
awk -F'\t' '{ n[$1]++ } END { for (k in n) print k "\t" n[k] }' interrupts.tsv \
  | sort -t "$(printf '\t')" -k2,2rn | table Project Count

section "Bash allow rules with no matching command in window"
if [ -s allow.tsv ]; then
  awk -F'\t' "$AWK_NORM"'
    NR == FNR {
      if ($3 !~ /^Bash\(/) next
      r = substr($3, 6, length($3) - 6); sub(/(:\*| \*|\*)$/, "", r)
      nr++; rp[nr] = $1; rf[nr] = $2; rr[nr] = $3; pre[nr] = r; next
    }
    { c = norm($3); for (i = 1; i <= nr; i++) if ((rp[i] == "(user)" || rp[i] == $1) && index(c, pre[i]) == 1) used[i]++ }
    END { for (i = 1; i <= nr; i++) if (!used[i]) print rp[i] "\t" rf[i] "\t`" rr[i] "`" }' allow.tsv bash_cmds.txt \
    | head -n 40 | table Project File Rule
else
  echo "_no allow rules collected (run inventory.sh <workdir> first)_"
fi
