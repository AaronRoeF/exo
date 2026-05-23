#!/usr/bin/env bash
# exo-focus-gate.sh
# PreToolUse hook (matcher: Edit|Write).
# Warns when editing a file inside projects/<X>/ where <X> != declared focus.
# Exit 0 with warning to stderr - warns, does NOT block.
#
# Wire in ~/.claude/settings.json under "PreToolUse" with matcher "Edit|Write".
# Set KB_ROOT to override the default knowledge-base location.

set -u

KB_ROOT="${KB_ROOT:-$HOME/Exo}"
FOCUS_FILE="$HOME/.claude/current-focus.txt"

# Read tool input JSON from stdin
INPUT=$(cat 2>/dev/null) || exit 0
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

# Only trigger for files inside $KB_ROOT/projects/
case "$FILE_PATH" in
    "$KB_ROOT/projects/"*) ;;
    *) exit 0 ;;
esac

# Extract project name (first path component under projects/)
project=$(echo "$FILE_PATH" | sed -E "s|^${KB_ROOT}/projects/([^/]+).*|\1|")

# pulse.md edits on any project are allowed silently - that's how you update state
# at the end of a session before declaring a new focus.
case "$FILE_PATH" in
    */pulse.md|*/PULSE.md) exit 0 ;;
esac

# Read current focus (empty = no focus declared)
focus=""
if [ -f "$FOCUS_FILE" ]; then
    focus=$(head -n 1 "$FOCUS_FILE" | tr -d '[:space:]')
fi

# No focus declared yet -> gentle reminder, allow
if [ -z "$focus" ]; then
    echo "[exo] No focus declared. Editing projects/$project/. Declare focus: echo \"$project\" > $FOCUS_FILE" >&2
    exit 0
fi

# Focus matches -> silent allow
if [ "$focus" = "$project" ]; then
    exit 0
fi

# Mismatch -> warn (don't block)
cat >&2 <<EOF

[exo] CONTEXT SWITCH DETECTED

  Editing:        projects/$project/
  Declared focus: projects/$focus/

Before continuing:
  1. Update projects/$focus/pulse.md - Last Stop, completion, Next Actions.
  2. Announce the switch.
  3. Then proceed.

To switch focus now: echo "$project" > $FOCUS_FILE

EOF

exit 0
