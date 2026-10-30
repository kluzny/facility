#!/usr/bin/env bash
# shellcheck disable=SC2016  # $names inside single quotes are jq variables
# Extract prompts, tool calls, rejections and subagent models from Claude Code
# history and transcripts into a fresh working directory, and print its path.
#
# Usage: extract.sh [--days N] [--project NAME] [--chunks N]
#
#   --days N        only records from the last N days (default: all)
#   --project NAME  only projects whose path contains NAME
#   --chunks N      cap on prompt chunks for fan-out reading (default 4)
#
# Reads ~/.claude/history.jsonl and ~/.claude/projects; writes only to the
# working directory. Override the source root with CLAUDE_HOME.

set -euo pipefail

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
HISTORY="$CLAUDE_HOME/history.jsonl"
PROJECTS="$CLAUDE_HOME/projects"

# 350KB keeps one chunk inside a single subagent's context with room to reason.
CHUNK_BYTES=358400
# Long pasted prompts would dominate a chunk and the Read tool truncates long lines.
MAX_PROMPT_CHARS=2000
# Bash commands keep more text so heredoc bodies stay classifiable.
MAX_CMD_CHARS=4000
# Prompts in the sample used by --quick runs instead of fan-out.
SAMPLE_SIZE=200

DAYS=""
PROJECT=""
MAX_CHUNKS=4

usage() {
  echo "Usage: extract.sh [--days N] [--project NAME] [--chunks N]" >&2
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --days) DAYS="${2:-}"; shift 2 || usage ;;
    --days=*) DAYS="${1#--days=}"; shift ;;
    --project) PROJECT="${2:-}"; shift 2 || usage ;;
    --project=*) PROJECT="${1#--project=}"; shift ;;
    --chunks) MAX_CHUNKS="${2:-}"; shift 2 || usage ;;
    --chunks=*) MAX_CHUNKS="${1#--chunks=}"; shift ;;
    -h|--help) usage ;;
    *) echo "extract.sh: unknown argument '$1' (valid: --days N, --project NAME, --chunks N)" >&2; exit 2 ;;
  esac
done

case "$DAYS" in ''|*[!0-9]*) [ -z "$DAYS" ] || { echo "extract.sh: --days must be a positive integer, got '$DAYS'" >&2; exit 2; } ;; esac
case "$MAX_CHUNKS" in ''|*[!0-9]*|0) echo "extract.sh: --chunks must be a positive integer, got '$MAX_CHUNKS'" >&2; exit 2 ;; esac

command -v jq >/dev/null 2>&1 || { echo "extract.sh: jq is required (brew install jq / apt install jq)" >&2; exit 1; }
[ -f "$HISTORY" ] || { echo "extract.sh: no history at $HISTORY" >&2; exit 1; }
[ -d "$PROJECTS" ] || { echo "extract.sh: no transcripts at $PROJECTS" >&2; exit 1; }

TMP_ROOT="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${TMP_ROOT%/}/retro.XXXXXX")"
mkdir -p "$WORK/chunks"

if [ -n "$DAYS" ]; then
  CUTOFF="$(jq -n --argjson d "$DAYS" 'now - $d * 86400 | floor')"
else
  CUTOFF=0
fi

# Shared jq helpers: prompt cleanup, noise test, ISO timestamp → epoch.
JQ_LIB='
def clean($n): gsub("\r"; "") | .[0:$n];
def noise: test("^\\s*(<local-command|<system-reminder|<task-notification|<command-|\\[Request interrupted|This session is being continued|/(exit|clear|new|compact|model)(\\s|$))");
def epoch: if type == "string" then (sub("\\.[0-9]+"; "") | fromdateiso8601) else 0 end;
def day: epoch | strftime("%Y-%m-%d");
'

# --- history: project, date, prompt ------------------------------------------
jq -r --argjson cutoff "$CUTOFF" --arg proj "$PROJECT" --argjson n "$MAX_PROMPT_CHARS" "$JQ_LIB"'
  select((.timestamp // 0) / 1000 >= $cutoff)
  | select(.project and (.project | contains($proj)))
  | select((.display // "") | length > 0)
  | select(.display | noise | not)
  | [(.project | split("/") | last), (.timestamp / 1000 | strftime("%Y-%m-%d")), (.display | clean($n))]
  | @tsv
' "$HISTORY" > "$WORK/history.tsv"

awk -F'\t' -v dir="$WORK" '{ gsub(/[^A-Za-z0-9_.-]/, "_", $1); print > (dir "/h_" $1 ".tsv") }' "$WORK/history.tsv"

# slug, path, prompt count — lets inventory.sh find each project's own guidance files.
jq -r --argjson cutoff "$CUTOFF" --arg proj "$PROJECT" '
  select((.timestamp // 0) / 1000 >= $cutoff) | select(.project and (.project | contains($proj))) | .project
' "$HISTORY" | sort | uniq -c \
  | awk '{ n = $1; sub(/^ *[0-9]+ /, ""); s = $0; sub(/.*\//, "", s); gsub(/[^A-Za-z0-9_.-]/, "_", s); print s "\t" $0 "\t" n }' \
  | sort -t "$(printf '\t')" -k3,3rn > "$WORK/projects.tsv"

# --- transcripts --------------------------------------------------------------
# One jq pass per file emits tagged lines, routed into output files by awk:
#   P prompt, S slash command, T tool call (JSON), B bash command,
#   R rejection, I interruption.
TRANSCRIPT_JQ="$JQ_LIB"'
  select(.timestamp and (.timestamp | epoch) >= $cutoff)
  | (.isSidechain // false) as $side
  | .timestamp as $ts
  | if .type == "user" and (.isMeta | not) and (.toolUseResult | not) and ($side | not) then
      (.message.content | if type == "string" then . else (map(select(.type == "text") | .text) | join(" ")) end) as $text
      | if ($text | test("^\\s*<command-name>")) then
          ["S", $proj, $sess, ($ts | day), (($text | capture("<command-name>(?<c>[^<]+)</command-name>")? | .c) // "")] | @tsv
        elif ($text | test("^\\s*\\[Request interrupted")) then
          ["I", $proj, $sess, ($ts | day)] | @tsv
        elif ($text | length > 0) and ($text | noise | not) then
          ["P", $proj, $sess, $ts, ($text | clean($n))] | @tsv
        else empty end
    elif .type == "user" and (.message.content | type) == "array" then
      .message.content[]
      | select(.type == "tool_result" and .is_error == true)
      | (.content | if type == "array" then map(.text? // "") | join(" ") else tostring end) as $res
      | select($res | startswith("The user doesn'"'"'t want to proceed"))
      | ["R", $proj, $sess, .tool_use_id, ((($res | capture("the user said:\\s*(?<r>.*)"; "s")? | .r) // "") | clean(300))] | @tsv
    elif .type == "assistant" and (.message.content | type) == "array" then
      .message.content[]
      | select(.type == "tool_use")
      | (if .name == "Bash" then ["B", $proj, ($side | tostring), ((.input.command // "") | clean($cmdmax))] | @tsv else empty end),
        ("T\t" + ({project: $proj, session: $sess, sidechain: $side, ts: $ts, id, name,
                   input: (.input | walk(if type == "string" then .[0:300] else . end))} | tojson))
    else empty end
'

project_of() {
  # Launch directory recorded in the transcript; falls back to the encoded dir name.
  local cwd
  cwd="$(jq -rn 'first(inputs | select(.cwd) | .cwd) // empty' "$1" 2>/dev/null || true)"
  # Encoded dir names start with "-", so use parameter expansion rather than basename/dirname.
  if [ -z "$cwd" ]; then
    case "$1" in
      ./*/*/subagents/*) cwd="${1#./}"; cwd="${cwd%%/*}" ;;
      *) cwd="${1%/*}"; cwd="${cwd##*/}" ;;
    esac
  fi
  printf '%s\n' "$cwd"
}

: > "$WORK/transcripts.raw"
: > "$WORK/subagent_models.tsv"
FIND_AGE=()
if [ -n "$DAYS" ]; then FIND_AGE=(-mtime "-$((DAYS + 1))"); fi

cd "$PROJECTS"
command find ./ -name '*.jsonl' "${FIND_AGE[@]+"${FIND_AGE[@]}"}" -print | while IFS= read -r f; do
  cwd="$(project_of "$f")"
  case "$cwd" in *"$PROJECT"*) ;; *) continue ;; esac
  proj="$(printf '%s\n' "${cwd##*/}" | tr -c 'A-Za-z0-9_.\n-' '_')"
  case "$f" in
    */subagents/*)
      sess="${f%/subagents/*}"; sess="${sess##*/}"
      meta="${f%.jsonl}.meta.json"
      [ -f "$meta" ] || meta=/dev/null
      jq -r --arg proj "$proj" --slurpfile meta "$meta" -n '
        [inputs | select(.type == "assistant") | .message.model // empty] as $m
        | ($meta[0] // {}) as $mt
        | [$proj, ($mt.agentType // "?"), (($mt.description // "") | gsub("[\t\n]"; " ")),
           ($mt.model // "inherit"), (if ($m | length) > 0 then ($m | group_by(.) | max_by(length) | .[0]) else "?" end)]
        | @tsv' "$f" >> "$WORK/subagent_models.tsv" 2>/dev/null || true
      ;;
    *) sess="${f##*/}"; sess="${sess%.jsonl}" ;;
  esac
  jq -r --arg proj "$proj" --arg sess "$sess" --argjson cutoff "$CUTOFF" \
    --argjson n "$MAX_PROMPT_CHARS" --argjson cmdmax "$MAX_CMD_CHARS" \
    "$TRANSCRIPT_JQ" "$f" >> "$WORK/transcripts.raw" 2>/dev/null || true
done
cd - >/dev/null

awk -F'\t' -v dir="$WORK" '
  $1 == "P" { print $2 "\t" $3 "\t" $4 "\t" $5 > (dir "/p_" $2 ".tsv") }
  $1 == "S" { print $2 "\t" $3 "\t" $4 "\t" $5 > (dir "/slash.tsv") }
  $1 == "I" { print $2 "\t" $3 "\t" $4 > (dir "/interrupts.tsv") }
  $1 == "R" { print $2 "\t" $3 "\t" $4 "\t" $5 > (dir "/rejected_ids.tsv") }
  $1 == "B" { print $2 "\t" $3 "\t" $4 > (dir "/bash_cmds.txt") }
  $1 == "T" { sub(/^T\t/, ""); print > (dir "/tools.jsonl") }
' "$WORK/transcripts.raw"
rm -f "$WORK/transcripts.raw"
for f in slash.tsv interrupts.tsv rejected_ids.tsv bash_cmds.txt tools.jsonl; do
  [ -f "$WORK/$f" ] || : > "$WORK/$f"
done

# --- rejections: join tool_result ids back to their tool_use ----------------
jq -r --rawfile ids "$WORK/rejected_ids.tsv" '
  ($ids | split("\n") | map(select(length > 0) | split("\t") | {key: .[2], value: .[3]}) | from_entries) as $rej
  | select($rej[.id] != null)
  | [.project, .session, .name,
     ((.input.command // .input.file_path // .input.description // .input.skill // (.input | tojson)) | tostring | gsub("[\t\n]"; " ") | .[0:200]),
     $rej[.id]]
  | @tsv
' "$WORK/tools.jsonl" > "$WORK/rejections.tsv"
rm -f "$WORK/rejected_ids.tsv"

# --- quick-mode sample: evenly spaced prompts across the history window -----
awk -v n="$SAMPLE_SIZE" 'NR == FNR { total++; next }
  FNR == 1 { step = (total > n) ? total / n : 1; next_at = 1 }
  FNR >= next_at { print; next_at += step }' "$WORK/history.tsv" "$WORK/history.tsv" > "$WORK/sample.tsv"

# --- chunks for fan-out ------------------------------------------------------
# Keep the most recent prompts that fit the chunk budget, then pack them by
# project (largest first) so each chunk tells as few projects' stories as possible.
# Each budget slot reserves one max-length line so line granularity never adds a chunk.
# Lines are capped at that length here because @tsv escaping can stretch a prompt
# past MAX_PROMPT_CHARS.
MAX_LINE=$(( MAX_PROMPT_CHARS + 200 ))
BUDGET=$(( MAX_CHUNKS * (CHUNK_BYTES - MAX_LINE) ))
# history.tsv is chronological (append order), so reversing it puts newest first.
awk '{ a[NR] = $0 } END { for (i = NR; i > 0; i--) print a[i] }' "$WORK/history.tsv" \
  | awk -v b="$BUDGET" -v max="$MAX_LINE" '{ if (length($0) > max) $0 = substr($0, 1, max)
      used += length($0) + 1; if (used > b) { dropped++; next } print }
      END { if (dropped) print dropped > "/dev/stderr" }' 2> "$WORK/chunks_dropped.txt" \
  > "$WORK/recent.tsv"

awk -F'\t' '{ size[$1] += length($0) + 1 } END { for (p in size) print size[p] "\t" p }' "$WORK/recent.tsv" \
  | sort -rn | cut -f2 > "$WORK/project_order.txt"

awk -F'\t' -v dir="$WORK/chunks" -v limit="$CHUNK_BYTES" '
  NR == FNR { order[++np] = $0; next }
  { rows[$1] = rows[$1] $0 "\n" }
  END {
    c = 1; used = 0
    for (i = 1; i <= np; i++) {
      p = order[i]; nl = split(rows[p], lines, "\n")
      # Reverse back to chronological order within each project.
      for (j = nl - 1; j >= 1; j--) {
        len = length(lines[j]) + 1
        if (used + len > limit && used > 0) { close(file); c++; used = 0 }
        file = sprintf("%s/chunk_%02d.tsv", dir, c)
        print lines[j] > file; used += len
      }
    }
  }' "$WORK/project_order.txt" "$WORK/recent.tsv"
rm -f "$WORK/recent.tsv" "$WORK/project_order.txt"

{
  printf 'source\t%s\n' "$CLAUDE_HOME"
  printf 'days\t%s\n' "${DAYS:-all}"
  printf 'project_filter\t%s\n' "${PROJECT:-none}"
  printf 'history_range\t%s\n' "$(cut -f2 "$WORK/history.tsv" | sort | awk 'NR==1{f=$0}{l=$0}END{print (NR ? f " .. " l : "none")}')"
  printf 'transcript_range\t%s\n' "$(jq -r '.ts[0:10]' "$WORK/tools.jsonl" | sort | awk 'NR==1{f=$0}{l=$0}END{print (NR ? f " .. " l : "none")}')"
  printf 'chunk_prompts_dropped\t%s\n' "$(cat "$WORK/chunks_dropped.txt" 2>/dev/null || true)"
} > "$WORK/meta.tsv"
rm -f "$WORK/chunks_dropped.txt"

if [ ! -s "$WORK/history.tsv" ] && [ ! -s "$WORK/tools.jsonl" ]; then
  echo "extract.sh: no records matched (days=${DAYS:-all}, project=${PROJECT:-any})" >&2
fi

echo "$WORK"
