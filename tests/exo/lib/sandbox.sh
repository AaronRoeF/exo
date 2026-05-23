#!/usr/bin/env bash
#
# sandbox.sh — Sandbox lifecycle for Exo tests.
#
# Every test writes to ~/Exo-test/, never ~/Exo/. This file enforces that
# invariant via init/cleanup helpers.
#
# Usage at top of a test:
#   source "$(dirname "$0")/../lib/sandbox.sh"
#   init_sandbox
#   trap cleanup_sandbox EXIT
#   # ... test body uses $EXO_TEST_DIR ...

EXO_TEST_DIR="${EXO_TEST_DIR:-$HOME/Exo-test}"
EXO_REAL_DIR="${EXO_REAL_DIR:-$HOME/Exo}"

# Refuse to operate if EXO_TEST_DIR == EXO_REAL_DIR (safety check)
_sandbox_safety_check() {
    if [[ "$EXO_TEST_DIR" == "$EXO_REAL_DIR" ]]; then
        echo "FATAL: EXO_TEST_DIR equals EXO_REAL_DIR. Refusing to proceed." >&2
        exit 2
    fi
    if [[ "$EXO_TEST_DIR" == "$HOME" ]] || [[ "$EXO_TEST_DIR" == "/" ]]; then
        echo "FATAL: EXO_TEST_DIR is $EXO_TEST_DIR. Refusing to proceed." >&2
        exit 2
    fi
    case "$EXO_TEST_DIR" in
        *Exo-test*) ;;
        *) echo "FATAL: EXO_TEST_DIR ($EXO_TEST_DIR) does not contain 'Exo-test'. Refusing to proceed." >&2; exit 2 ;;
    esac
}

# init_sandbox — create ~/Exo-test with empty subdirs
init_sandbox() {
    _sandbox_safety_check
    if [[ -d "$EXO_TEST_DIR" ]]; then
        rm -rf "$EXO_TEST_DIR"
    fi
    mkdir -p "$EXO_TEST_DIR"/{people,accounts,decisions,intel,projects,observations,tmp}
    touch "$EXO_TEST_DIR/MEMORY.md"
    touch "$EXO_TEST_DIR/README.md"
    touch "$EXO_TEST_DIR/CLAUDE.md"
    touch "$EXO_TEST_DIR/observations/REVIEW-LOG.md"
}

# cleanup_sandbox — remove ~/Exo-test
cleanup_sandbox() {
    _sandbox_safety_check
    if [[ -d "$EXO_TEST_DIR" ]]; then
        rm -rf "$EXO_TEST_DIR"
    fi
}

# with_sandbox <cmd...> — run a command with sandbox set up, then tear down
with_sandbox() {
    init_sandbox
    trap cleanup_sandbox EXIT
    "$@"
    local rc=$?
    cleanup_sandbox
    trap - EXIT
    return $rc
}

# assert_no_writes_to_real_exo — sanity check at test end. Verifies test did
# NOT touch ~/Exo. (Uses mtime: if ~/Exo exists and any file changed during
# this test run, alert.)
# Note: this is advisory, not strict — the safety check above prevents the
# common error of pointing tests at the real dir.
