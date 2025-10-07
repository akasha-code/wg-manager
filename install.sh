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
  arch|manjaro) 
    sudo pacman -S --needed "${pkgs[@]}" base-devel --noconfirm
    # Ensure WireGuard kernel module is loaded on Arch
    if ! lsmod | grep -q wireguard; then
      echo "🔧 Loading WireGuard kernel module..."
      sudo modprobe wireguard 2>/dev/null || echo "⚠️  Could not load WireGuard module - may need manual setup"
    fi
    ;;
  debian|ubuntu) sudo apt update && sudo apt install -y "${pkgs[@]}" ;;
  fedora) sudo dnf install -y "${pkgs[@]}" ;;
  opensuse*) sudo zypper install -y "${pkgs[@]}" ;;
  *) echo "⚠️  Unknown distro. Please install manually / Distribución desconocida. Instala manualmente: ${pkgs[*]}";;
esac

# Give time for PATH to update after package installation
sleep 2

# Verify critical packages are available
echo "🔍 Verifying package installation..."
missing_pkgs=()
for cmd in fzf qrencode wg; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing_pkgs+=("$cmd")
  fi
done

if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
  echo "⚠️  Some packages may not be properly installed: ${missing_pkgs[*]}"
  echo "   You may need to install them manually or update your PATH"
fi

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
echo "🔧 Creating executable wrapper..."
cat > "$INSTALL_DIR/wg-manager-executable" <<EOF
#!/usr/bin/env bash
export WG_HOME="$INSTALL_DIR"
exec "$INSTALL_DIR/wg-manager" "\$@"
EOF

# Verify the file was created
if [[ ! -f "$INSTALL_DIR/wg-manager-executable" ]]; then
  echo "❌ Failed to create wg-manager-executable wrapper"
  echo "   Check write permissions in: $INSTALL_DIR"
  exit 1
fi

chmod +x "$INSTALL_DIR/wg-manager-executable"

# Verify permissions were set
if [[ ! -x "$INSTALL_DIR/wg-manager-executable" ]]; then
  echo "❌ Failed to set execute permissions on wrapper"
  exit 1
fi

echo "✅ Wrapper created successfully"

# Additional Arch Linux debugging
if [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
  echo "🔍 Arch Linux specific checks:"
  echo "   - Checking if /usr is mounted read-only..."
  mount | grep -E "^[^ ]+ on /usr " | grep -q "ro," && echo "   ⚠️  /usr is mounted read-only!" || echo "   ✅ /usr is writable"
  
  echo "   - Checking filesystem type..."
  stat -f -c "%T" /usr/local 2>/dev/null || echo "   ⚠️  Cannot determine filesystem type"
  
  echo "   - Checking available space..."
  df -h /usr/local 2>/dev/null | tail -1 || echo "   ⚠️  Cannot check disk space"
fi

# Try to install system-wide first, fallback to user directory
if sudo -v >/dev/null 2>&1; then
  echo "🔧 Attempting system-wide installation..."
  echo "   Checking /usr/local/bin directory..."
  
  # Debug: Check if /usr/local/bin exists and permissions
  if [[ -d "/usr/local/bin" ]]; then
    echo "   ✅ /usr/local/bin exists"
    ls -ld /usr/local/bin || echo "   ⚠️  Cannot list /usr/local/bin"
  else
    echo "   📁 /usr/local/bin does not exist, creating..."
  fi
  
  # Create directory with detailed error checking
  if sudo mkdir -p /usr/local/bin 2>&1; then
    echo "   ✅ Directory created/confirmed"
  else
    echo "   ❌ Failed to create /usr/local/bin"
  fi
  
  # Check filesystem info
  echo "   � Filesystem info for /usr/local/bin:"
  df -h /usr/local/bin 2>/dev/null || echo "   ⚠️  Cannot get filesystem info"
  
  # Test write permissions first
  echo "   🧪 Testing write permissions..."
  if sudo touch /usr/local/bin/.test-write 2>/dev/null && sudo rm -f /usr/local/bin/.test-write 2>/dev/null; then
    echo "   ✅ Write permissions OK"
    
    # Now try the actual copy with detailed error output
    echo "   📋 Copying file and setting permissions..."
    # Refresh sudo credentials and do both operations in one sudo call
    if sudo -v 2>/dev/null; then
      # Combine copy and chmod in single sudo operation to avoid timeout issues
      if sudo bash -c "cp '$INSTALL_DIR/wg-manager-executable' '/usr/local/bin/wg-manager' && chmod +x '/usr/local/bin/wg-manager'" 2>/dev/null; then
        echo "   ✅ Copy and permissions successful"
        echo "$INSTALL_CMD_INSTALLED"
      else
        echo "   ❌ Copy or chmod failed"
        echo "   🔄 Falling back to local installation..."
        sudo rm -f "/usr/local/bin/wg-manager" 2>/dev/null
        mkdir -p "$HOME/.local/bin"
        cp "$INSTALL_DIR/wg-manager-executable" "$HOME/.local/bin/wg-manager"
        chmod +x "$HOME/.local/bin/wg-manager"
        echo "$INSTALL_CMD_LOCAL $HOME/.local/bin/wg-manager"
      fi
    else
      echo "   ❌ sudo credentials expired, installing locally instead..."
      mkdir -p "$HOME/.local/bin"
      cp "$INSTALL_DIR/wg-manager-executable" "$HOME/.local/bin/wg-manager"
      chmod +x "$HOME/.local/bin/wg-manager"
      echo "$INSTALL_CMD_LOCAL $HOME/.local/bin/wg-manager"
    fi
  else
    echo "   ❌ No write permissions to /usr/local/bin"
    echo "   🔄 Installing locally instead..."
    mkdir -p "$HOME/.local/bin"
    cp "$INSTALL_DIR/wg-manager-executable" "$HOME/.local/bin/wg-manager"
    chmod +x "$HOME/.local/bin/wg-manager"
    echo "$INSTALL_CMD_LOCAL $HOME/.local/bin/wg-manager"
  fi
else
  # No sudo, install locally
  echo "🔧 No sudo available, installing locally..."
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
  echo "🔧 Debug: About to run first-run setup..."
  echo "   WG_HOME=$INSTALL_DIR"
  echo "   Command: bash ./wg-manager --first-run"
  
  # Ensure wg-manager has execute permissions
  chmod +x ./wg-manager
  
  echo
  if WG_HOME="$INSTALL_DIR" bash ./wg-manager --first-run; then
    echo "✅ First-run setup completed successfully"
  else
    exit_code=$?
    echo "⚠️  First-run setup had issues (exit code: $exit_code)"
    echo "   Installation completed, but first-run configuration needs to be done manually"
    echo "   To complete setup, run: wg-manager --first-run"
    echo "   Or if that doesn't work: cd '$INSTALL_DIR' && bash ./wg-manager --first-run"
  fi
  echo
fi
echo "$INSTALL_COMPLETE"
