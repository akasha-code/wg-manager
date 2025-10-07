# WireGuard Manager (TUI)

**🇺🇸 English | [🇪🇸 Español](README.es.md)**

WireGuard Admin is an interactive TUI helper designed to simplify the day-to-day
management of a self-hosted WireGuard VPN server. It wraps the `wg` tooling with
an `fzf`-powered menu so you can configure the server, add peers and inspect
status without memorising long commands. The project ships with bilingual (EN/ES)
prompts, guided first-run wizards and sane defaults so that you can go from zero
to a usable VPN in minutes.

## Features

- 🚀 **First-run onboarding** – choose between quick defaults, a simple prompt
  flow, or an in-depth guided wizard that explains every setting.
- 📂 **Config management** – automatically populates a `.env` file and stores
  client files under `~/wireguard-files` (customisable).
- 👥 **Peer provisioning** – create client profiles with QR codes and selectable
  routing modes using `create-client.sh` or from the main menu.
- 🔁 **Service helpers** – restart WireGuard, validate configuration and review
  logs from inside the menu.
- 🌐 **Multi-language support** – English and Spanish localisation with automatic
  application restart when changing languages for seamless experience.
- 🚪 **User-friendly interface** – intuitive menu system with clear exit options
  and streamlined installation process.

## Requirements

- A GNU/Linux host with WireGuard already installed and minimally configured.
- `bash`, `wg`, `qrencode`, `fzf` and `wireguard-tools` available in `$PATH`.
- `sudo` rights for actions that touch `/etc/wireguard` or restart services.

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/akasha-code/wg-manager.git
cd wg-manager
```

### 2. Run the installer

The installer automatically detects your distribution, installs required packages,
and prepares a `.env` file with a clean, professional installation experience.

```bash
./install.sh
```

> **💡 Tip**: If you get a "Permission denied" error, make the script executable first:
> ```bash
> chmod +x install.sh
> ./install.sh
> ```
> Alternatively, you can run it directly with: `bash install.sh`

During installation you will:
- Select your preferred language (English/Spanish)
- Choose a first-run setup mode (defaults, simple prompts, or verbose wizard)
- Have the `wg-manager` command automatically registered in your system

The installer provides intelligent fallbacks, attempting system-wide installation
first, then falling back to local user installation if needed.

> **Note**: The script tries to detect your distribution and install packages via
> `apt`, `pacman`, `dnf` or `zypper`. If your distro is not supported you will
> need to install `fzf`, `qrencode` and `wireguard-tools` manually before running
> the script again.

### Manual installation (optional)

If you prefer a manual setup:

1. Copy `.env.example` to `.env` and edit the values to match your server.
2. Ensure the required commands (`wg`, `qrencode`, `fzf`) are available.
3. Export `WG_HOME` to the project directory and run `./wg-manager`.
4. Optionally symlink the script somewhere in your `$PATH` as `wg-manager`.

## Usage

Launch the interface with:

```bash
wg-manager
```

Key operations available from the menu include:

- **Create peers**: generates keys, configuration files and QR codes. You can
  choose between full-tunnel, split-tunnel or custom routing.
- **Edit settings**: open `.env` in your `$EDITOR` to tweak defaults such as DNS
  servers, keepalive or the base network.
- **Change language**: switch between English and Spanish with automatic 
  application restart to apply the new language immediately.
- **Service controls**: restart `wg-quick@<interface>` or validate the current
  WireGuard configuration.
- **Exit application**: clean exit option available directly from the main menu
  (in addition to ESC key support).
- **Wizard rerun**: start the detailed setup wizard at any time with
  `wg-manager --wizard`.

Generated client artefacts are stored under `~/wireguard-files/<peer-name>/` by
default. Each directory contains the client configuration (`.conf`) and a QR
code (`.png`) that can be scanned from mobile devices.

## Recent Improvements

- **Enhanced user experience**: Streamlined installation with reduced debug output
  for a cleaner, more professional setup process.
- **Complete internationalization**: All user-facing messages now support both
  English and Spanish languages.
- **Smart language switching**: Automatic application restart when changing 
  languages with user confirmation to ensure seamless language transitions.
- **Improved navigation**: Added clear exit option to main menu for better
  user experience and discoverability.
- **Automated versioning**: GitHub Actions automatically manage version numbers
  based on commit messages, eliminating manual version management.

## Credits and Support

WireGuard Admin is maintained by Guido Nicolás Quadrini. You can find a
complete acknowledgment of all the people and projects that collaborated in
[CREDITS.md](CREDITS.md).

Is this tool useful to you? Consider buying me a coffee on
[Buy Me a Coffee](https://buymeacoffee.com/matekraft) to support its
continued development.
