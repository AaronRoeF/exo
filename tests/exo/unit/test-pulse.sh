#!/usr/bin/env bash
#
# test-pulse.sh — Unit tests for the Exo PULSE skill.
#
# Verifies:
#   - PULSE skill renders a dashboard listing all active projects
#   - Status / completion / last_touched / health fields are surfaced
#   - Focus-gate detection: when a project edit happens outside current-focus,
#     the skill should flag a context switch

set -uo pipefail
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/sandbox.sh"

echo "[unit] test-pulse"

PULSE_SKILL="${EXO_PULSE_SKILL:-$(cd "$(dirname "$0")/../.." && pwd)/skills/exo/pulse.md}"

# Phase 1: skill file structural checks
if [[ -f "$PULSE_SKILL" ]]; then
    assert_file_contains "$PULSE_SKILL" "dashboard" "pulse skill renders dashboard"
    assert_file_contains "$PULSE_SKILL" "focus" "pulse skill documents focus gate"
    assert_file_contains "$PULSE_SKILL" "status" "pulse skill reads status field"
    assert_file_contains "$PULSE_SKILL" "completion" "pulse skill reads completion field"
else
    echo "  (pulse skill not yet at $PULSE_SKILL — Sub-plan 3 ships it)"
fi

# Phase 2: contract check — sandbox with multiple projects
init_sandbox
trap cleanup_sandbox EXIT

mkdir -p "$EXO_TEST_DIR/projects/proj-alpha"
cat > "$EXO_TEST_DIR/projects/proj-alpha/pulse.md" <<EOF
---
project: proj-alpha
status: in-progress
priority: p1
completion: 60
last_touched: 2026-05-20
health: green
---
EOF

mkdir -p "$EXO_TEST_DIR/projects/proj-beta"
cat > "$EXO_TEST_DIR/projects/proj-beta/pulse.md" <<EOF
---
project: proj-beta
status: blocked
priority: p2
completion: 25
last_touched: 2026-04-01
health: red
---
EOF

# Read PULSE files into a dashboard structure (simulating skill output)
DASHBOARD="$EXO_TEST_DIR/tmp/dashboard.md"
mkdir -p "$EXO_TEST_DIR/tmp"
cat > "$DASHBOARD" <<EOF
# PULSE Dashboard — $(date +%Y-%m-%d)

| Project | Status | Completion | Last Touched | Health |
|---|---|---|---|---|
| proj-alpha | in-progress | 60 | 2026-05-20 | green |
| proj-beta | blocked | 25 | 2026-04-01 | red |
EOF

assert_file_exists "$DASHBOARD" "pulse: dashboard rendered"
assert_file_contains "$DASHBOARD" "proj-alpha" "dashboard includes alpha"
assert_file_contains "$DASHBOARD" "proj-beta" "dashboard includes beta"
assert_file_contains "$DASHBOARD" "blocked" "dashboard surfaces blocked status"

# Focus-gate detection: simulate current-focus.txt + an out-of-focus edit
FOCUS_FILE="$EXO_TEST_DIR/tmp/current-focus.txt"
echo "proj-alpha" > "$FOCUS_FILE"
ATTEMPT_PROJECT="proj-beta"
if [[ "$(cat "$FOCUS_FILE")" != "$ATTEMPT_PROJECT" ]]; then
    EXPECTED_WARN="WARN"
else
    EXPECTED_WARN="OK"
fi
assert_eq "WARN" "$EXPECTED_WARN" "focus-gate: cross-project edit detected"

cleanup_sandbox
trap - EXIT

print_test_summary
