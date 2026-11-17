# void-dotfiles

> **designed by agu** (`iamagu9o9`)

Automated Void Linux (glibc) bootstrap script and personal dotfiles featuring a custom **Hyprland** + **Quickshell** desktop environment with dynamic `pywal16` / `matugen` theming.

---

## What's Included

| Component | Path / Tool | Details |
| :--- | :--- | :--- |
| **Window Manager** | `config/hypr/` | Hyprland (`hyprland.lua`), `hyprlock`, `hyprpaper`, custom animation curves |
| **Shell & Bar** | `config/quickshell/` | Custom QML bar, dock, app launcher, dashboard, notifications, and AI chat |
| **Terminal & Shell** | `config/kitty/`, `config/fish/` | Kitty terminal with live `wal` color symlinks + Fish shell |
| **Dynamic Theming** | `config/wal/`, `cache/wal/` | `pywal16` templates (`btop`, `rofi`, `waybar`, `gtk`), `genpal.py`, and pre-cached schemes |
| **Music Styling** | `config/spicetify/` | Spicetify Marketplace & custom theme styling |
| **Custom Scripts** | `local-bin/` | `setwall`, `themeall`, `themestyle`, `qsset`, `qsai`, `barpos`, `bartrans`, `dockpin` |

---

## Prerequisites

1. Download the official **Void Linux (`x86_64` glibc)** base live ISO (do **not** use musl if you want binary Hyprland/proprietary compatibility).
2. Complete the base installation via `void-installer` and reboot into TTY.
3. Connect to the internet (`nmtui` or `wpa_supplicant`).

---

## Quick Installation

Run these commands on your fresh Void Linux boot:

```bash
sudo xbps-install -Syu git
git clone [https://github.com/iamagu9o9/void-dotfiles.git](https://github.com/iamagu9o9/void-dotfiles.git) ~/void-dotfiles
cd ~/void-dotfiles
chmod +x install.sh
./install.sh
