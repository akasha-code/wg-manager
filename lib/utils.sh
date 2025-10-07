#!/usr/bin/env bash
# lib/utils.sh - Common utility functions

log() { echo "LOG: $*"; }
ask() { local p="$1"; local d="$2"; read -rp "$p" REPLY; echo "${REPLY:-$d}"; }
pause() { read -rp "${PROMPT_CONTINUE:-Press Enter to continue...}"; }
footer() { echo; echo "Support: $DONATE_URL"; }
restart_wg() { echo "Restarting WireGuard..."; sudo systemctl restart "wg-quick@${WG_INTERFACE:-wg0}"; }
