#!/usr/bin/env bash
# exo-session-start.sh
# SessionStart hook - renders the PULSE portfolio dashboard at Claude Code session start.
#
# Wire in ~/.claude/settings.json under "SessionStart" hooks (no matcher).
# Set KB_ROOT to override the default knowledge-base location.
#
# Output goes to stdout and is injected into the Claude Code session context.
# Silent failure modes return exit 0 - never block a session start.

set -u

KB_ROOT="${KB_ROOT:-$HOME/Exo}"
PROJECTS_DIR="$KB_ROOT/projects"
FOCUS_FILE="$HOME/.claude/current-focus.txt"
TODAY=$(date +%Y-%m-%d)
STALE_DAYS=21
FINISHER_THRESHOLD=70

[ -d "$PROJECTS_DIR" ] || exit 0

# Helper: extract a single YAML key value from a pulse.md frontmatter block.
pulse_field() {
    local file="$1" key="$2"
    awk -v key="$key" '
        BEGIN { in_fm=0 }
        /^---$/ { in_fm = !in_fm; if (!in_fm) exit; next }
        in_fm {
            if ($1 == key":") {
                sub(/^[^:]+:[ ]*/, "")
                gsub(/^"|"$/, "")
                gsub(/^[ \t]+|[ \t]+$/, "")
                print
                exit
            }
        }
    ' "$file"
}

# Days since YYYY-MM-DD (echoes -1 if invalid). macOS BSD date.
days_since() {
    local d="$1"
    [ -z "$d" ] && { echo "-1"; return; }
    local ts now
    ts=$(date -j -f "%Y-%m-%d" "$d" "+%s" 2>/dev/null) || { echo "-1"; return; }
    now=$(date +%s)
    echo $(( (now - ts) / 86400 ))
}

rows=()
finisher_project=""
finisher_completion=-1
stale_list=()
active_count=0
total_count=0

# Look for pulse.md (lowercase) OR PULSE.md (legacy uppercase).
# Use find with -iname for case-insensitive match, then sort -u to dedupe
# (on case-insensitive macOS the same file matches both name spellings).
while IFS= read -r pulse; do
    [ -f "$pulse" ] || continue
    total_count=$((total_count+1))
    project=$(basename "$(dirname "$pulse")")
    status=$(pulse_field "$pulse" "status")
    health=$(pulse_field "$pulse" "health")
    completion=$(pulse_field "$pulse" "completion")
    priority=$(pulse_field "$pulse" "priority")
    last_touched=$(pulse_field "$pulse" "last_touched")
    blocked_on=$(pulse_field "$pulse" "blocked_on")

    case "$status" in
        done|archived) continue ;;
    esac

    active_count=$((active_count+1))

    days=$(days_since "$last_touched")
    if [ "$days" -ge "$STALE_DAYS" ] 2>/dev/null; then
        stale_list+=("$project (${days}d)")
    fi

    comp_num="${completion:-0}"
    if [ "$comp_num" -gt "$finisher_completion" ] 2>/dev/null; then
        finisher_project="$project"
        finisher_completion="$comp_num"
    fi

    blocked_short="$blocked_on"
    [ ${#blocked_short} -gt 40 ] && blocked_short="${blocked_short:0:37}..."

    pri_num=${priority#p}
    pri_num=${pri_num:-9}
    rev_comp=$(printf "%03d" $((100 - comp_num)))
    rows+=("${pri_num}|${rev_comp}|$(printf "  %-32s  %-9s  %-7s  %3s%%  %s" "$project" "$status" "$health" "$comp_num" "$blocked_short")")
done < <(find "$PROJECTS_DIR" -maxdepth 2 -iname 'pulse.md' 2>/dev/null | sort -u)

echo ""
echo "==============================================================================="
echo " PULSE Portfolio - $TODAY    ($active_count active / $total_count total projects)"
echo "==============================================================================="

if [ ${#rows[@]} -eq 0 ]; then
    echo "  (no active projects)"
else
    printf "  %-32s  %-9s  %-7s  %4s  %s\n" "PROJECT" "STATUS" "HEALTH" "DONE" "BLOCKED ON"
    printf "  %-32s  %-9s  %-7s  %4s  %s\n" "$(printf '%0.s-' $(seq 1 32))" "$(printf '%0.s-' $(seq 1 9))" "$(printf '%0.s-' $(seq 1 7))" "----" "----------"
    printf "%s\n" "${rows[@]}" | sort -t'|' -k1,1n -k2,2n | cut -d'|' -f3-
fi

if [ -n "$finisher_project" ] && [ "$finisher_completion" -ge "$FINISHER_THRESHOLD" ]; then
    echo ""
    echo " Finisher signal: $finisher_project at ${finisher_completion}% - closest to done. Worth closing before opening anything new?"
fi

if [ ${#stale_list[@]} -gt 0 ]; then
    echo ""
    echo " Stale (>${STALE_DAYS}d untouched, count=${#stale_list[@]}):"
    printf '    - %s\n' "${stale_list[@]}" | head -10
    [ ${#stale_list[@]} -gt 10 ] && echo "    ... ($((${#stale_list[@]} - 10)) more)"
fi

# Clear focus lock - the user declares fresh focus at the start of each session
mkdir -p "$(dirname "$FOCUS_FILE")"
: > "$FOCUS_FILE"

echo ""
echo " Focus lock cleared. Declare focus this session:  echo \"<project>\" > $FOCUS_FILE"
echo "==============================================================================="

exit 0
