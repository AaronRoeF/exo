#!/usr/bin/env bash
#
# seed-exo-dir.sh — populate ~/Exo-test/ with fixture content for tests.
#
# Assumes init_sandbox already ran (subdirs exist).
# Idempotent: overwrites existing fixture files in the sandbox.

set -euo pipefail

FIXTURES_DIR="$(cd "$(dirname "$0")" && pwd)"
EXO_TEST_DIR="${EXO_TEST_DIR:-$HOME/Exo-test}"

if [[ ! -d "$EXO_TEST_DIR" ]]; then
    echo "ERROR: $EXO_TEST_DIR does not exist. Run init_sandbox first." >&2
    exit 2
fi

# People
cp "$FIXTURES_DIR/sample-people/sarah-chen.md" "$EXO_TEST_DIR/people/"
cp "$FIXTURES_DIR/sample-people/mark-rivera.md" "$EXO_TEST_DIR/people/"

# Accounts
cp "$FIXTURES_DIR/sample-accounts/acme-corp.md" "$EXO_TEST_DIR/accounts/"
cp "$FIXTURES_DIR/sample-accounts/globex-inc.md" "$EXO_TEST_DIR/accounts/"

# Project + PULSE
mkdir -p "$EXO_TEST_DIR/projects/test-project"
cp "$FIXTURES_DIR/sample-pulse.md" "$EXO_TEST_DIR/projects/test-project/pulse.md"

# Observations
cp "$FIXTURES_DIR/sample-observations.md" "$EXO_TEST_DIR/observations/2026-05-15.md"

# Bare-minimum CLAUDE.md so skills find a config
cat > "$EXO_TEST_DIR/CLAUDE.md" <<'EOF'
# Exo Test Sandbox CLAUDE.md

User: Test User (test@example.com)
Data dir: ~/Exo-test/
Auto-capture: enabled
Daily briefing: enabled
EOF

echo "Seeded $EXO_TEST_DIR with fixtures:"
ls -R "$EXO_TEST_DIR"
