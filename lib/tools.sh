#!/usr/bin/env bash
show_status() { echo "VPN Status"; sudo wg show 2>/dev/null || echo "No active connections"; }
