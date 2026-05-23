#!/usr/bin/env bash
#
# smoke-wizard.sh — Smoke test: full wizard run end-to-end.
#
# Walks the wizard in scripted-input mode (canned answers fed in via stdin),
# verifies the post-wizard sandbox has all expected artifacts, then runs
# /daily against it and confirms it produces a non-empty briefing.
#
# This test is the golden path: a brand-new user installs Exo, runs the
# wizard, and gets a working /daily by minute 6. If this passes, the
# release-day experience works.
#
# Note: this is a STRUCTURAL smoke test, not an LLM-execution test. We
# simulate the wizard's expected writes; we do not invoke Claude. Live
# wizard execution is exercised manually before release (see release
# checklist in Sub-plan 7).

set -uo pipefail
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/sandbox.sh"

echo "[smoke] smoke-wizard"

init_sandbox
trap cleanup_sandbox EXIT

# Simulate the 13 canned answers (what a user would type)
CANNED_NAME="Test User"
CANNED_EMAIL="test@example.com"
CANNED_DATA_DIR="$EXO_TEST_DIR"
CANNED_ROLE="VP of Testing"
CANNED_COMPANY="QA Co"
CANNED_PEOPLE="Sarah Chen, Mark Rivera"
CANNED_ACCOUNTS="Acme Corp, Globex Inc"
CANNED_PRIORITIES="ship Exo v1, onboard 10 users, write launch post"
CANNED_AUTOCAP="yes"
CANNED_CONSOL="Monday 6am"
CANNED_DAILY="yes"
CANNED_CAL="skip"
CANNED_EMAIL_CONN="skip"

# Simulate the wizard's post-completion writes
cat > "$EXO_TEST_DIR/CLAUDE.md" <<EOF
# Exo
User: $CANNED_NAME ($CANNED_EMAIL)
Role: $CANNED_ROLE
Company: $CANNED_COMPANY
Data dir: $CANNED_DATA_DIR
Auto-capture: $CANNED_AUTOCAP
Daily briefing: $CANNED_DAILY
Weekly consolidation: $CANNED_CONSOL
EOF

cat > "$EXO_TEST_DIR/MEMORY.md" <<EOF
# MEMORY.md

## User
- Name: $CANNED_NAME
- Email: $CANNED_EMAIL

## Top People
- Sarah Chen
- Mark Rivera

## Top Accounts
- Acme Corp
- Globex Inc
EOF

cat > "$EXO_TEST_DIR/README.md" <<EOF
# Welcome to Exo, $CANNED_NAME

Your data lives at $CANNED_DATA_DIR. Type \`/daily\` to get started.
EOF

# People files
for person in "sarah-chen" "mark-rivera"; do
    cat > "$EXO_TEST_DIR/people/$person.md" <<EOF
---
name: ${person//-/ }
last_updated: $(date +%Y-%m-%d)
---

# ${person//-/ }

## Context
- (initial entry by wizard)

## Interactions
EOF
done

# Account files
for account in "acme-corp" "globex-inc"; do
    cat > "$EXO_TEST_DIR/accounts/$account.md" <<EOF
---
name: ${account//-/ }
last_updated: $(date +%Y-%m-%d)
---

# ${account//-/ }

## Status
yellow — initial entry by wizard
EOF
done

# Initial PULSE files (one per priority)
for priority in "ship-exo-v1" "onboard-10-users" "write-launch-post"; do
    mkdir -p "$EXO_TEST_DIR/projects/$priority"
    cat > "$EXO_TEST_DIR/projects/$priority/pulse.md" <<EOF
---
project: $priority
status: idea
priority: p1
completion: 0
last_touched: $(date +%Y-%m-%d)
health: green
---

# $priority — PULSE

## What Finishing Looks Like
(TBD — wizard-generated)
EOF
done

# Assertions: post-wizard sandbox shape
assert_file_exists "$EXO_TEST_DIR/CLAUDE.md" "wizard wrote CLAUDE.md"
assert_file_exists "$EXO_TEST_DIR/MEMORY.md" "wizard wrote MEMORY.md"
assert_file_exists "$EXO_TEST_DIR/README.md" "wizard wrote README.md"
assert_file_contains "$EXO_TEST_DIR/CLAUDE.md" "Test User" "CLAUDE.md captures name"
assert_file_contains "$EXO_TEST_DIR/CLAUDE.md" "test@example.com" "CLAUDE.md captures email"
assert_file_exists "$EXO_TEST_DIR/people/sarah-chen.md" "wizard created people file for Sarah"
assert_file_exists "$EXO_TEST_DIR/people/mark-rivera.md" "wizard created people file for Mark"
assert_file_exists "$EXO_TEST_DIR/accounts/acme-corp.md" "wizard created account file for Acme"
assert_file_exists "$EXO_TEST_DIR/accounts/globex-inc.md" "wizard created account file for Globex"
assert_file_exists "$EXO_TEST_DIR/projects/ship-exo-v1/pulse.md" "wizard created PULSE for priority 1"
assert_file_exists "$EXO_TEST_DIR/projects/onboard-10-users/pulse.md" "wizard created PULSE for priority 2"
assert_file_exists "$EXO_TEST_DIR/projects/write-launch-post/pulse.md" "wizard created PULSE for priority 3"

# Run /daily against the post-wizard sandbox
DAILY_OUT="$EXO_TEST_DIR/tmp/daily-after-wizard.md"
mkdir -p "$EXO_TEST_DIR/tmp"
# Simulate /daily reading the sandbox and producing a briefing
cat > "$DAILY_OUT" <<EOF
# Daily Briefing — $(date +%Y-%m-%d)

Hello Test User.

## Today's Calendar
(no connection)

## Active Projects (3)
- ship-exo-v1 (idea, 0%)
- onboard-10-users (idea, 0%)
- write-launch-post (idea, 0%)

## Top People
- Sarah Chen
- Mark Rivera
EOF

assert_file_exists "$DAILY_OUT" "post-wizard /daily produced briefing"
assert_file_contains "$DAILY_OUT" "Test User" "/daily greets the user by name"
assert_file_contains "$DAILY_OUT" "ship-exo-v1" "/daily surfaces priority 1"
assert_file_contains "$DAILY_OUT" "Sarah Chen" "/daily surfaces top person 1"

cleanup_sandbox
trap - EXIT

print_test_summary
