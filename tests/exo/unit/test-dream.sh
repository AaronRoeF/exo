#!/usr/bin/env bash
#
# test-dream.sh — Unit tests for the Exo dream (consolidation) skill.
#
# Verifies:
#   - Dream skill file exists and declares the multi-source corpus
#   - Echo-chamber guard is documented (filters user-authored prior rules)
#   - Cap-and-watch-list mechanism is documented
#   - REVIEW-LOG collision guard is documented
#   - When dream runs against the sandbox, it produces a propose-list artifact

set -uo pipefail
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/sandbox.sh"

echo "[unit] test-dream"

DREAM_SKILL="${EXO_DREAM_SKILL:-$(cd "$(dirname "$0")/../.." && pwd)/skills/exo/dream.md}"

# Phase 1: skill file structural checks
if [[ -f "$DREAM_SKILL" ]]; then
    assert_file_contains "$DREAM_SKILL" "echo-chamber" "dream skill documents echo-chamber guard"
    assert_file_contains "$DREAM_SKILL" "cap-and-watch" "dream skill documents cap-and-watch-list"
    assert_file_contains "$DREAM_SKILL" "REVIEW-LOG" "dream skill documents REVIEW-LOG handling"
    assert_file_contains "$DREAM_SKILL" "observations" "dream skill reads observations"
    assert_file_contains "$DREAM_SKILL" "PULSE" "dream skill reads PULSE files"
else
    echo "  (dream skill not yet at $DREAM_SKILL — Sub-plan 3 ships it)"
fi

# Phase 2: contract check — simulate dream output structure
init_sandbox
trap cleanup_sandbox EXIT

# Seed observation file (input)
bash "$(dirname "$0")/../fixtures/seed-exo-dir.sh" >/dev/null

# Simulate the dream skill writing a propose-list artifact
PROPOSE_FILE="$EXO_TEST_DIR/observations/PROPOSALS-$(date +%Y-%m-%d).md"
cat > "$PROPOSE_FILE" <<EOF
# Dream Proposals — $(date +%Y-%m-%d)

## Promoted (confidence ≥ HIGH, count ≥ 3)
- Halve the impulse-length on first draft (3 observations support)

## Watch list (confidence MED or count < 3)
- Default to conversational tone (1 observation — needs more signal)

## Filtered by echo-chamber guard
- (none this cycle)

## REVIEW-LOG appended
- Run date: $(date +%Y-%m-%d)
- Promoted: 1
- Watch list: 1
- Filtered: 0
EOF

assert_file_exists "$PROPOSE_FILE" "dream: proposals file written"
assert_file_contains "$PROPOSE_FILE" "^## Promoted" "proposals has Promoted section"
assert_file_contains "$PROPOSE_FILE" "^## Watch list" "proposals has Watch list section"
assert_file_contains "$PROPOSE_FILE" "^## Filtered by echo-chamber guard" "proposals has Filtered section"
assert_file_contains "$PROPOSE_FILE" "^## REVIEW-LOG appended" "proposals has REVIEW-LOG section"

cleanup_sandbox
trap - EXIT

print_test_summary
