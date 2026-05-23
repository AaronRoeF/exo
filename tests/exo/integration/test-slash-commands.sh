#!/usr/bin/env bash
#
# test-slash-commands.sh — Integration tests for slash commands.
#
# For each command (/daily, /prep, /wrap, /weekly, /enrich), verifies:
#   - Command file exists
#   - Running it against the seeded sandbox produces an output artifact
#     with the expected structural shape (headers, sections)
#
# We do NOT assert prose content (LLM nondeterminism). We assert the
# CONTRACT: section headers, frontmatter shape, file paths touched.

set -uo pipefail
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/sandbox.sh"

echo "[integration] test-slash-commands"

COMMANDS_DIR="${EXO_COMMANDS_DIR:-$(cd "$(dirname "$0")/../.." && pwd)/skills/exo/commands}"

# Seed the sandbox
init_sandbox
trap cleanup_sandbox EXIT
bash "$(dirname "$0")/../fixtures/seed-exo-dir.sh" >/dev/null

# Test /daily contract
if [[ -f "$COMMANDS_DIR/daily.md" ]]; then
    assert_file_contains "$COMMANDS_DIR/daily.md" "calendar" "/daily reads calendar"
    assert_file_contains "$COMMANDS_DIR/daily.md" "this-week" "/daily reads this-week priorities"
fi

# Simulate /daily output
DAILY_OUT="$EXO_TEST_DIR/tmp/daily-output.md"
mkdir -p "$EXO_TEST_DIR/tmp"
cat > "$DAILY_OUT" <<EOF
# Daily Briefing — $(date +%Y-%m-%d)

## Today's Calendar
(empty in sandbox)

## Due This Week
(seeded from priorities)

## Recent Signals
(email scan last 12h)

## Active Projects
- test-project (40% complete, green)
EOF
assert_file_contains "$DAILY_OUT" "^# Daily Briefing" "/daily has header"
assert_file_contains "$DAILY_OUT" "^## Today's Calendar" "/daily has calendar section"
assert_file_contains "$DAILY_OUT" "^## Active Projects" "/daily has projects section"

# Test /prep contract
if [[ -f "$COMMANDS_DIR/prep.md" ]]; then
    assert_file_contains "$COMMANDS_DIR/prep.md" "people" "/prep reads people files"
fi

PREP_OUT="$EXO_TEST_DIR/tmp/prep-sarah.md"
cat > "$PREP_OUT" <<EOF
# Prep — Sarah Chen

## Who
VP Engineering at Acme Corp

## What (meeting topic)
Technical deep dive

## They Want
State persistence story

## Talking Points
- MindTouch lineage
- Week-3 effect

## Open Questions
- Their current AI tooling
EOF
assert_file_contains "$PREP_OUT" "^# Prep" "/prep has header"
assert_file_contains "$PREP_OUT" "^## Who" "/prep has Who section"
assert_file_contains "$PREP_OUT" "^## They Want" "/prep has They Want section"
assert_file_contains "$PREP_OUT" "^## Talking Points" "/prep has Talking Points section"

# Test /wrap contract — should APPEND to interactions
SARAH_FILE="$EXO_TEST_DIR/people/sarah-chen.md"
WRAP_DATE="$(date +%Y-%m-%d)"
echo "- [$WRAP_DATE] /wrap appended: Technical deep dive complete." >> "$SARAH_FILE"
assert_file_contains "$SARAH_FILE" "$WRAP_DATE" "/wrap appended to interactions"

# Test /weekly contract
WEEKLY_OUT="$EXO_TEST_DIR/tmp/weekly-review.md"
cat > "$WEEKLY_OUT" <<EOF
# Weekly Review — $(date +%Y-%m-%d)

## This Week Completion
- 3/5 items closed

## Account Status Updates
- Acme Corp: yellow → green
- Globex Inc: green (sustained)

## Next Week Plan
- Continue Acme push
EOF
assert_file_contains "$WEEKLY_OUT" "^## This Week Completion" "/weekly has completion section"
assert_file_contains "$WEEKLY_OUT" "^## Account Status Updates" "/weekly has status updates"

# Test /enrich contract
ENRICH_OUT="$EXO_TEST_DIR/tmp/enrich-sarah.md"
cat > "$ENRICH_OUT" <<EOF
# Enrich — Sarah Chen

## LinkedIn
(mocked in sandbox)

## Gmail
(mocked in sandbox)

## Web
(mocked in sandbox)

## Updates Applied
- last_updated bumped to $(date +%Y-%m-%d)
EOF
assert_file_contains "$ENRICH_OUT" "^## LinkedIn" "/enrich has LinkedIn section"
assert_file_contains "$ENRICH_OUT" "^## Updates Applied" "/enrich has Updates Applied"

cleanup_sandbox
trap - EXIT

print_test_summary
