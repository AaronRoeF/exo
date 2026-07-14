#!/usr/bin/env bash
#
# test-trace-audit.sh — Unit tests for the TRACE audit hook.
#
# Verifies:
#   - the hook writes a signed record per tool call into a chained log
#   - a clean chain verifies (--verify exits 0)
#   - tampering with a record breaks verification (--verify exits 1)
#
# The hook depends on python3 + agentrust-trace. Those are not part of the base
# test environment (run-all.sh only requires jq), so this test SKIPS cleanly
# when either is missing rather than failing the suite.

set -uo pipefail
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/sandbox.sh"

echo "[unit] test-trace-audit"

HOOK="$(cd "$(dirname "$0")/../../.." && pwd)/hooks/exo-trace-audit.py"

# Structural check runs regardless of Python availability.
assert_file_exists "$HOOK" "trace-audit hook present"
assert_file_contains "$HOOK" "software-only" "hook records software-only platform (hardware honesty)"

# Dependency gate: skip the behavioural checks if deps are absent.
if ! command -v python3 >/dev/null 2>&1; then
    echo "  SKIP: python3 not installed — skipping behavioural checks"
    print_test_summary
    exit $?
fi
if ! python3 -c "import agentrust_trace" >/dev/null 2>&1; then
    echo "  SKIP: agentrust-trace not installed (pip install agentrust-trace) — skipping behavioural checks"
    print_test_summary
    exit $?
fi

init_sandbox
trap cleanup_sandbox EXIT

export KB_ROOT="$EXO_TEST_DIR"
export EXO_TRACE_CONFIG="$EXO_TEST_DIR/trace-cfg"
RECORDS="$EXO_TEST_DIR/trace/records.jsonl"

# Two tool calls through the hook.
echo '{"tool_name":"Bash","tool_input":{"command":"ls"},"tool_response":{"stdout":"a"}}' | python3 "$HOOK"
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/x","content":"hi"},"tool_response":{"ok":true}}' | python3 "$HOOK"

assert_file_exists "$RECORDS" "records file written"
RECORD_COUNT="$(grep -c . "$RECORDS" 2>/dev/null || echo 0)"
assert_eq "2" "$RECORD_COUNT" "two records appended"
assert_file_contains "$RECORDS" "trace-v0.1" "records carry the TRACE v0.1 profile"
assert_file_contains "$RECORDS" "\"signature\":" "records are signed"

# Clean chain verifies. Capture the exit code into a variable and compare with
# assert_eq: the shared assert_exit_code helper reads $? after its own `local`
# assignment, so it only reports 0 reliably.
python3 "$HOOK" --verify >/dev/null 2>&1
CLEAN_RC=$?
assert_eq "0" "$CLEAN_RC" "clean chain verifies"

# Tamper with the first record; verification must fail. Done in python so the
# edit is deterministic across platforms (we are already past the python gate).
python3 - "$RECORDS" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
text = p.read_text()
assert '"data_class":"personal"' in text, "expected field not found to tamper"
p.write_text(text.replace('"data_class":"personal"', '"data_class":"secret"', 1))
PY
python3 "$HOOK" --verify >/dev/null 2>&1
TAMPER_RC=$?
assert_eq "1" "$TAMPER_RC" "tampered chain fails verification"

cleanup_sandbox
trap - EXIT

print_test_summary
