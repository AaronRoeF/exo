#!/usr/bin/env bash
#
# cleanup.sh — Tear down test sandbox. Safe to run anytime.

set -uo pipefail
source "$(dirname "$0")/lib/sandbox.sh"
cleanup_sandbox
echo "Cleaned up $EXO_TEST_DIR"
