#!/usr/bin/env bash
# lib/peers.sh - Peer management functions

list_peers() { find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort; }
view_peer() { clear; sudo less "$BASE_DIR/$1/$1.conf"; footer; }
qr_peer() { clear; qrencode -t ANSIUTF8 < "$BASE_DIR/$1/$1.conf"; echo; footer; pause; }
