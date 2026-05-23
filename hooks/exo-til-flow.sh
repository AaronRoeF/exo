#!/usr/bin/env bash
# exo-til-flow.sh
# Prompts the model to propose 2-3 candidate TILs based on session activity.
# Fires after /compact or on demand; can also be wired to PreToolUse as a
# debounced flow-aware capture nudge (see exo docs/customization.md).
#
# Output goes to stdout (gets injected into the Claude session as instructions).
# Exit 0 always.

set -u

KB_ROOT="${KB_ROOT:-$HOME/Exo}"
TODAY=$(date '+%Y-%m-%d')
OBS_DIR="$KB_ROOT/observations"
OBS_FILE="$OBS_DIR/$TODAY.md"
REVIEW_LOG="$OBS_DIR/REVIEW-LOG.md"

# Count today's observations
if [ -f "$OBS_FILE" ]; then
    TODAY_COUNT=$(grep -c '^## \[' "$OBS_FILE" 2>/dev/null || echo "0")
else
    TODAY_COUNT=0
fi

# Count total unreviewed observations across all files
TOTAL_OBS=0
LAST_REVIEW="never"
if [ -f "$REVIEW_LOG" ]; then
    LAST_REVIEW=$(grep -E '^## [0-9]{4}-[0-9]{2}-[0-9]{2}' "$REVIEW_LOG" | tail -1 | awk '{print $2}')
    [ -z "$LAST_REVIEW" ] && LAST_REVIEW="never"
fi

if [ "$LAST_REVIEW" = "never" ]; then
    for f in "$OBS_DIR"/2*.md; do
        [ -f "$f" ] || continue
        COUNT=$(grep -c '^## \[' "$f" 2>/dev/null || echo "0")
        TOTAL_OBS=$((TOTAL_OBS + COUNT))
    done
else
    for f in "$OBS_DIR"/2*.md; do
        [ -f "$f" ] || continue
        FILE_DATE=$(basename "$f" .md)
        if [[ "$FILE_DATE" > "$LAST_REVIEW" ]]; then
            COUNT=$(grep -c '^## \[' "$f" 2>/dev/null || echo "0")
            TOTAL_OBS=$((TOTAL_OBS + COUNT))
        fi
    done
fi

# Build the prompt
REMINDER="TIL Checkpoint - ACTION REQUIRED: Scan the previous context and PROPOSE 2-3 specific TIL candidates based on what you observed."
REMINDER="$REMINDER\nDo NOT ask the user to provide TILs. YOU identify the learnings from the session - corrections, surprises, MCP gotchas, workflow patterns, things that worked - and propose them. The user will edit/approve."
REMINDER="$REMINDER\n- Today's observations so far: $TODAY_COUNT"
REMINDER="$REMINDER\n- Unreviewed observations: $TOTAL_OBS (last dream: $LAST_REVIEW)"

# Check if dream is recommended (30+ unreviewed observations OR 7+ days since last)
DREAM_NEEDED=false
DREAM_REASON=""

if [ "$TOTAL_OBS" -ge 30 ]; then
    DREAM_NEEDED=true
    DREAM_REASON="30+ unreviewed observations ($TOTAL_OBS total)"
fi

if [ "$LAST_REVIEW" != "never" ]; then
    DAYS_SINCE=$(( ($(date +%s) - $(date -j -f '%Y-%m-%d' "$LAST_REVIEW" +%s 2>/dev/null || echo $(date +%s))) / 86400 ))
    if [ "$DAYS_SINCE" -ge 7 ] && [ "$TOTAL_OBS" -gt 0 ]; then
        DREAM_NEEDED=true
        if [ -n "$DREAM_REASON" ]; then
            DREAM_REASON="$DREAM_REASON + ${DAYS_SINCE} days since last dream"
        else
            DREAM_REASON="${DAYS_SINCE} days since last dream with $TOTAL_OBS unreviewed observations"
        fi
    fi
elif [ "$TOTAL_OBS" -ge 15 ]; then
    DREAM_NEEDED=true
    DREAM_REASON="$TOTAL_OBS observations accumulated and no dream has ever been run"
fi

if [ "$DREAM_NEEDED" = true ]; then
    REMINDER="$REMINDER\n- DREAM RECOMMENDED: $DREAM_REASON. After capturing TILs, run \`dream\` to check for graduation candidates."
fi

REMINDER="$REMINDER\nFormat each candidate as: [signal-strength] [category] - [title]: [one-line why this matters]"
REMINDER="$REMINDER\nSignal-strength: strong | weak"
REMINDER="$REMINDER\nCategories: mcp, skill, claude, code, workflow, product, meta"

echo -e "$REMINDER"
