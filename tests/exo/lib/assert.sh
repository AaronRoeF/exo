#!/usr/bin/env bash
#
# assert.sh — Shared assertion library for Exo test harness.
#
# Source this file at the top of every test: source "$(dirname "$0")/../lib/assert.sh"
#
# Each assert function:
#   - Prints PASS or FAIL with context
#   - Increments TESTS_RUN / TESTS_FAILED counters
#   - Returns 0 on pass, 1 on fail (does NOT exit — test scripts decide aggregation)

TESTS_RUN=0
TESTS_FAILED=0
TESTS_PASSED=0

_assert_log_pass() {
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $1"
}

_assert_log_fail() {
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && echo "        $2"
}

# assert_eq <expected> <actual> <message>
assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="${3:-assert_eq}"
    if [[ "$expected" == "$actual" ]]; then
        _assert_log_pass "$message"
        return 0
    else
        _assert_log_fail "$message" "expected='$expected' actual='$actual'"
        return 1
    fi
}

# assert_file_exists <path> <message>
assert_file_exists() {
    local path="$1"
    local message="${2:-file exists: $path}"
    if [[ -f "$path" ]]; then
        _assert_log_pass "$message"
        return 0
    else
        _assert_log_fail "$message" "missing file: $path"
        return 1
    fi
}

# assert_dir_exists <path> <message>
assert_dir_exists() {
    local path="$1"
    local message="${2:-dir exists: $path}"
    if [[ -d "$path" ]]; then
        _assert_log_pass "$message"
        return 0
    else
        _assert_log_fail "$message" "missing dir: $path"
        return 1
    fi
}

# assert_file_contains <path> <pattern> <message>
assert_file_contains() {
    local path="$1"
    local pattern="$2"
    local message="${3:-file contains pattern: $pattern}"
    if [[ ! -f "$path" ]]; then
        _assert_log_fail "$message" "file does not exist: $path"
        return 1
    fi
    if grep -qE "$pattern" "$path"; then
        _assert_log_pass "$message"
        return 0
    else
        _assert_log_fail "$message" "pattern not found in $path: $pattern"
        return 1
    fi
}

# assert_json_shape <file> <jq_expr> <expected> <message>
# Example: assert_json_shape result.json '.tools | length' 8 "MCP server exposes 8 tools"
assert_json_shape() {
    local file="$1"
    local expr="$2"
    local expected="$3"
    local message="${4:-json shape}"
    if ! command -v jq >/dev/null 2>&1; then
        _assert_log_fail "$message" "jq not installed"
        return 1
    fi
    local actual
    actual="$(jq -r "$expr" "$file" 2>/dev/null || echo "JQ_ERROR")"
    if [[ "$actual" == "$expected" ]]; then
        _assert_log_pass "$message"
        return 0
    else
        _assert_log_fail "$message" "jq expr='$expr' expected='$expected' actual='$actual'"
        return 1
    fi
}

# assert_exit_code <expected_code> <message>
# Use after running a command: $cmd; assert_exit_code 0 "command succeeded"
assert_exit_code() {
    local expected="$1"
    local actual="$?"
    local message="${2:-exit code}"
    if [[ "$expected" == "$actual" ]]; then
        _assert_log_pass "$message"
        return 0
    else
        _assert_log_fail "$message" "expected exit=$expected actual=$actual"
        return 1
    fi
}

# print_test_summary — call at the end of each test file
print_test_summary() {
    echo ""
    echo "  ---"
    echo "  Tests run:    $TESTS_RUN"
    echo "  Tests passed: $TESTS_PASSED"
    echo "  Tests failed: $TESTS_FAILED"
    if [[ "$TESTS_FAILED" -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}
