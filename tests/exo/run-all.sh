#!/usr/bin/env bash
#
# run-all.sh — Top-level Exo test runner.
#
# Orchestrates unit → integration → smoke in order. Skips regression by default
# (must opt in with --regression because it reads real data).
#
# Exit codes:
#   0 = all pass
#   1 = at least one test failed
#   2 = infrastructure error (missing dep, sandbox setup failed)
#
# Usage:
#   bash run-all.sh                  # unit + integration + smoke
#   bash run-all.sh --skip-smoke     # unit + integration only (fast feedback)
#   bash run-all.sh --regression     # adds regression sweep at the end
#   bash run-all.sh --only-unit      # unit only
#   bash run-all.sh --only-integration
#   bash run-all.sh --only-smoke

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$TESTS_DIR/lib/sandbox.sh"

# Always clean up on exit (success OR failure)
trap cleanup_sandbox EXIT

# Argument parsing
RUN_UNIT=1
RUN_INTEGRATION=1
RUN_SMOKE=1
RUN_REGRESSION=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-smoke) RUN_SMOKE=0 ;;
        --regression) RUN_REGRESSION=1 ;;
        --only-unit) RUN_UNIT=1; RUN_INTEGRATION=0; RUN_SMOKE=0 ;;
        --only-integration) RUN_UNIT=0; RUN_INTEGRATION=1; RUN_SMOKE=0 ;;
        --only-smoke) RUN_UNIT=0; RUN_INTEGRATION=0; RUN_SMOKE=1 ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
    shift
done

# Dependency check
if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq not installed. brew install jq" >&2
    exit 2
fi

OVERALL_PASS=0
OVERALL_FAIL=0
FAILED_FILES=()

run_layer() {
    local layer="$1"
    local glob="$2"
    echo ""
    echo "================================================"
    echo " Running $layer tests"
    echo "================================================"
    local files=("$TESTS_DIR/$glob"/test-*.sh "$TESTS_DIR/$glob"/smoke-*.sh "$TESTS_DIR/$glob"/sweep-*.sh)
    local any=0
    for f in "${files[@]}"; do
        [[ -f "$f" ]] || continue
        any=1
        echo ""
        echo "▸ $f"
        bash "$f"
        local rc=$?
        if [[ "$rc" -eq 0 ]]; then
            OVERALL_PASS=$((OVERALL_PASS + 1))
        else
            OVERALL_FAIL=$((OVERALL_FAIL + 1))
            FAILED_FILES+=("$f")
        fi
    done
    if [[ "$any" -eq 0 ]]; then
        echo "(no $layer tests found)"
    fi
}

[[ "$RUN_UNIT" -eq 1 ]] && run_layer "unit" "unit"
[[ "$RUN_INTEGRATION" -eq 1 ]] && run_layer "integration" "integration"
[[ "$RUN_SMOKE" -eq 1 ]] && run_layer "smoke" "smoke"
[[ "$RUN_REGRESSION" -eq 1 ]] && run_layer "regression" "regression"

echo ""
echo "================================================"
echo " Summary"
echo "================================================"
echo "  Test files passed: $OVERALL_PASS"
echo "  Test files failed: $OVERALL_FAIL"
if [[ "$OVERALL_FAIL" -gt 0 ]]; then
    echo "  Failed files:"
    for f in "${FAILED_FILES[@]}"; do
        echo "    - $f"
    done
    exit 1
fi
exit 0
