#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_TMP="$ROOT_DIR/tests/tmp_install"
MOCKS_DIR="$ROOT_DIR/tests/mocks"
SCRIPT="$ROOT_DIR/install.sh"
SCRIPT_CLEAN="$TEST_TMP/install.sh"

cleanup() {
  if [[ "${KEEP_ARTIFACTS:-0}" != "1" ]]; then
    rm -rf "$TEST_TMP" || true
  else
    echo "KEEP_ARTIFACTS=1 set; preserving $TEST_TMP" >&2
  fi
}
trap cleanup EXIT

mkdir -p "$TEST_TMP"

# Normalize CRLF to LF
awk '{ sub(/\r$/,"" ); print }' "$SCRIPT" > "$SCRIPT_CLEAN"
chmod +x "$SCRIPT_CLEAN"

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

case_name="install script creates env and wrapper (local bin)"

# Set up isolated HOME and PATH with mocks
export HOME="$TEST_TMP/home"
mkdir -p "$HOME/.local/bin"
export PATH="$MOCKS_DIR:$PATH"
export FAKE_ROOT="$TEST_TMP"

# Ensure package manager mocks are executable
chmod +x "$MOCKS_DIR"/* 2>/dev/null || true

# Run install: choose English (1), skip wizard via env var
set +e
printf "1\n" | WG_INSTALL_NO_WIZARD=1 bash "$SCRIPT_CLEAN" >"$TEST_TMP/out.txt" 2>"$TEST_TMP/err.txt"
rc=$?
set -e
[[ $rc -eq 0 ]] || fail "$case_name (exit=$rc)"

# Assertions
[[ -f "$ROOT_DIR/.env" ]] || fail "$case_name (.env not created)"
grep -q '^WG_LANG="en"' "$ROOT_DIR/.env" || fail "$case_name (WG_LANG not set)"

WRAPPER="$HOME/.local/bin/wg-manager"
[[ -f "$WRAPPER" ]] || fail "$case_name (wrapper not created)"
[[ -x "$WRAPPER" ]] || fail "$case_name (wrapper not executable)"
grep -q "WG_HOME=\"$ROOT_DIR\"" "$WRAPPER" || fail "$case_name (wrapper WG_HOME path)"
grep -q "wg-fzf.sh" "$WRAPPER" || fail "$case_name (wrapper points to wg-fzf.sh)"

pass "$case_name"
echo "All install tests passed."

