#!/usr/bin/env bash
set -euo pipefail

# Minimal test harness for create-client.sh

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_TMP="$ROOT_DIR/tests/tmp"
MOCKS_DIR="$ROOT_DIR/tests/mocks"
SCRIPT="$ROOT_DIR/create-client.sh"
SCRIPT_CLEAN="$TEST_TMP/create-client.sh"

cleanup() {
  if [[ "${KEEP_ARTIFACTS:-0}" != "1" ]]; then
    rm -rf "$TEST_TMP" || true
  else
    echo "KEEP_ARTIFACTS=1 set; preserving $TEST_TMP" >&2
  fi
}
trap cleanup EXIT

mkdir -p "$TEST_TMP" "$MOCKS_DIR"

# Normalize potential CRLF in the script into LF for bash
awk '{ sub(/\r$/,"" ); print }' "$SCRIPT" > "$SCRIPT_CLEAN"
chmod +x "$SCRIPT_CLEAN"

# Ensure mocks are executable
chmod +x "$MOCKS_DIR"/* 2>/dev/null || true

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

run_basic_full_tunnel_test() {
  local case_name="basic full-tunnel creates client and appends peer"
  local WG_HOME="$TEST_TMP/wghome"
  local BASE_DIR="$WG_HOME/wireguard-files"
  local ETC_REDIRECT="$TEST_TMP"
  local WG_INTERFACE="wgtest"
  local CLIENT="alice"

  mkdir -p "$WG_HOME" "$BASE_DIR" "$ETC_REDIRECT"

  cat >"$WG_HOME/.env" <<EOF
WG_BASE_DIR="$BASE_DIR"
WG_INTERFACE="$WG_INTERFACE"
WG_BASE_NETWORK="10.20.30"
WG_DEFAULT_DNS="9.9.9.9"
WG_DEFAULT_KEEPALIVE="21"
WG_SERVER_DOMAIN="test.example.com"
WG_SERVER_PORT="51820"
EOF

  # Mocks setup
  export FAKE_ROOT="$ETC_REDIRECT"
  export PATH="$MOCKS_DIR:$PATH"

  # Non-interactive answers: name, then decline restart
  # Mock fzf will return "Full"
  set +e
  printf "%s\n%s\n" "$CLIENT" "y" | WG_HOME="$WG_HOME" bash "$SCRIPT_CLEAN"
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    fail "$case_name (script exit=$rc)"
  fi

  # Assert client files
  [[ -f "$BASE_DIR/$CLIENT/private.key" ]] || fail "$case_name (missing private.key)"
  [[ -f "$BASE_DIR/$CLIENT/public.key" ]] || fail "$case_name (missing public.key)"
  [[ -f "$BASE_DIR/$CLIENT/$CLIENT.conf" ]] || fail "$case_name (missing client conf)"
  [[ -f "$BASE_DIR/$CLIENT/$CLIENT.png" ]] || fail "$case_name (missing client png)"

  # Assert client conf contents
  addr=$(grep -E '^Address = ' "$BASE_DIR/$CLIENT/$CLIENT.conf" | awk '{print $3}')
  [[ "$addr" =~ ^10\.20\.30\.[0-9]+/32$ ]] || fail "$case_name (client IP)"
  grep -q "AllowedIPs = 0.0.0.0/0, ::/0" "$BASE_DIR/$CLIENT/$CLIENT.conf" || fail "$case_name (client AllowedIPs full)"
  grep -q "Endpoint = test.example.com:51820" "$BASE_DIR/$CLIENT/$CLIENT.conf" || fail "$case_name (endpoint)"
  grep -q "DNS = 9.9.9.9" "$BASE_DIR/$CLIENT/$CLIENT.conf" || fail "$case_name (dns)"
  grep -q "PersistentKeepalive = 21" "$BASE_DIR/$CLIENT/$CLIENT.conf" || fail "$case_name (keepalive)"

  # Assert server conf append (redirected to fake root)
  [[ -f "$ETC_REDIRECT/etc/wireguard/wgtest.conf" ]] || fail "$case_name (server conf append)"
  grep -q "\[Peer\]" "$ETC_REDIRECT/etc/wireguard/wgtest.conf" || fail "$case_name (server peer block)"
  addr_base="${addr%/*}"
  grep -q "AllowedIPs = ${addr_base}/32" "$ETC_REDIRECT/etc/wireguard/wgtest.conf" || fail "$case_name (server allowed IPs)"

  pass "$case_name"
}

run_basic_full_tunnel_test

echo "All tests passed."
