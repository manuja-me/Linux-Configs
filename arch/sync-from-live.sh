#!/usr/bin/env bash
# ==============================================================================
# Sync Live System Configurations into arch/ Repository Bundle
# ==============================================================================
# Run this script anytime you tweak your live Arch setup to pull the latest
# dotfiles, themes, and app configurations into this repository before pushing.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVE_HOME="${HOME}"
LIVE_CONFIG="${LIVE_HOME}/.config"

echo "[*] Syncing live configurations from ${LIVE_HOME} into ${SCRIPT_DIR}..."

# 1. Hyprland & Hyprcat Dotfiles
mkdir -p "${SCRIPT_DIR}/dotfiles/hypr" "${SCRIPT_DIR}/dotfiles/hyprcat"
rsync -a --delete \
    --exclude='__pycache__' \
    --exclude='*.bak' \
    "${LIVE_CONFIG}/hypr/" "${SCRIPT_DIR}/dotfiles/hypr/"

rsync -a --delete \
    --exclude='__pycache__' \
    --exclude='*.bak' \
    "${LIVE_CONFIG}/hyprcat/" "${SCRIPT_DIR}/dotfiles/hyprcat/"

# Preserve fallback profile picture in hypr/wallpapers if present on system
if [[ -f "${LIVE_HOME}/Pictures/dp.jpeg" ]]; then
    cp -f "${LIVE_HOME}/Pictures/dp.jpeg" "${SCRIPT_DIR}/dotfiles/hypr/wallpapers/dp.jpeg"
    cp -f "${LIVE_HOME}/Pictures/dp.jpeg" "${SCRIPT_DIR}/dotfiles/hypr/wallpapers/profile.jpg"
fi

# 2. Shell Configuration (Zsh)
mkdir -p "${SCRIPT_DIR}/dotfiles/zsh"
[[ -f "${LIVE_HOME}/.zshrc" ]] && cp -f "${LIVE_HOME}/.zshrc" "${SCRIPT_DIR}/dotfiles/zsh/.zshrc"
[[ -f "${LIVE_HOME}/.zprofile" ]] && cp -f "${LIVE_HOME}/.zprofile" "${SCRIPT_DIR}/dotfiles/zsh/.zprofile"

# 3. TUI & Desktop Application Configs
APP_DIRS=(
    nvim
    yazi
    btop
    cava
    mpv
    qt5ct
    spicetify
    Thunar
    viewnior
    xarchiver
    fontconfig
)

for app in "${APP_DIRS[@]}"; do
    if [[ -d "${LIVE_CONFIG}/${app}" ]]; then
        mkdir -p "${SCRIPT_DIR}/dotfiles/${app}"
        rsync -a --delete \
            --exclude='.git' \
            --exclude='__pycache__' \
            --exclude='watch_later' \
            --exclude='*.bak' \
            --exclude='*.backup' \
            "${LIVE_CONFIG}/${app}/" "${SCRIPT_DIR}/dotfiles/${app}/"
    fi
done

# 4. Misc GTK2/3/4, Ranger, Geany, Ncmpcpp, Transmission wrapper & XDG configs
mkdir -p "${SCRIPT_DIR}/misc/gtk-3.0" "${SCRIPT_DIR}/misc/gtk-4.0"
[[ -f "${LIVE_HOME}/.gtkrc-2.0" ]] && cp -f "${LIVE_HOME}/.gtkrc-2.0" "${SCRIPT_DIR}/misc/.gtkrc-2.0"
[[ -f "${LIVE_CONFIG}/gtk-3.0/gtk.css" ]] && cp -f "${LIVE_CONFIG}/gtk-3.0/gtk.css" "${SCRIPT_DIR}/misc/gtk-3.0/gtk.css"
[[ -f "${LIVE_CONFIG}/gtk-3.0/settings.ini" ]] && cp -f "${LIVE_CONFIG}/gtk-3.0/settings.ini" "${SCRIPT_DIR}/misc/gtk-3.0/settings.ini"
[[ -f "${LIVE_CONFIG}/gtk-4.0/settings.ini" ]] && cp -f "${LIVE_CONFIG}/gtk-4.0/settings.ini" "${SCRIPT_DIR}/misc/gtk-4.0/settings.ini"
[[ -f "${LIVE_CONFIG}/xdg-terminals.list" ]] && cp -f "${LIVE_CONFIG}/xdg-terminals.list" "${SCRIPT_DIR}/misc/xdg-terminals.list"
[[ -f "${LIVE_CONFIG}/mimeapps.list" ]] && cp -f "${LIVE_CONFIG}/mimeapps.list" "${SCRIPT_DIR}/misc/mimeapps.list"
[[ -f "${LIVE_HOME}/.local/bin/transmission-qt" ]] && cp -pf "${LIVE_HOME}/.local/bin/transmission-qt" "${SCRIPT_DIR}/misc/transmission-qt"

# Extra Wallpapers from ~/Pictures/wallpapers
if [[ -d "${LIVE_HOME}/Pictures/wallpapers" ]]; then
    mkdir -p "${SCRIPT_DIR}/dotfiles/wallpapers"
    rsync -a --delete "${LIVE_HOME}/Pictures/wallpapers/" "${SCRIPT_DIR}/dotfiles/wallpapers/"
fi

# Antigravity Custom Skills & Plugins
if [[ -d "${LIVE_HOME}/.gemini/config/skills" ]]; then
    mkdir -p "${SCRIPT_DIR}/dotfiles/antigravity/skills"
    rsync -a --delete --exclude='.git' --exclude='test.txt' "${LIVE_HOME}/.gemini/config/skills/" "${SCRIPT_DIR}/dotfiles/antigravity/skills/"
fi
if [[ -d "${LIVE_HOME}/.gemini/config/plugins" ]]; then
    mkdir -p "${SCRIPT_DIR}/dotfiles/antigravity/plugins"
    rsync -a --delete --exclude='.git' "${LIVE_HOME}/.gemini/config/plugins/" "${SCRIPT_DIR}/dotfiles/antigravity/plugins/"
fi

for misc_app in geany ncmpcpp ranger; do
    if [[ -d "${LIVE_CONFIG}/${misc_app}" ]]; then
        mkdir -p "${SCRIPT_DIR}/misc/${misc_app}"
        rsync -a --delete --exclude='__pycache__' "${LIVE_CONFIG}/${misc_app}/" "${SCRIPT_DIR}/misc/${misc_app}/"
    fi
done

# 5. Bootloader & Display Manager Themes (GRUB + SDDM)
if [[ -d /boot/grub/themes/Elegant-wave-window-right-dark ]]; then
    mkdir -p "${SCRIPT_DIR}/themes/grub/Elegant-wave-window-right-dark"
    rsync -a --delete /boot/grub/themes/Elegant-wave-window-right-dark/ "${SCRIPT_DIR}/themes/grub/Elegant-wave-window-right-dark/"
fi

if [[ -d /usr/share/sddm/themes/corners ]]; then
    mkdir -p "${SCRIPT_DIR}/themes/sddm/corners"
    rsync -a --delete /usr/share/sddm/themes/corners/ "${SCRIPT_DIR}/themes/sddm/corners/"
fi

# 6. Boot recovery script
if [[ -f "${LIVE_HOME}/boot-recovery/recover-boot.sh" ]]; then
    mkdir -p "${SCRIPT_DIR}/boot-recovery"
    cp -pf "${LIVE_HOME}/boot-recovery/recover-boot.sh" "${SCRIPT_DIR}/boot-recovery/recover-boot.sh"
fi

chmod -R a+rX "${SCRIPT_DIR}/dotfiles" "${SCRIPT_DIR}/misc" "${SCRIPT_DIR}/themes"

echo "[✓] Live system configurations synced to ${SCRIPT_DIR}."
