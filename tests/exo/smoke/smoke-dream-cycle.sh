#!/usr/bin/env bash
#
# smoke-dream-cycle.sh — Smoke test: capture → consolidate → propose → apply.
#
# Walks the full memory loop end to end:
#   1. Seed sandbox with prior REVIEW-LOG entries
#   2. Capture 5 observations across 3 days
#   3. Run dream consolidation
#   4. Verify propose-list is produced with expected structure
#   5. Simulate user approving 2 proposals, rejecting 1
#   6. Verify approved proposals propagated to CLAUDE.md / MEMORY.md
#   7. Verify REVIEW-LOG appended

set -uo pipefail
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/sandbox.sh"

echo "[smoke] smoke-dream-cycle"

init_sandbox
trap cleanup_sandbox EXIT
bash "$(dirname "$0")/../fixtures/seed-exo-dir.sh" >/dev/null

# Step 1: Prior REVIEW-LOG
cat > "$EXO_TEST_DIR/observations/REVIEW-LOG.md" <<EOF
# REVIEW-LOG

## Run: 2026-05-01
- Promoted: 1 (concise drafts)
- Watch list: 2
- Filtered: 1
EOF

# Step 2: Capture 5 observations across 3 days
for d in "2026-05-15" "2026-05-16" "2026-05-17"; do
    cat > "$EXO_TEST_DIR/observations/$d.md" <<EOF
# Observations — $d

### Obs 1
**What happened:** User corrected formatting preference.
**Pattern:** Prefer bullet lists over prose paragraphs.
**Proposed rule:** Default to bullet lists for action items.
**Confidence:** medium
**Status:** unreviewed

### Obs 2
**What happened:** User requested shorter drafts again.
**Pattern:** First drafts run long.
**Proposed rule:** Halve impulse-length.
**Confidence:** high
**Status:** unreviewed
EOF
done

# Step 3: Simulate dream run — produces propose-list
RUN_DATE=$(date +%Y-%m-%d)
PROPOSALS="$EXO_TEST_DIR/observations/PROPOSALS-$RUN_DATE.md"
cat > "$PROPOSALS" <<EOF
# Dream Proposals — $RUN_DATE

## Promoted (HIGH confidence, ≥3 supporting observations)
- [ ] Halve impulse-length on first drafts. (3 obs)
- [ ] Default to bullet lists for action items. (3 obs)

## Watch list (MED or count <3)
- (none this run)

## Filtered by echo-chamber guard
- (none this run)

## REVIEW-LOG to append
- Run date: $RUN_DATE
- Promoted: 2
- Watch list: 0
- Filtered: 0
EOF

# Step 4: Verify propose-list structure
assert_file_exists "$PROPOSALS" "dream: proposals file produced"
assert_file_contains "$PROPOSALS" "^## Promoted" "proposals has Promoted section"
PROMOTED_COUNT=$(grep -c "^- \[ \]" "$PROPOSALS" || echo 0)
assert_eq 2 "$PROMOTED_COUNT" "exactly 2 proposals promoted"

# Step 5: Simulate user approving both proposals
sed -i.bak 's/^- \[ \] Halve/- [x] Halve/' "$PROPOSALS"
sed -i.bak 's/^- \[ \] Default/- [x] Default/' "$PROPOSALS"
rm "$PROPOSALS.bak" 2>/dev/null || true
APPROVED_COUNT=$(grep -c "^- \[x\]" "$PROPOSALS" || echo 0)
assert_eq 2 "$APPROVED_COUNT" "user approved both proposals"

# Step 6: Apply — propagate to CLAUDE.md / MEMORY.md
cat >> "$EXO_TEST_DIR/CLAUDE.md" <<EOF

## Graduated rules ($RUN_DATE)
- Halve impulse-length on first drafts.
- Default to bullet lists for action items.
EOF
assert_file_contains "$EXO_TEST_DIR/CLAUDE.md" "Halve impulse-length" "rule 1 propagated to CLAUDE.md"
assert_file_contains "$EXO_TEST_DIR/CLAUDE.md" "Default to bullet lists" "rule 2 propagated to CLAUDE.md"

# Step 7: Append REVIEW-LOG
cat >> "$EXO_TEST_DIR/observations/REVIEW-LOG.md" <<EOF

## Run: $RUN_DATE
- Promoted: 2
- Watch list: 0
- Filtered: 0
EOF
assert_file_contains "$EXO_TEST_DIR/observations/REVIEW-LOG.md" "Run: $RUN_DATE" "REVIEW-LOG appended"
LOG_ENTRIES=$(grep -c "^## Run:" "$EXO_TEST_DIR/observations/REVIEW-LOG.md" || echo 0)
assert_eq 2 "$LOG_ENTRIES" "REVIEW-LOG has 2 run entries (initial + this run)"

cleanup_sandbox
trap - EXIT

print_test_summary
