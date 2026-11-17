#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}==> Starting Void Linux Automated Setup (designed by agu)...${NC}"

# 1. System Update & Official Repos
echo -e "${GREEN}==> Updating system and enabling void-repo-nonfree...${NC}"
sudo xbps-install -Syu xbps
sudo xbps-install -Sy void-repo-nonfree
sudo xbps-install -Syu

# 2. Add Community Hyprland Repository (Makrennel)
echo -e "${GREEN}==> Adding Hyprland repository for Void (x86_64-glibc)...${NC}"
echo "repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc" | sudo tee /etc/xbps.d/hyprland-void.conf > /dev/null
sudo xbps-install -S

# 3. Core System, Audio, Wayland & CLI Packages
echo -e "${GREEN}==> Installing core packages, Hyprland, Kitty, and Fish...${NC}"
PACKAGES=(
    git curl wget unzip base-devel cmake ninja pkg-config
    seatd dbus elogind polkit-kde-agent mesa-dri
    hyprland xdg-desktop-portal-hyprland hyprpaper hypridle hyprlock
    wl-clipboard grim slurp swaybg swww brightnessctl playerctl
    kitty fish-shell fastfetch btop neovim yazi
    pipewire wireplumber pulseaudio-utils pamixer
    noto-fonts-ttf noto-fonts-emoji font-awesome6 papirus-icon-theme
    python3-pipx ImageMagick
    qt6-base-devel qt6-declarative-devel qt6-wayland-devel qt6-svg-devel
    qt6-shadertools-devel cli11 jemalloc-devel libdrm-devel wayland-devel
    wayland-protocols
)

sudo xbps-install -Sy "${PACKAGES[@]}"

# 4. Install Color Generators (pywal16 & matugen)
echo -e "${GREEN}==> Installing pywal16 and matugen...${NC}"
pipx install pywal16 || true
if ! command -v matugen &> /dev/null; then
    curl -sL https://github.com/InioX/matugen/releases/latest/download/matugen-x86_64-unknown-linux-gnu.tar.gz | sudo tar -xz -C /usr/local/bin/
fi

# 5. Build & Install Quickshell via xbps-src
echo -e "${GREEN}==> Setting up Quickshell...${NC}"
if ! command -v quickshell &> /dev/null; then
    echo -e "${YELLOW}Cloning void-packages to build Quickshell...${NC}"
    mkdir -p "$HOME/.local/src"
    if [ ! -d "$HOME/.local/src/void-packages" ]; then
        git clone --depth 1 https://github.com/void-linux/void-packages.git "$HOME/.local/src/void-packages"
        "$HOME/.local/src/void-packages/xbps-src" binary-bootstrap
    fi
    if [ ! -d "$HOME/.local/src/void-packages/srcpkgs/quickshell" ]; then
        git clone --depth 1 https://github.com/ItsLemmy/void-packages.git /tmp/lemmy-void
        cp -r /tmp/lemmy-void/srcpkgs/quickshell "$HOME/.local/src/void-packages/srcpkgs/"
        rm -rf /tmp/lemmy-void
    fi
    cd "$HOME/.local/src/void-packages"
    ./xbps-src pkg quickshell
    sudo xbps-install -Sy --repository=hostdir/binpkgs quickshell
    cd "$REPO_DIR"
fi

# 6. Enable Runit Services
echo -e "${GREEN}==> Enabling runit services (dbus, seatd, polkitd)...${NC}"
sudo ln -sf /etc/sv/dbus /var/service/
sudo ln -sf /etc/sv/seatd /var/service/
sudo ln -sf /etc/sv/polkitd /var/service/
sudo usermod -aG _seatd,video,audio,input "$USER"

# 7. Symlink Configs, Cache Colors, Scripts & Wallpapers
echo -e "${GREEN}==> Linking configs, .cache colors, scripts, and wallpapers...${NC}"
mkdir -p "$HOME/.config" "$HOME/.cache" "$HOME/.local/bin" "$HOME/Pictures/Wallpapers"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

link_folder() {
    local src_parent="$1"
    local dest_parent="$2"
    for item in "$src_parent"/*; do
        [ -e "$item" ] || continue
        local name="$(basename "$item")"
        local target="$dest_parent/$name"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$BACKUP_DIR"
            mv "$target" "$BACKUP_DIR/"
        fi
        rm -rf "$target"
        ln -sfn "$item" "$target"
        echo -e "Linked ${BLUE}$name${NC} -> $target"
    done
}

link_folder "$REPO_DIR/config" "$HOME/.config"
link_folder "$REPO_DIR/cache" "$HOME/.cache"
link_folder "$REPO_DIR/local-bin" "$HOME/.local/bin"

chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
cp -rn "$REPO_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true

# 8. Set Fish as Default Shell
FISH_PATH="$(which fish)"
if [ "$SHELL" != "$FISH_PATH" ]; then
    echo -e "${GREEN}==> Changing default shell to Fish...${NC}"
    chsh -s "$FISH_PATH"
fi

echo -e "${BLUE}==> All done! Reboot your system to load Void services and permissions.${NC}"
