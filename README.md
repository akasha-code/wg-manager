# WireGuard Admin v6.3

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
- 🌐 **Multi-language support** – English and Spanish localisation strings are
  bundled, with the language selected during installation.

## Requirements

- A GNU/Linux host with WireGuard already installed and minimally configured.
- `bash`, `wg`, `qrencode`, `fzf` and `wireguard-tools` available in `$PATH`.
- `sudo` rights for actions that touch `/etc/wireguard` or restart services.

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/<your-user>/wg-manager.git
cd wg-manager
```

### 2. Run the installer

The installer installs the few userland dependencies, prepares a `.env` file and
registers a `wg-manager` command that launches the TUI.

```bash
./install.sh
```

During the process you will be prompted to pick your preferred language and a
first-run mode (defaults, simple prompts or the verbose wizard).

> **Note**: The script tries to detect your distribution and install packages via
> `apt`, `pacman`, `dnf` or `zypper`. If your distro is not supported you will
> need to install `fzf`, `qrencode` and `wireguard-tools` manually before running
> the script again.

### Manual installation (optional)

If you prefer a manual setup:

1. Copy `.env.example` to `.env` and edit the values to match your server.
2. Ensure the required commands (`wg`, `qrencode`, `fzf`) are available.
3. Export `WG_HOME` to the project directory and run `./wg-fzf.sh`.
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
- **Service controls**: restart `wg-quick@<interface>` or validate the current
  WireGuard configuration.
- **Wizard rerun**: start the detailed setup wizard at any time with
  `wg-manager --wizard`.

Generated client artefacts are stored under `~/wireguard-files/<peer-name>/` by
default. Each directory contains the client configuration (`.conf`) and a QR
code (`.png`) that can be scanned from mobile devices.

## Credits

This project is maintained by Guido Nicolás Quadrini. See [CREDITS.md](CREDITS.md)
for full acknowledgements.
