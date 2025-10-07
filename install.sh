#!/usr/bin/env bash
set -euo pipefail

echo "🛠 Installing WireGuard Admin (v6.3) / Instalando WireGuard Admin (v6.3)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect distro
if [[ -f /etc/os-release ]]; then . /etc/os-release; DISTRO="$ID"; else DISTRO="unknown"; fi

# Install packages
pkgs=(fzf qrencode wireguard-tools)
echo "📦 Installing required packages / Instalando paquetes requeridos: ${pkgs[*]}"
case "$DISTRO" in
  arch|manjaro) sudo pacman -S --needed "${pkgs[@]}" base-devel --noconfirm ;;
  debian|ubuntu) sudo apt update && sudo apt install -y "${pkgs[@]}" ;;
  fedora) sudo dnf install -y "${pkgs[@]}" ;;
  opensuse*) sudo zypper install -y "${pkgs[@]}" ;;
  *) echo "⚠️  Unknown distro. Please install manually / Distribución desconocida. Instala manualmente: ${pkgs[*]}";;
esac

# Language choice
echo
echo "🌐 Select your language / Selecciona tu idioma:"
echo "  1) English"
echo "  2) Español"
read -rp "Enter choice [1] / Ingresa opción [1]: " lang_choice
lang_choice="${lang_choice:-1}"
WG_LANG="en"; [[ "$lang_choice" == "2" ]] && WG_LANG="es"

# Load language file
LANG_FILE="languages/${WG_LANG}.lang"
if [[ -f "$LANG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$LANG_FILE"
else
  echo "⚠️  Language file not found: $LANG_FILE"
  exit 1
fi

# Prepare env file (create minimal now; wizard will refine)
if [[ ! -f .env ]]; then
  cp .env.example .env
  sed -i "s/^WG_LANG=.*/WG_LANG=\"$WG_LANG\"/" .env
  echo "$INSTALL_ENV_CREATED"
else
  echo "$INSTALL_ENV_EXISTS"
fi

# Install to PATH
INSTALL_DIR="$(pwd)"

# Prepare the executable script with embedded path
cat > "$INSTALL_DIR/wg-manager-executable" <<EOF
#!/usr/bin/env bash
export WG_HOME="$INSTALL_DIR"
exec "$INSTALL_DIR/wg-manager" "\$@"
EOF
chmod +x "$INSTALL_DIR/wg-manager-executable"

# Try to install system-wide first, fallback to user directory
if sudo -v >/dev/null 2>&1; then
  # Ensure /usr/local/bin exists
  sudo mkdir -p /usr/local/bin 2>/dev/null || true
  
  if sudo cp "$INSTALL_DIR/wg-manager-executable" "/usr/local/bin/wg-manager" 2>/dev/null && sudo chmod +x "/usr/local/bin/wg-manager" 2>/dev/null; then
    echo "$INSTALL_CMD_INSTALLED"
  else
    echo "⚠️  Failed to install system-wide, installing locally..."
    mkdir -p "$HOME/.local/bin"
    cp "$INSTALL_DIR/wg-manager-executable" "$HOME/.local/bin/wg-manager"
    chmod +x "$HOME/.local/bin/wg-manager"
    echo "$INSTALL_CMD_LOCAL $HOME/.local/bin/wg-manager"
  fi
else
  # No sudo, install locally
  mkdir -p "$HOME/.local/bin"
  cp "$INSTALL_DIR/wg-manager-executable" "$HOME/.local/bin/wg-manager"
  chmod +x "$HOME/.local/bin/wg-manager"
  echo "$INSTALL_CMD_LOCAL $HOME/.local/bin/wg-manager"
fi

# Clean up temporary file
rm -f "$INSTALL_DIR/wg-manager-executable"

echo
if [[ "${WG_INSTALL_NO_WIZARD:-}" != "1" ]]; then
  echo
  echo "$INSTALL_LAUNCHING"
  WG_HOME="$INSTALL_DIR" ./wg-manager --first-run
  echo
fi
echo "$INSTALL_COMPLETE"
