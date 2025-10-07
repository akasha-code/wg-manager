#!/usr/bin/env bash
set -euo pipefail

echo "🛠 Installing WireGuard Admin (v6.3)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect distro
if [[ -f /etc/os-release ]]; then . /etc/os-release; DISTRO="$ID"; else DISTRO="unknown"; fi

# Install packages
pkgs=(fzf qrencode wireguard-tools)
echo "📦 Installing required packages: ${pkgs[*]}"
case "$DISTRO" in
  arch|manjaro) sudo pacman -S --needed "${pkgs[@]}" base-devel --noconfirm ;;
  debian|ubuntu) sudo apt update && sudo apt install -y "${pkgs[@]}" ;;
  fedora) sudo dnf install -y "${pkgs[@]}" ;;
  opensuse*) sudo zypper install -y "${pkgs[@]}" ;;
  *) echo "⚠️  Unknown distro. Please install manually: ${pkgs[*]}";;
esac

# Language choice
echo
echo "🌐 Select your language / Selecciona tu idioma:"
echo "  1) English"
echo "  2) Español"
read -rp "Enter choice [1]: " lang_choice
lang_choice="${lang_choice:-1}"
WG_LANG="en"; [[ "$lang_choice" == "2" ]] && WG_LANG="es"

# Prepare env file (create minimal now; wizard will refine)
if [[ ! -f .env ]]; then
  cp .env.example .env
  sed -i "s/^WG_LANG=.*/WG_LANG=\"$WG_LANG\"/" .env
  echo "✅ Created base .env"
else
  echo "ℹ️  Existing .env found, keeping it"
fi

# Install wrapper to /usr/local/bin
INSTALL_DIR="$(pwd)"
WRAPPER="/usr/local/bin/wg-manager"
WRAP_CONTENT="#!/usr/bin/env bash
export WG_HOME=\"${INSTALL_DIR}\"
exec \"${INSTALL_DIR}/wg-fzf.sh\" \"\$@\"
"
if sudo -v >/dev/null 2>&1; then
  echo "$WRAP_CONTENT" | sudo tee "$WRAPPER" >/dev/null
  sudo chmod +x "$WRAPPER"
  echo "✅ Installed command: wg-manager"
else
  mkdir -p "$HOME/.local/bin"
  WRAPPER="$HOME/.local/bin/wg-manager"
  echo "$WRAP_CONTENT" > "$WRAPPER"
  chmod +x "$WRAPPER"
  echo "✅ Installed local command: $WRAPPER"
fi

echo
echo "🎩 Launching first-time options..."
WG_HOME="$INSTALL_DIR" ./wg-fzf.sh --first-run
echo
echo "🎉 Installation complete. Run 'wg-manager' anytime."
