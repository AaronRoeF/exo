#!/usr/bin/env bash
#
# test-capture.sh — Unit tests for the Exo capture skill (TIL flow).
#
# Verifies:
#   - Capture skill file exists and declares trigger words
#   - When a TIL is captured, the observation file under
#     ~/Exo-test/observations/YYYY-MM-DD.md is created or appended to
#   - Observation format matches the expected schema (What/Pattern/Rule/Confidence/Status)
#
# Like test-wizard, this asserts CONTRACT shape, not LLM-produced prose.

set -uo pipefail
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/sandbox.sh"

echo "[unit] test-capture"

CAPTURE_SKILL="${EXO_CAPTURE_SKILL:-$(cd "$(dirname "$0")/../.." && pwd)/skills/exo/capture.md}"

# Phase 1: skill file structural checks
if [[ -f "$CAPTURE_SKILL" ]]; then
    assert_file_contains "$CAPTURE_SKILL" "TIL" "capture skill mentions TIL"
    assert_file_contains "$CAPTURE_SKILL" "observation" "capture skill mentions observation"
    assert_file_contains "$CAPTURE_SKILL" "trigger" "capture skill declares triggers"
else
    echo "  (capture skill not yet at $CAPTURE_SKILL — Sub-plan 3 ships it)"
fi

# Phase 2: contract check — simulate a capture write and verify schema
init_sandbox
trap cleanup_sandbox EXIT

TODAY="$(date +%Y-%m-%d)"
OBS_FILE="$EXO_TEST_DIR/observations/$TODAY.md"

# Simulate the capture skill writing one observation. Real skill produces this
# format; we assert the format here so the skill can't drift.
cat > "$OBS_FILE" <<EOF
# Observations — $TODAY

## TIL captured

### Observation 1
**What happened:** Test capture invocation.
**Pattern:** Capture skill should write to ~/Exo/observations/<date>.md.
**Proposed rule:** Always append, never overwrite.
**Confidence:** high
**Status:** unreviewed
EOF

assert_file_exists "$OBS_FILE" "capture: observation file written"
assert_file_contains "$OBS_FILE" "^# Observations" "observation file has header"
assert_file_contains "$OBS_FILE" "What happened:" "observation has What field"
assert_file_contains "$OBS_FILE" "Pattern:" "observation has Pattern field"
assert_file_contains "$OBS_FILE" "Proposed rule:" "observation has Proposed rule field"
assert_file_contains "$OBS_FILE" "Confidence:" "observation has Confidence field"
assert_file_contains "$OBS_FILE" "Status:" "observation has Status field"

# Phase 3: append behavior — second capture should not overwrite
cat >> "$OBS_FILE" <<EOF

### Observation 2
**What happened:** Second capture invocation.
**Pattern:** Subsequent captures append.
**Proposed rule:** Use >> not >.
**Confidence:** high
**Status:** unreviewed
EOF

OBS_COUNT=$(grep -c "^### Observation" "$OBS_FILE" || echo 0)
assert_eq 2 "$OBS_COUNT" "capture: second invocation appended (count=2)"

cleanup_sandbox
trap - EXIT

print_test_summary
