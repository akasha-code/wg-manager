#!/usr/bin/env bash
set -euo pipefail

WG_HOME="${WG_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
ENV_FILE="$WG_HOME/.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE" || { echo "❌ Missing .env"; exit 1; }

BASE_DIR="${WG_BASE_DIR:-$WG_HOME/wireguard-files}"
WG_CONF="/etc/wireguard/${WG_INTERFACE:-wg0}.conf"

for cmd in wg qrencode fzf; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ Missing $cmd"; exit 1; }
done

read -rp "Peer name: " DEVNAME
[[ -z "$DEVNAME" ]] && { echo "Cancelled."; exit 1; }

MODE=$(printf "🌍 Full tunnel (all traffic)\n🌐 Split tunnel (internal networks)\n🔧 Custom (manual AllowedIPs)" | \
        fzf --prompt="Routing mode > " --height=10)

case "$MODE" in
  *Full*) ALLOWED_IPS="0.0.0.0/0, ::/0" ;;
  *Split*)
    INTERNALS=$(printf "${WG_BASE_NETWORK}.0/24\n10.10.0.0/16\n192.168.0.0/16" | fzf -m --prompt="Select internal networks > ")
    [[ -z "$INTERNALS" ]] && INTERNALS="${WG_BASE_NETWORK}.0/24"
    ALLOWED_IPS=$(echo "$INTERNALS" | paste -sd, -)
    ;;
  *Custom*)
    read -rp "AllowedIPs (comma separated): " ALLOWED_IPS
    ;;
esac

DNS="${WG_DEFAULT_DNS:-1.1.1.1}"
KEEPALIVE="${WG_DEFAULT_KEEPALIVE:-25}"

CLIENT_DIR="$BASE_DIR/$DEVNAME"; mkdir -p "$CLIENT_DIR"
wg genkey | tee "$CLIENT_DIR/private.key" | wg pubkey > "$CLIENT_DIR/public.key"
chmod 600 "$CLIENT_DIR"/private.key

CLIENT_PRIV=$(<"$CLIENT_DIR/private.key")
CLIENT_PUB=$(<"$CLIENT_DIR/public.key")

# Next free IP
USED_IPS=$(grep -h "Address" "$BASE_DIR"/*/*.conf 2>/dev/null | awk '{print $3}' | cut -d/ -f1 | awk -F. '{print $4}' | sort -n || true)
NEXT_IP=2; for n in $(seq 2 254); do echo "$USED_IPS" | grep -qw "$n" || { NEXT_IP=$n; break; }; done
CLIENT_IP="${WG_BASE_NETWORK}.${NEXT_IP}/32"

# derive server public from server conf (best-effort)
SERVER_PRIV=$(sudo awk '/PrivateKey/ {print $3; exit}' /etc/wireguard/${WG_INTERFACE}.conf 2>/dev/null || echo "")
SERVER_PUB=""; [[ -n "$SERVER_PRIV" ]] && SERVER_PUB=$(printf "%s" "$SERVER_PRIV" | wg pubkey)

CONF_FILE="$CLIENT_DIR/$DEVNAME.conf"
{
  echo "# --- peer $DEVNAME ---"
  echo "[Interface]"
  echo "PrivateKey = $CLIENT_PRIV"
  echo "Address = $CLIENT_IP"
  [[ -n "$DNS" ]] && echo "DNS = $DNS"
  echo
  echo "[Peer]"
  echo "PublicKey = ${SERVER_PUB}"
  echo "AllowedIPs = $ALLOWED_IPS"
  echo "Endpoint = ${WG_SERVER_DOMAIN}:${WG_SERVER_PORT}"
  [[ -n "$KEEPALIVE" ]] && echo "PersistentKeepalive = $KEEPALIVE"
} > "$CONF_FILE"

{
  echo "# --- peer $DEVNAME ---"
  echo "[Peer]"
  echo "PublicKey = $CLIENT_PUB"
  echo "AllowedIPs = ${CLIENT_IP%/*}/32"
  echo
} | sudo tee -a "$WG_CONF" >/dev/null

qrencode -t PNG -o "$CLIENT_DIR/${DEVNAME}.png" < "$CONF_FILE"
qrencode -t ANSIUTF8 < "$CONF_FILE"

echo "✅ Peer '$DEVNAME' created at $CLIENT_DIR"
read -rp "Restart service now? [y/N]: " yn
[[ $yn =~ ^[Yy]$ ]] && sudo systemctl restart "wg-quick@${WG_INTERFACE}"
