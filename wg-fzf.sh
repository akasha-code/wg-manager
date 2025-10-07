#!/usr/bin/env bash
set -euo pipefail

# Determine home dir for app
WG_HOME="${WG_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
ENV_FILE="$WG_HOME/.env"
SETUP_FLAG="$WG_HOME/.setup_done"
LANG_DIR="$WG_HOME/languages"
DONATE_URL="https://buymeacoffee.com/matekraft"
CFG_DIR="$HOME/.config/wg-admin"
mkdir -p "$CFG_DIR"
LOG_FILE="$CFG_DIR/setup.log"
log() { printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"; }

# Utilities
ask() { local p="$1"; local d="$2"; read -rp "$p" REPLY; echo "${REPLY:-$d}"; }
valid_ip(){ [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }
private_ip(){ [[ "$1" =~ ^10\. || "$1" =~ ^192\.168\. || "$1" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; }
valid_domain(){ [[ "$1" =~ ^[a-zA-Z0-9.-]+$ && "$1" != *".."* && "$1" != "." ]]; }
detect_if(){ ip link show 2>/dev/null | awk -F': ' '/wg[0-9]/{print $2}' | head -n1; }

# Flows -------------------------------------------------------------------
create_defaults() {
  if [[ -f "$WG_HOME/.env.example" ]]; then
    cp "$WG_HOME/.env.example" "$ENV_FILE"
  else
    cat > "$ENV_FILE" <<EOF
WG_BASE_DIR="$HOME/wireguard-files"
WG_SERVER_DOMAIN="vpn.example.com"
WG_SERVER_PORT=51820
WG_INTERFACE="wg0"
WG_BASE_NETWORK="10.0.0"
WG_DEFAULT_DNS="1.1.1.1"
WG_DEFAULT_KEEPALIVE=25
WG_THEME="dark"
WG_LANG="en"
EOF
  fi
  log "ENV created with defaults"
}

configure_step_by_step() {
  echo "⚙️  Configure each setting (press Enter to keep defaults)"
  local domain port iface base dns ka
  domain=$(ask "🌍 Domain or public IP [vpn.example.com]: " "vpn.example.com")
  port=$(ask "⚙️  UDP port [51820]: " "51820")
  local di; di="$(detect_if)"; [[ -z "$di" ]] && di="wg0"
  iface=$(ask "🧩 Interface [${di}]: " "${di}")
  base=$(ask "🕸️  Base private network (e.g., 10.0.0): " "10.0.0")
  dns=$(ask "📡 DNS for clients [1.1.1.1]: " "1.1.1.1")
  ka=$(ask "🔁 Keepalive seconds [25]: " "25")
  cat > "$ENV_FILE" <<EOF
WG_BASE_DIR="$HOME/wireguard-files"
WG_SERVER_DOMAIN="$domain"
WG_SERVER_PORT=${port:-51820}
WG_INTERFACE="$iface"
WG_BASE_NETWORK="$base"
WG_DEFAULT_DNS="$dns"
WG_DEFAULT_KEEPALIVE=${ka:-25}
WG_THEME="dark"
WG_LANG="${WG_LANG:-en}"
EOF
  log "ENV written via step-by-step"
}

wizard_verbose() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✨ WireGuard Admin — Guided Wizard"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "I'll explain each option and propose safe defaults."
  echo

  # Step 1 - Domain/IP (verbose text, bilingual kept minimal here)
  cat <<'EOT'
🌍 Step 1/6 — Domain or public IP
- If you have a domain: add an A record (vpn.mydomain.com → your public IP).
- No domain? Use free DDNS: https://www.duckdns.org/ or https://www.noip.com/
- Public IP check: https://ifconfig.me / https://whatismyipaddress.com/
- Local-only: use a private IP like 192.168.1.10
EOT
  local domain; domain=$(ask "Enter domain or IP [vpn.example.com]: " "vpn.example.com")
  log "WZ_DOMAIN=$domain"

  echo
  local port; port=$(ask "⚙️  Step 2/6 — UDP port [51820]: " "51820")
  log "WZ_PORT=$port"

  echo
  local di; di="$(detect_if)"; [[ -z "$di" ]] && di="wg0"
  local iface; iface=$(ask "🧩 Step 3/6 — Interface [${di}]: " "${di}")
  log "WZ_IFACE=$iface"

  echo
  local base; base=$(ask "🕸️  Step 4/6 — Base network (e.g., 10.0.0): " "10.0.0")
  log "WZ_BASE=$base"

  echo
  local dns; dns=$(ask "📡 Step 5/6 — DNS for clients [1.1.1.1]: " "1.1.1.1")
  log "WZ_DNS=$dns"

  echo
  local ka; ka=$(ask "🔁 Step 6/6 — Keepalive seconds [25]: " "25")
  log "WZ_KA=$ka"

  cat > "$ENV_FILE" <<EOF
WG_BASE_DIR="$HOME/wireguard-files"
WG_SERVER_DOMAIN="$domain"
WG_SERVER_PORT=${port:-51820}
WG_INTERFACE="$iface"
WG_BASE_NETWORK="$base"
WG_DEFAULT_DNS="$dns"
WG_DEFAULT_KEEPALIVE=${ka:-25}
WG_THEME="dark"
WG_LANG="${WG_LANG:-en}"
EOF
  log "ENV written via verbose wizard"
  echo "✅ Saved configuration to $ENV_FILE"
}

first_run_menu() {
  # Show bilingual explanatory message and options
  echo "───────────────────────────────────────"
  echo "No existing configuration (.env) found."
  echo "You have several options to begin:"
  echo "  1) Accept safe defaults and open the app"
  echo "  2) Configure setting-by-setting (simple prompts)"
  echo "  3) Run the exhaustive guided wizard (educational)"
  echo "  4) Cancel now (you can run later: wg-manager --wizard)"
  read -rp "Choose [1-4]: " choice
  case "${choice:-1}" in
    1) create_defaults ;;
    2) configure_step_by_step ;;
    3) wizard_verbose ;;
    4) echo "Cancelled. Run 'wg-manager --wizard' later."; exit 0 ;;
    *) create_defaults ;;
  esac
  touch "$SETUP_FLAG"
  echo "Setup finished. You can adjust settings later from Settings → Edit (.env)"
}

# Load language (after ENV exists)
load_lang() {
  local lang_file="$LANG_DIR/${WG_LANG:-en}.lang"
  [[ -f "$lang_file" ]] && source "$lang_file" || true
}

# Optional direct wizard
if [[ "${1:-}" == "--wizard" ]]; then
  if [[ ! -f "$ENV_FILE" ]]; then create_defaults; fi
  wizard_verbose
  touch "$SETUP_FLAG"
  exit 0
fi

# First-run orchestrator (used by installer)
if [[ "${1:-}" == "--first-run" ]]; then
  if [[ ! -f "$ENV_FILE" ]]; then
    first_run_menu
  else
    echo "Found existing .env; skipping first-run menu."
  fi
  exit 0
fi

# Normal startup
if [[ ! -f "$ENV_FILE" ]]; then
  # Called outside installer; show menu
  first_run_menu
fi

source "$ENV_FILE"
load_lang

# Deps
for cmd in wg qrencode fzf; do command -v "$cmd" >/dev/null 2>&1 || { echo "❌ Missing $cmd"; exit 1; }; done

# Paths
BASE_DIR="${WG_BASE_DIR:-$WG_HOME/wireguard-files}"
WG_CONF="/etc/wireguard/${WG_INTERFACE:-wg0}.conf"
EDITOR="${EDITOR:-nano}"

pause() { read -rp "${PROMPT_CONTINUE:-Press Enter to continue...}"; }
footer() {
  local cols=$(tput cols 2>/dev/null || echo 80)
  local msg="☕ ${DONATE_PREFIX:-Support development}: ${DONATE_URL}"
  printf "\n\033[2;37m%*s\033[0m\n" $(((${#msg} + cols)/2)) "$msg"
}

restart_wg() {
  echo "${RESTARTING:-Restarting WireGuard...}"
  sudo systemctl restart "wg-quick@${WG_INTERFACE}" && echo "${RESTARTED_OK:-Service restarted.}"
  pause
}

list_peers() { find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort; }

validate_config() {
  if command -v wg-quick >/dev/null 2>&1; then
    if sudo wg-quick strip "${WG_INTERFACE}" >/dev/null 2>&1; then
      echo "${VALID_CONFIG_OK}"
    else
      echo "${VALID_CONFIG_FAIL}"
    fi
  else
    echo "wg-quick not found."
  fi
  pause
}

backup_all() {
  mkdir -p "$WG_HOME/backups"
  local ts=$(date +%Y%m%d-%H%M%S)
  local out="$WG_HOME/backups/wg-backup-$ts.tar.gz"
  sudo tar -czf "$out" /etc/wireguard "$BASE_DIR"
  echo "${BACKUP_DONE}: $out"
  pause
}

export_peer() {
  local peer="$1"
  local out="$WG_HOME/backups/${peer}-export-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$out" -C "$BASE_DIR" "$peer"
  echo "${EXPORT_DONE}: $out"
  pause
}

view_peer() { clear; sudo less "$BASE_DIR/$1/$1.conf"; footer; }
edit_peer() { sudo "$EDITOR" "$BASE_DIR/$1/$1.conf"; validate_config; restart_wg; }
qr_peer() { clear; qrencode -t ANSIUTF8 < "$BASE_DIR/$1/$1.conf"; echo; footer; pause; }
delete_peer() {
  local peer="$1"
  read -rp "${CONFIRM_DELETE:-Delete} '$peer'? [y/N]: " yn
  [[ $yn =~ ^[Yy]$ ]] || return
  sudo sed -i "/# --- peer $peer ---/,+3d" "$WG_CONF"
  sudo rm -rf "$BASE_DIR/$peer"
  restart_wg
}
rename_peer() {
  local old="$1"; read -rp "New name for '$old': " new; [[ -z "$new" ]] && { echo "Cancelled."; pause; return; }
  [[ -d "$BASE_DIR/$new" ]] && { echo "Name exists."; pause; return; }
  sudo mv "$BASE_DIR/$old" "$BASE_DIR/$new"
  sudo mv "$BASE_DIR/$new/$old.conf" "$BASE_DIR/$new/$new.conf"
  sudo sed -i "s/# --- peer $old ---/# --- peer $new ---/" "$WG_CONF"
  restart_wg
}

peer_menu_loop() {
  local peer="$1"
  while true; do
    clear
    action=$(printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
             "${PEER_VIEW:-View}" "${PEER_EDIT:-Edit}" "${PEER_QR:-QR}" "${PEER_RENAME:-Rename}" "${PEER_DELETE:-Delete}" \
             "${PEER_MAIN_MENU:-🏠 Main Menu}" "${BACK:-Back}" | \
             fzf --height=16 --reverse --prompt="${PROMPT_PEER_MENU:-$peer > }")
    case "$action" in
      *View*) view_peer "$peer" ; pause ;;
      *Edit*) edit_peer "$peer" ; pause ;;
      *QR*) qr_peer "$peer" ; pause ;;
      *Rename*|*Renombrar*) 
        new_peer=$(rename_peer "$peer")
        if [[ -n "$new_peer" && "$new_peer" != "$peer" ]]; then
          peer="$new_peer"
        fi
        pause
        ;;
      *Delete*|*Eliminar*) 
        if delete_peer "$peer"; then
          echo "Peer deleted. Returning to main menu..."
          sleep 2
          return 0
        fi
        pause
        ;;
      *Main*|*Principal*) return 0 ;;
      *Back*|*Atrás*) return 0 ;;
      *) return 0 ;;
    esac
  done
}

peer_more() {
  local peer="$1"
  action=$(printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
           "${PEER_VIEW:-View}" "${PEER_EDIT:-Edit}" "${PEER_QR:-QR}" "${PEER_RENAME:-Rename}" "${PEER_DELETE:-Delete}" "${BACK:-Back}" | \
           fzf --height=14 --reverse --prompt="${PROMPT_ACTION:-Action > }")
  case "$action" in
    *View*) view_peer "$peer" ;;
    *Edit*) edit_peer "$peer" ;;
    *QR*) qr_peer "$peer" ;;
    *Rename*|*Renombrar*) rename_peer "$peer" ;;
    *Delete*|*Eliminar*) delete_peer "$peer" ;;
  esac
}

view_general() {
  clear
  action=$(printf "%s\n%s\n%s\n%s\n" \
           "${GENERAL_VIEW_RO:-View (RO)}" "${GENERAL_EDIT:-Edit}" "${GENERAL_EDIT_RESTART:-Edit+Restart}" "${BACK:-Back}" | \
           fzf --height=12 --reverse --prompt="${PROMPT_ACTION:-Action > }")
  case "$action" in
    *View*) sudo less "$WG_CONF" ;;
    *Edit*) sudo "$EDITOR" "$WG_CONF" ;;
    *Restart*|*reiniciar*) sudo "$EDITOR" "$WG_CONF"; validate_config; restart_wg ;;
  esac
}

settings_menu() {
  action=$(printf "%s\n%s\n%s\n" \
           "${SETTINGS_EDIT_ENV:-Edit .env}" "${SETTINGS_CHANGE_LANGUAGE:-Change language}" "${SETTINGS_RESTORE_ENV:-Restore defaults}" | \
           fzf --height=12 --reverse --prompt="${PROMPT_ACTION:-Action > }")
  case "$action" in
    *Edit*) "$EDITOR" "$ENV_FILE" ;;
    *Change*|*Cambiar*)
        sel=$(printf "en\nes" | fzf --height=6 --reverse --prompt="Language / Idioma > ")
        [[ -n "$sel" ]] && (grep -q '^WG_LANG=' "$ENV_FILE" && sed -i "s/^WG_LANG=.*/WG_LANG=\"$sel\"/" "$ENV_FILE" || echo "WG_LANG=\"$sel\"" >> "$ENV_FILE")
        ;;
    *Restore*|*Restaurar*) cp "$WG_HOME/.env.example" "$ENV_FILE";;
  esac
}

show_status() {
  clear
  echo "${STATUS_HEADER:-VPN Status}"
  sudo wg show | awk '
    /^interface:/ {iface=$2}
    /^peer:/ {p=$2}
    /allowed ips:/ {ip=$3}
    /latest handshake:/ {h=$3" "$4" "$5" "$6}
    /transfer:/ {tx=$2; rx=$5; printf("• %s | %-18s | %-16s | TX:%-8s RX:%-8s\n", p, ip, h, tx, rx)}
  '
  footer; pause
}

tools_menu() {
  action=$(printf "💾 Backup (all)\n📦 Export selected peer\n🧪 Validate config\n⬅️ Back" | \
           fzf --height=12 --reverse --prompt="${PROMPT_ACTION:-Action > }")
  case "$action" in
    "💾 Backup (all)") backup_all ;;
    "📦 Export selected peer")
        peer=$(list_peers | fzf --height=20 --reverse --prompt="${PROMPT_SELECT_PEER:-Select peer > }")
        [[ -n "$peer" ]] && export_peer "$peer"
        ;;
    "🧪 Validate config") validate_config ;;
  esac
}

# CLI subcommands
if [[ $# -gt 0 ]]; then
  case "$1" in
    list) list_peers ; exit 0 ;;
    status) show_status ; exit 0 ;;
    add) shift; sudo "$WG_HOME/create-client.sh" "$@" ; exit 0 ;;
    --wizard) wizard_verbose; touch "$SETUP_FLAG"; exit 0 ;;
    --first-run) first_run_menu; exit 0 ;;
    --peer-menu) 
      shift
      if [[ $# -gt 0 ]]; then
        peer_menu_loop "$1"
        exit 0
      else
        echo "❌ Peer name required for --peer-menu"
        exit 1
      fi
      ;;
  esac
fi

# Main menu
while true; do
  clear
  choice=$(printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
           "${MENU_VIEW_PEERS:-View peers}" "${MENU_CREATE_NEW:-Create new}" "${MENU_GENERAL_CONFIG:-General config}" "🧰 Tools" \
           "${MENU_SETTINGS:-Settings}" "${MENU_RESTART_SERVICE:-Restart service}" "${MENU_STATUS:-VPN Status}" "${MENU_CREDITS:-Credits}" | \
           fzf --height=20 --reverse --prompt="${PROMPT_MANAGER:-WireGuard Manager > }")
  case "$choice" in
    *View*|*Ver*) peers=$(list_peers); [[ -z "$peers" ]] && { echo "${NO_PEERS:-No peers}"; footer; pause; continue; }; peer=$(echo "$peers" | fzf --height=20 --reverse --prompt="${PROMPT_SELECT_PEER:-Select peer > }"); [[ -n "$peer" ]] && peer_more "$peer" ;;
    *Create*|*Crear*) sudo "$WG_HOME/create-client.sh" ;;
    *General*) view_general ;;
    "🧰 Tools") tools_menu ;;
    *Settings*|*Configuración*) settings_menu ;;
    *Restart*|*Reiniciar*) restart_wg ;;
    *Status*|*Estado*) show_status ;;
    *Credits*|*Créditos*)
      clear
      if [[ -f "$WG_HOME/CREDITS.md" ]]; then
        if command -v glow >/dev/null 2>&1; then glow "$WG_HOME/CREDITS.md"; else cat "$WG_HOME/CREDITS.md"; fi
      else
        echo "Credits file missing."
      fi
      footer; pause
      ;;
    *) clear; exit 0 ;;
  esac
done
