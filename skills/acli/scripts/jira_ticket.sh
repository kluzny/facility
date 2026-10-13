#!/usr/bin/env bash
set -euo pipefail

# Prints a Jira work item as Markdown: every populated field, the description
# and comments converted from Atlassian Document Format, attachments, worklog,
# and linked work items. Links whose relation (as seen from this item) matches
# JIRA_BLOCKER_PATTERN and that are not yet done are fetched too, so their
# descriptions are inline; other links show only key, status, and summary.
#
# acli does not expose field display names, so custom fields are listed by id.

usage() {
  cat >&2 <<'EOF'
Usage: jira_ticket.sh <KEY | browse URL>

Environment:
  JIRA_BLOCKER_PATTERN  case-insensitive regex matched against a link's
                        relation text (default: "blocked by")
EOF
  exit 1
}

[ $# -eq 1 ] || usage
case "$1" in -h | --help) usage ;; esac

for bin in acli jq; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "jira_ticket.sh: $bin not found on PATH" >&2
    exit 1
  }
done

# Accept https://site.atlassian.net/browse/KEY-1?focusedCommentId=... as well as KEY-1.
key="${1##*/browse/}"
key="${key%%[?#/]*}"
key="$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')"
if ! printf '%s' "$key" | grep -Eq '^[A-Z][A-Z0-9_]*-[0-9]+$'; then
  echo "jira_ticket.sh: '$1' is not a work item key (e.g. PROJ-123)" >&2
  exit 1
fi

blocker_pattern="${JIRA_BLOCKER_PATTERN:-blocked by}"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/jira_ticket.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

if ! acli jira workitem view "$key" --json --fields '*all' >"$tmp/issue.json" 2>"$tmp/err" </dev/null; then
  cat "$tmp/err" >&2
  exit 1
fi

site="$(acli jira auth status 2>/dev/null </dev/null | sed -n 's/^[[:space:]]*Site:[[:space:]]*//p' | head -n 1 || true)"

# Unresolved blockers get a second fetch for their description.
printf '[' >"$tmp/blockers.json"
sep=''
for bkey in $(jq -r --arg pat "$blocker_pattern" '
  .fields.issuelinks[]?
  | if .inwardIssue then {rel: .type.inward, issue: .inwardIssue} else {rel: .type.outward, issue: .outwardIssue} end
  | select(.rel | test($pat; "i"))
  | select(.issue.fields.status.statusCategory.key != "done")
  | .issue.key' "$tmp/issue.json"); do
  if acli jira workitem view "$bkey" --json \
    --fields 'summary,status,issuetype,priority,assignee,description' \
    >"$tmp/b.json" 2>/dev/null </dev/null; then
    printf '%s' "$sep" >>"$tmp/blockers.json"
    cat "$tmp/b.json" >>"$tmp/blockers.json"
  else
    printf '%s{"key":"%s","unreadable":true}' "$sep" "$bkey" >>"$tmp/blockers.json"
  fi
  sep=','
done
printf ']' >>"$tmp/blockers.json"

jq -r --arg site "$site" --arg pat "$blocker_pattern" --slurpfile blockers "$tmp/blockers.json" '
# ---- Atlassian Document Format -> Markdown ----------------------------------
# Emphasis markers must hug the text, so whitespace inside a mark moves outside it.
def wrap($l; $r):
  capture("^(?<a>\\s*)(?<b>.*?)(?<c>\\s*)$"; "s") as $p
  | if $p.b == "" then . else $p.a + $l + $p.b + $r + $p.c end;

def marked($marks):
  reduce ($marks // [])[] as $m (.;
    if   $m.type == "code"   then "`" + . + "`"
    elif $m.type == "strong" then wrap("**"; "**")
    elif $m.type == "em"     then wrap("_"; "_")
    elif $m.type == "strike" then wrap("~~"; "~~")
    elif $m.type == "link"   then "[" + . + "](" + ($m.attrs.href // "") + ")"
    else . end);

def inl:
  if   .type == "text"      then .marks as $m | (.text // "") | marked($m)
  elif .type == "hardBreak" then "\n"
  elif .type == "mention"   then .attrs.text // ("@" + (.attrs.id // "unknown"))
  elif .type == "emoji"     then .attrs.text // .attrs.shortName // ""
  elif .type == "date"      then (.attrs.timestamp | tonumber / 1000 | todate)[0:10]
  elif .type == "status"    then "[" + (.attrs.text // "") + "]"
  elif (.type | IN("inlineCard", "blockCard", "embedCard")) then .attrs.url // ""
  elif (.type | IN("media", "mediaInline")) then "[attachment: " + (.attrs.alt // .attrs.id // "file") + "]"
  else [.content[]? | inl] | join("") end;

# $h is added to every heading level.
def blk($h):
  def item($marker):
    ([.content[]? | blk($h)] | join("\n") | split("\n")) as $lines
    | $marker + ($lines[0] // "")
      + ($lines[1:] | map("\n" + (if . == "" then "" else (($marker | length) * " ") + . end)) | join(""));
  def cell: [.content[]? | blk($h)] | join(" ") | gsub("\n"; " ") | gsub("\\|"; "\\|");
  def quoted: split("\n") | map("> " + .) | join("\n");

  if   .type == "doc"         then [.content[]? | blk($h) | select(. != "")] | join("\n\n")
  elif .type == "paragraph"   then [.content[]? | inl] | join("")
  elif .type == "heading"     then ([[(.attrs.level // 1) + $h, 6] | min, 1] | max) * "#" + " " + ([.content[]? | inl] | join(""))
  elif .type == "bulletList"  then [.content[]? | item("- ")] | join("\n")
  elif .type == "orderedList" then
    (.attrs.order // 1) as $start
    | [.content // [] | to_entries[] | .key as $i | .value | item("\($start + $i). ")] | join("\n")
  elif .type == "listItem"    then item("- ")
  elif (.type | IN("taskList", "decisionList")) then [.content[]? | blk($h)] | join("\n")
  elif (.type | IN("taskItem", "decisionItem")) then
    (if (.attrs.state | IN("DONE", "DECIDED")) then "- [x] " else "- [ ] " end)
    + ([.content[]? | if .type == "taskList" then "\n" + blk($h) else inl end] | join(""))
  elif .type == "codeBlock"   then "```" + (.attrs.language // "") + "\n" + ([.content[]?.text] | join("")) + "\n```"
  elif .type == "blockquote"  then [.content[]? | blk($h)] | join("\n\n") | quoted
  elif .type == "panel"       then
    "**" + ((.attrs.panelType // "note") | ascii_upcase) + ":**\n\n" + ([.content[]? | blk($h) | select(. != "")] | join("\n\n")) | quoted
  elif .type == "rule"        then "---"
  elif .type == "table"       then
    [.content[]? | select(.type == "tableRow")] as $rows
    | if ($rows | length) == 0 then "" else
        ($rows | map("| " + ([.content[]? | cell] | join(" | ")) + " |")) as $lines
        | ($rows[0].content | length) as $w
        | if ($rows[0].content | all(.type == "tableHeader"))
          then [$lines[0], "|" + ($w * " --- |")] + $lines[1:]
          else ["|" + ($w * "   |"), "|" + ($w * " --- |")] + $lines end
        | join("\n")
      end
  elif (.type | IN("mediaSingle", "mediaGroup")) then [.content[]? | inl] | join(" ")
  elif (.type | IN("expand", "nestedExpand")) then
    "**" + (.attrs.title // "Details") + "**\n\n" + ([.content[]? | blk($h) | select(. != "")] | join("\n\n"))
  elif (.type | IN("extension", "bodiedExtension", "inlineExtension")) then
    "[extension: " + (.attrs.extensionKey // "unknown") + "]"
  elif has("content")         then [.content[]? | blk($h) | select(. != "")] | join("\n\n")
  else inl end;

# $top is the level the shallowest heading in the document is rendered at, so it
# nests under whichever section of the output holds it.
def adf($top):
  if . == null then "" elif type == "string" then .
  else ([.. | objects | select(.type == "heading") | .attrs.level // 1] | min // 1) as $min
    | blk($top - $min) end;

# ---- helpers ------------------------------------------------------------------
def ts: if . == null then null else .[0:16] | sub("T"; " ") end;
def names: if . == null or . == [] then null else map(.name // .value // tostring) | join(", ") end;
def browse($k): if $site == "" then null else "https://\($site)/browse/\($k)" end;
def ref: "\(.key) [\(.fields.status.name // "?")] \(.fields.summary // "")";
def bytes:
  if . == null then "?" elif . >= 1048576 then "\(. / 1048576 * 10 | floor / 10) MB"
  elif . >= 1024 then "\(. / 1024 | floor) KB" else "\(.) B" end;

# Reduce an arbitrary custom field value to one readable line.
def simple:
  if . == null then empty
  elif type == "array" then ([.[] | simple] | select(length > 0) | join(", "))
  elif type == "object" then
    if .type == "doc" then adf(0) | gsub("\n+"; " ")
    elif has("value") then .value + (if .child then " > " + (.child | simple) else "" end)
    else (.name // .displayName // .title // .key // empty) | tostring end
  else tostring end
  | select(. != "")
  | if length > 200 then .[0:200] + "…" else . end;

def section($title; $body): if $body == null or $body == "" then empty else "## \($title)\n\n\($body)\n" end;
def bullets: if length == 0 then null else join("\n") end;

# ---- document -----------------------------------------------------------------
.key as $key
| .fields as $f
| ($blockers[0] // []) as $fetched
| [
    "# \(.key): \($f.summary // "")\n",
    (browse(.key) // empty | . + "\n"),

    ([
      ["Type",           $f.issuetype.name],
      ["Status",         ($f.status.name // null) as $s | if $s then "\($s) (\($f.status.statusCategory.name))" else null end],
      ["Resolution",     $f.resolution.name],
      ["Priority",       $f.priority.name],
      ["Project",        ($f.project | if . then "\(.key) — \(.name)" else null end)],
      ["Parent",         ($f.parent | if . then "\(.key) [\(.fields.issuetype.name)] \(.fields.summary)" else null end)],
      ["Assignee",       $f.assignee.displayName // "Unassigned"],
      ["Reporter",       $f.reporter.displayName],
      ["Created",        ($f.created | ts)],
      ["Updated",        ($f.updated | ts)],
      ["Resolved",       ($f.resolutiondate | ts)],
      ["Due",            $f.duedate],
      ["Labels",         ($f.labels | if . == null or . == [] then null else join(", ") end)],
      ["Components",     ($f.components | names)],
      ["Fix versions",   ($f.fixVersions | names)],
      ["Affects versions", ($f.versions | names)],
      ["Security level", $f.security.name],
      ["Estimate",       $f.timetracking.originalEstimate],
      ["Time spent",     $f.timetracking.timeSpent],
      ["Remaining",      $f.timetracking.remainingEstimate]
    ] | map(select(.[1] != null and .[1] != "") | "- **\(.[0]):** \(.[1])") | join("\n") + "\n"),

    section("Description"; $f.description | adf(3) | if . == "" then "_No description._" else . end),
    section("Environment"; $f.environment | adf(3)),

    section("Links"; [
      $f.issuelinks[]?
      | if .inwardIssue then "- \(.type.inward) \(.inwardIssue | ref)" else "- \(.type.outward) \(.outwardIssue | ref)" end
    ] | bullets),

    section("Open blockers"; [
      $fetched[]
      | if .unreadable then "### \(.key)\n\n_Could not read this work item._"
        else "### \(.key): \(.fields.summary)\n\n"
          + "- **Status:** \(.fields.status.name)\n"
          + "- **Type:** \(.fields.issuetype.name)\n"
          + "- **Assignee:** \(.fields.assignee.displayName // "Unassigned")\n"
          + (browse(.key) | if . then "- **URL:** \(.)\n" else "" end)
          + "\n" + (.fields.description | adf(4) | if . == "" then "_No description._" else . end)
        end
    ] | if length == 0 then null else join("\n\n") end),

    section("Subtasks"; [$f.subtasks[]? | "- \(ref)"] | bullets),

    section("Attachments"; [
      $f.attachment[]?
      | "- \(.filename) (\(.mimeType // "?"), \(.size | bytes)) — \(.author.displayName // "?"), \(.created | ts)"
    ] | bullets),

    section("Worklog"; [
      $f.worklog.worklogs[]?
      | "- \(.timeSpent) — \(.author.displayName // "?"), \(.started | ts)"
        + (.comment | adf(0) | if . == "" then "" else ": " + gsub("\n+"; " ") end)
    ] | bullets
      | if . != null and ($f.worklog.total // 0) > ($f.worklog.worklogs | length)
        then . + "\n\n_Showing \($f.worklog.worklogs | length) of \($f.worklog.total) entries._" else . end),

    section("Comments (\($f.comment.total // 0))"; [
      $f.comment.comments[]?
      | "### \(.author.displayName // "?") — \(.created | ts)"
        + (if .updated != .created then " (edited \(.updated | ts))" else "" end)
        + "\n\n" + (.body | adf(4))
    ] | if length == 0 then null else join("\n\n") end
      | if . != null and ($f.comment.total // 0) > ($f.comment.comments | length)
        then . + "\n\n_Showing \($f.comment.comments | length) of \($f.comment.total). Run `acli jira workitem comment list --key \($key) --paginate` for the rest._"
        else . end),

    section("Custom fields"; [
      $f | to_entries[] | select(.key | startswith("customfield_"))
      | (.value | [simple] | first // empty) as $v | "- \(.key): \($v)"
    ] | bullets)
  ]
| join("\n")
' "$tmp/issue.json"
