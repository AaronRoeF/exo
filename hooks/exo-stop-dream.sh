#!/usr/bin/env bash
# exo-stop-dream.sh
# Stop hook - at session end, check whether dream thresholds are met.
# If so, surface a suggestion to run dream before closing.
#
# Thresholds:
#   - 30+ unreviewed observations in ~/Exo/observations/ since last dream, OR
#   - 7+ days since the last dream entry in ~/Exo/observations/REVIEW-LOG.md
#
# Output goes to stderr (visible to the user, doesn't pollute Claude's context).
# Exit 0 always - this is a suggestion, never blocks session close.
#
# Wire in ~/.claude/settings.json under "Stop" hooks (no matcher).

set -u

KB_ROOT="${KB_ROOT:-$HOME/Exo}"
OBS_DIR="$KB_ROOT/observations"
REVIEW_LOG="$OBS_DIR/REVIEW-LOG.md"
THRESHOLD_OBS=30
THRESHOLD_DAYS=7

[ -d "$OBS_DIR" ] || exit 0

# Find the most recent dream date from REVIEW-LOG.md
last_dream_date=""
if [ -f "$REVIEW_LOG" ]; then
    last_dream_date=$(grep -E '^## [0-9]{4}-[0-9]{2}-[0-9]{2}' "$REVIEW_LOG" | tail -1 | awk '{print $2}')
fi

# Days since last dream
days_since_dream=999
if [ -n "$last_dream_date" ]; then
    ts=$(date -j -f "%Y-%m-%d" "$last_dream_date" "+%s" 2>/dev/null) || ts=""
    if [ -n "$ts" ]; then
        now=$(date +%s)
        days_since_dream=$(( (now - ts) / 86400 ))
    fi
fi

# Count observation files newer than the last dream
if [ -n "$last_dream_date" ] && [ -f "$REVIEW_LOG" ]; then
    new_obs_count=$(find "$OBS_DIR" -name '[0-9]*.md' -newer "$REVIEW_LOG" 2>/dev/null | wc -l | tr -d ' ')
else
    # No prior dream - count all observations
    new_obs_count=$(find "$OBS_DIR" -name '[0-9]*.md' 2>/dev/null | wc -l | tr -d ' ')
fi

# Decision: prompt if either threshold is met
should_prompt=0
[ "$new_obs_count" -ge "$THRESHOLD_OBS" ] && should_prompt=1
[ "$days_since_dream" -ge "$THRESHOLD_DAYS" ] && should_prompt=1

if [ "$should_prompt" -eq 1 ]; then
    cat >&2 <<EOF

[exo] Dream threshold reached.
   New observation files since last dream: $new_obs_count (threshold: $THRESHOLD_OBS)
   Days since last dream:                  $days_since_dream (threshold: $THRESHOLD_DAYS)

Run \`dream\` next session to consolidate. Or run it now if you have a minute.
EOF
fi

exit 0
