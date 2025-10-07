#!/usr/bin/env bash
set -euo pipefail

# Simulate a real user installing and launching the app.

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR="$ROOT_DIR/tests/tmp_sim_user"
MOCKS_DIR="$ROOT_DIR/tests/mocks"

cleanup() {
  if [[ "${KEEP_ARTIFACTS:-0}" != "1" ]]; then
    rm -rf "$TMP_DIR" || true
  else
    echo "KEEP_ARTIFACTS=1 set; preserving $TMP_DIR" >&2
  fi
}
trap cleanup EXIT

mkdir -p "$TMP_DIR"

export HOME="$TMP_DIR/home"
mkdir -p "$HOME/.local/bin"

# Put mocks first in PATH so we don't require real sudo/wg/qrencode/fzf/pkg managers
export PATH="$MOCKS_DIR:$PATH"
export FAKE_ROOT="$TMP_DIR"

echo "-- Fixing script line endings for bash (Windows host scenario)"
bash "$ROOT_DIR/docker-test/fix-scripts.sh" >/dev/null 2>&1 || true

echo "-- Running install.sh (choose English, then accept defaults in first-run)"
pushd "$ROOT_DIR" >/dev/null
set +e
printf "1\n1\n" | bash ./install.sh >"$TMP_DIR/install.out" 2>"$TMP_DIR/install.err"
rc=$?
set -e
popd >/dev/null

if [[ $rc -ne 0 ]]; then
  echo "Install exited with code $rc" >&2
  echo "--- install.out ---"; sed -n '1,120p' "$TMP_DIR/install.out" || true
  echo "--- install.err ---"; sed -n '1,120p' "$TMP_DIR/install.err" || true
  exit $rc
fi

[[ -f "$ROOT_DIR/.env" ]] || { echo "Missing .env after install"; exit 1; }
[[ -x "$HOME/.local/bin/wg-manager" ]] || { echo "Missing wg-manager wrapper in ~/.local/bin"; exit 1; }

echo "-- Launching wg-manager (sanity run)"
set +e
"$HOME/.local/bin/wg-manager" --first-run >"$TMP_DIR/launch.out" 2>"$TMP_DIR/launch.err"
rc2=$?
set -e

if [[ $rc2 -ne 0 ]]; then
  echo "wg-manager launch exit code: $rc2" >&2
  echo "--- launch.out ---"; sed -n '1,120p' "$TMP_DIR/launch.out" || true
  echo "--- launch.err ---"; sed -n '1,120p' "$TMP_DIR/launch.err" || true
  exit $rc2
fi

echo "Simulation completed successfully."
echo "- HOME used: $HOME"
echo "- Wrapper: $HOME/.local/bin/wg-manager"
echo "- Env file: $ROOT_DIR/.env"

