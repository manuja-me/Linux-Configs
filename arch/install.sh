#!/usr/bin/env bash
# ==============================================================================
# Arch Linux -> Aesthetic Hyprland Rice Reproducible Installer (Verbose Mode)
# ==============================================================================
# Full interactive post-base Arch TTY installer with automatic verbose logging
# and detailed error diagnostics.
# Usage:
#   ./install.sh              # Interactive wizard + automatic verbose execution
#   ./install.sh --defaults   # Unattended install with live-system defaults
# ==============================================================================

set -Eeuo pipefail

# Text styling
BOLD="$(tput bold 2>/dev/null || printf '\033[1m')"
GREEN="$(tput setaf 2 2>/dev/null || printf '\033[32m')"
BLUE="$(tput setaf 4 2>/dev/null || printf '\033[34m')"
CYAN="$(tput setaf 6 2>/dev/null || printf '\033[36m')"
YELLOW="$(tput setaf 3 2>/dev/null || printf '\033[33m')"
RED="$(tput setaf 1 2>/dev/null || printf '\033[31m')"
RESET="$(tput sgr0 2>/dev/null || printf '\033[0m')"

log_info()    { echo -e "${BLUE}${BOLD}[*]${RESET} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[✓]${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $1"; }
log_err()     { echo -e "${RED}${BOLD}[✗]${RESET} $1"; }
log_section() { echo -e "\n${CYAN}${BOLD}=== $1 ===${RESET}\n"; }

LOG_FILE="/tmp/arch-hypr-install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

on_error() {
    local exit_code=$?
    local line_no=$1
    local func_name="${2:-main}"
    local cmd="$3"
    set +x 2>/dev/null || true
    echo -e "\n${RED}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}" >&2
    echo -e "${RED}${BOLD}║                  INSTALLATION ERROR DETECTED                 ║${RESET}" >&2
    echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}" >&2
    echo -e "  ${RED}${BOLD}• Function :${RESET} ${func_name}()" >&2
    echo -e "  ${RED}${BOLD}• Line     :${RESET} ${line_no}" >&2
    echo -e "  ${RED}${BOLD}• Exit Code:${RESET} ${exit_code}" >&2
    echo -e "  ${RED}${BOLD}• Command  :${RESET} ${cmd}" >&2
    echo -e "  ${YELLOW}${BOLD}• Full Log :${RESET} ${LOG_FILE}" >&2
    echo -e "  ${CYAN}${BOLD}• Rollback :${RESET} ${SRC_DIR:-.}/restore.sh\n" >&2
}
trap 'on_error $LINENO "${FUNCNAME[0]:-main}" "$BASH_COMMAND"' ERR

# Attach stdin to /dev/tty so sudo, su, passwd, and yay can always prompt for passwords interactively
if [[ -e /dev/tty ]]; then
    exec </dev/tty
fi

UNATTENDED=false
for arg in "$@"; do
    case "$arg" in
        -y|--yes|--defaults) UNATTENDED=true ;;
    esac
done

# Helper to read from /dev/tty even if script was piped
prompt_input() {
    local prompt_text="$1"
    local default_val="$2"
    local reply=""
    if [[ "$UNATTENDED" == true ]] || [[ ! -e /dev/tty ]]; then
        echo "$default_val"
        return 0
    fi
    read -r -p "$prompt_text" reply </dev/tty || true
    echo "${reply:-$default_val}"
}

prompt_yn() {
    local prompt_text="$1"
    local default_ans="${2:-Y}"
    local hint="[Y/n]"
    [[ "$default_ans" =~ ^[Nn]$ ]] && hint="[y/N]"
    if [[ "$UNATTENDED" == true ]] || [[ ! -e /dev/tty ]]; then
        [[ "$default_ans" =~ ^[Yy]$ ]] && return 0 || return 1
    fi
    local reply=""
    read -r -p "${prompt_text} ${hint}: " reply </dev/tty || true
    reply="${reply:-$default_ans}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

ensure_sudo() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    fi
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo privileges required — please type your sudo password:"
        if ! sudo -v </dev/tty; then
            log_warn "User '$(whoami)' may not be in sudoers yet. Enter root password (su) to enable wheel sudo access:"
            su -c "mkdir -p /etc/sudoers.d && echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel && chmod 440 /etc/sudoers.d/10-wheel && usermod -aG wheel $(whoami)" </dev/tty
            log_info "Now enter your user sudo password:"
            sudo -v </dev/tty
        fi
    fi
}

run_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        ensure_sudo
        sudo "$@"
    fi
}

run_as_user() {
    if [[ "$(whoami)" == "$TARGET_USER" ]]; then
        "$@"
    elif [[ $EUID -eq 0 ]]; then
        sudo -u "$TARGET_USER" -H "$@"
    else
        ensure_sudo
        sudo -u "$TARGET_USER" -H "$@"
    fi
}

# ------------------------------------------------------------------------------
# 0. Locate Source Repository
# ------------------------------------------------------------------------------
find_config_source() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local candidates=(
        "$script_dir"
        "$PWD/arch"
        "$PWD"
        "$HOME/nixos-config/arch"
        "$HOME/Documents/github/nixos-config/arch"
    )
    for path in "${candidates[@]}"; do
        if [[ -d "$path/dotfiles" && -d "$path/gtk" && -d "$path/fonts" ]]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

SRC_DIR="$(find_config_source || true)"
if [[ -z "$SRC_DIR" ]]; then
    log_err "Could not find valid 'arch/' configuration directory."
    exit 1
fi

# ------------------------------------------------------------------------------
# 1. Interactive Setup Wizard
# ------------------------------------------------------------------------------
interactive_wizard() {
    log_section "Step 0: Interactive Build Configuration"

    local detected_user="${SUDO_USER:-$(whoami)}"
    [[ "$detected_user" == "root" ]] && detected_user="user"

    echo -e "${BOLD}1. Target User Account${RESET}"
    TARGET_USER="$(prompt_input "   Enter target username [${detected_user}]: " "$detected_user")"
    # Sanitize username
    TARGET_USER="$(echo "$TARGET_USER" | tr -cd 'a-zA-Z0-9_-')"
    [[ -z "$TARGET_USER" ]] && TARGET_USER="user"

    echo -e "\n${BOLD}2. GPU Driver Selection${RESET}"
    echo "   1) Intel (mesa, vulkan-intel, intel-media-driver, libva-intel-driver) [Default]"
    echo "   2) AMD (mesa, vulkan-radeon, libva-mesa-driver)"
    echo "   3) NVIDIA (nvidia-dkms, nvidia-utils, libva-nvidia-driver + Wayland env)"
    echo "   4) VM / Software / Skip GPU drivers"
    GPU_CHOICE="$(prompt_input "   Select GPU option [1-4, default: 1]: " "1")"

    echo -e "\n${BOLD}3. Display Manager (SDDM) Theme${RESET}"
    echo "   1) Corners (Catppuccin Mocha custom theme) [Default]"
    echo "   2) Astronaut (sddm-astronaut-theme)"
    echo "   3) Skip SDDM configuration"
    SDDM_CHOICE="$(prompt_input "   Select SDDM theme [1-3, default: 1]: " "1")"

    echo -e "\n${BOLD}4. Bootloader & Recovery Tools${RESET}"
    INSTALL_GRUB_THEME=false
    if prompt_yn "   Install Elegant GRUB2 theme & enable os-prober?" "Y"; then
        INSTALL_GRUB_THEME=true
    fi

    echo -e "\n${BOLD}5. Optional Feature Bundles${RESET}"
    INSTALL_SHELL_TUI=false
    if prompt_yn "   Install Shell & TUI Suite (Zsh, Oh-My-Zsh, Neovim/LazyVim, Yazi, Btop, Cava, Fastfetch, Zathura)?" "Y"; then
        INSTALL_SHELL_TUI=true
    fi

    INSTALL_MEDIA=false
    if prompt_yn "   Install Media & Audio Suite (Spotify, Spicetify, EasyEffects, MPV, MPD/ncmpcpp, yt-dlp)?" "Y"; then
        INSTALL_MEDIA=true
    fi

    INSTALL_EXTRA_APPS=false
    if prompt_yn "   Install Extra Desktop Utilities (Firefox, Chromium, LocalSend, GParted, Timeshift, Transmission)?" "Y"; then
        INSTALL_EXTRA_APPS=true
    fi

    INSTALL_VIRT=false
    if prompt_yn "   Install KVM/QEMU Virtualization Suite (QEMU, libvirt, Virt-Manager)?" "Y"; then
        INSTALL_VIRT=true
    fi

    INSTALL_ANTIGRAVITY=false
    if prompt_yn "   Run Google Antigravity & AI Agent Setup (agy, claude-mem, headroom, opencode)?" "Y"; then
        INSTALL_ANTIGRAVITY=true
    fi

    echo ""
    log_info "Summary:"
    echo "   • Target User       : $TARGET_USER"
    echo "   • GPU Choice        : $GPU_CHOICE"
    echo "   • SDDM Theme        : $SDDM_CHOICE"
    echo "   • GRUB Theme        : $INSTALL_GRUB_THEME"
    echo "   • Shell & TUI Suite : $INSTALL_SHELL_TUI"
    echo "   • Media Suite       : $INSTALL_MEDIA"
    echo "   • Extra Utilities   : $INSTALL_EXTRA_APPS"
    echo "   • Virtualization    : $INSTALL_VIRT"
    echo "   • Antigravity AI    : $INSTALL_ANTIGRAVITY"
    echo ""
    if ! prompt_yn "Proceed with installation?" "Y"; then
        log_warn "Installation aborted by user."
        exit 0
    fi
}

# ------------------------------------------------------------------------------
# 2. User Account & Privilege Setup
# ------------------------------------------------------------------------------
setup_user_account() {
    log_section "Step 1: Configuring User Account ($TARGET_USER)"

    if ! id "$TARGET_USER" &>/dev/null; then
        log_info "User '$TARGET_USER' does not exist. Creating account..."
        run_root useradd -m -G wheel,video,input -s /bin/bash "$TARGET_USER"
        if [[ "$UNATTENDED" == false && -e /dev/tty ]]; then
            log_info "Set password for '$TARGET_USER':"
            run_root passwd "$TARGET_USER" </dev/tty
        fi
    else
        log_info "User '$TARGET_USER' exists. Ensuring group memberships..."
        run_root usermod -aG wheel,video,input "$TARGET_USER" 2>/dev/null || true
    fi

    USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
    CONFIG_DIR="$USER_HOME/.config"
    DATA_DIR="$USER_HOME/.local/share"
    BACKUP_DIR="$USER_HOME/.config-backups/hypr-rice-$(date +%Y%m%d-%H%M%S)"

    # Ensure wheel group has sudo permissions (prompts for sudo password when needed)
    run_root mkdir -p /etc/sudoers.d
    echo "%wheel ALL=(ALL:ALL) ALL" | run_root tee /etc/sudoers.d/10-wheel >/dev/null
    run_root chmod 440 /etc/sudoers.d/10-wheel

    # If repo was cloned into /root, copy it into target user's home directory
    local repo_root
    repo_root="$(cd "$SRC_DIR/.." && pwd)"
    if [[ "$repo_root" == /root/* && ! -d "$USER_HOME/nixos-config" ]]; then
        log_info "Copying repository to $USER_HOME/nixos-config..."
        run_root cp -ra "$repo_root" "$USER_HOME/nixos-config"
        run_root chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/nixos-config"
        SRC_DIR="$USER_HOME/nixos-config/arch"
    fi

    log_success "User '$TARGET_USER' ready (Home: $USER_HOME)."
}

# ------------------------------------------------------------------------------
# 3. Package Management & Dependencies
# ------------------------------------------------------------------------------
install_packages() {
    log_section "Step 2: Optimizing Pacman & Installing System/Desktop Packages"

    # 1. Enable Color and ParallelDownloads = 5 in /etc/pacman.conf for 5x faster package downloads
    if [[ -f /etc/pacman.conf ]]; then
        log_info "Enabling Color and ParallelDownloads = 5 in /etc/pacman.conf..."
        run_root sed -i 's/^#Color/Color/' /etc/pacman.conf
        if grep -q '^#\?ParallelDownloads' /etc/pacman.conf; then
            run_root sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
        else
            run_root sed -i '/^\[options\]/a ParallelDownloads = 5' /etc/pacman.conf
        fi
    fi

    local pacman_pkgs=(
        # Core Build, ZRAM & System Utilities
        base-devel git curl wget rsync unzip unrar 7zip zram-generator
        xdg-user-dirs xdg-utils gvfs polkit-gnome polkit-kde-agent

        # Wayland & Hyprland Core
        hyprland hyprlock hypridle hyprpaper hyprpicker hyprsunset xorg-xwayland uwsm
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        qt5-wayland qt6-wayland qt5ct qt5-quickcontrols2 qt6-virtualkeyboard

        # Status Bar, Launchers & Notifications
        waybar rofi wofi mako yad libnotify

        # Audio (PipeWire)
        pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
        gst-plugin-pipewire libpulse pavucontrol pulsemixer pamixer sof-firmware

        # Terminals & File Managers
        kitty alacritty foot thunar thunar-archive-plugin thunar-volman
        tumbler file-roller xarchiver viewnior geany ranger

        # Screenshots, Clipboard, Wallpaper & Theming
        grim slurp swappy imagemagick wl-clipboard wf-recorder cliphist
        brightnessctl pastel lxappearance xfce4-settings materia-gtk-theme breeze breeze-gtk

        # Network, Bluetooth & Power
        networkmanager network-manager-applet bluez bluez-utils blueman
        power-profiles-daemon

        # Display Manager
        sddm

        # Fonts
        noto-fonts noto-fonts-emoji ttf-jetbrains-mono ttf-jetbrains-mono-nerd
        ttf-nerd-fonts-symbols otf-font-awesome woff2-font-awesome ttf-croscore
    )

    local aur_pkgs=(
        wlogout
        python-pywal
        light
    )

    # GPU Drivers
    case "$GPU_CHOICE" in
        1) pacman_pkgs+=(mesa vulkan-intel intel-media-driver libva-intel-driver intel-ucode) ;;
        2) pacman_pkgs+=(mesa vulkan-radeon libva-mesa-driver amd-ucode) ;;
        3) pacman_pkgs+=(nvidia-dkms nvidia-utils libva-nvidia-driver) ;;
        *) log_info "Skipping dedicated GPU driver packages." ;;
    esac

    # SDDM Theme Packages
    case "$SDDM_CHOICE" in
        1) aur_pkgs+=(sddm-theme-corners-git) ;;
        2) aur_pkgs+=(sddm-astronaut-theme) ;;
    esac

    # GRUB / Boot Packages
    if [[ "$INSTALL_GRUB_THEME" == true ]]; then
        pacman_pkgs+=(grub efibootmgr os-prober)
    fi

    # Shell & TUI Bundle
    if [[ "$INSTALL_SHELL_TUI" == true ]]; then
        pacman_pkgs+=(
            zsh neovim ripgrep fd tree-sitter yazi fzf gum fastfetch btop htop cava
            zathura zathura-pdf-mupdf ueberzugpp poppler man-db
            npm python-pip python-pipx rustup
        )
    fi

    # Media & Audio Bundle
    if [[ "$INSTALL_MEDIA" == true ]]; then
        pacman_pkgs+=(easyeffects calf mpv mpd mpc ncmpcpp yt-dlp)
        aur_pkgs+=(spotify spicetify-cli)
    fi

    # Extra Desktop Utilities
    if [[ "$INSTALL_EXTRA_APPS" == true ]]; then
        pacman_pkgs+=(
            firefox chromium gparted timeshift transmission-qt
            ntfs-3g exfatprogs reflector aria2 nvtop smartmontools
        )
        aur_pkgs+=(localsend-bin linutil)
    fi

    # Virtualization Suite
    if [[ "$INSTALL_VIRT" == true ]]; then
        pacman_pkgs+=(qemu-desktop qemu-emulators-full libvirt virt-manager dnsmasq swtpm dmidecode iptables)
    fi

    log_info "Installing official repository packages via pacman..."
    run_root pacman -Sy --needed --noconfirm "${pacman_pkgs[@]}"

    # Initialize Rust stable toolchain if rustup was installed (prevents cargo/AUR build failures)
    if command -v rustup &>/dev/null; then
        log_info "Initializing default stable Rust toolchain for $TARGET_USER..."
        run_as_user rustup default stable || true
    fi

    # Install or detect AUR helper (yay)
    local aur_helper=""
    if command -v yay &>/dev/null; then
        aur_helper="yay"
    elif command -v paru &>/dev/null; then
        aur_helper="paru"
    else
        log_info "Installing yay-bin AUR helper as $TARGET_USER (type sudo password if prompted)..."
        ensure_sudo
        local tmp_yay="/tmp/yay-bin-$$"
        run_root rm -rf "$tmp_yay"
        run_as_user git clone https://aur.archlinux.org/yay-bin.git "$tmp_yay"
        (cd "$tmp_yay" && run_as_user makepkg -si --noconfirm)
        run_root rm -rf "$tmp_yay"
        aur_helper="yay"
    fi

    log_info "Installing AUR packages via $aur_helper (type sudo password if prompted)..."
    ensure_sudo
    run_as_user "$aur_helper" -S --needed --noconfirm "${aur_pkgs[@]}" || log_warn "Some optional AUR packages could not be built; continuing..."

    # Grant write permissions on /opt/spotify so Spicetify can apply themes without root errors
    if [[ -d /opt/spotify ]]; then
        log_info "Granting user write permissions on /opt/spotify for Spicetify..."
        run_root chmod a+wr /opt/spotify
        [[ -d /opt/spotify/Apps ]] && run_root chmod -R a+wr /opt/spotify/Apps || true
    fi

    log_success "Package installation complete."
}

# ------------------------------------------------------------------------------
# 4. Pre-Install Snapshot Backup
# ------------------------------------------------------------------------------
backup_existing() {
    log_section "Step 3: Creating Pre-Install Configuration Snapshot"
    run_as_user mkdir -p "$BACKUP_DIR"

    local items_to_backup=(
        "$CONFIG_DIR/hypr"
        "$CONFIG_DIR/hyprcat"
        "$CONFIG_DIR/kitty"
        "$CONFIG_DIR/alacritty"
        "$CONFIG_DIR/gtk-3.0"
        "$CONFIG_DIR/gtk-4.0"
        "$CONFIG_DIR/geany"
        "$CONFIG_DIR/ncmpcpp"
        "$CONFIG_DIR/ranger"
        "$CONFIG_DIR/nvim"
        "$CONFIG_DIR/yazi"
        "$CONFIG_DIR/btop"
        "$CONFIG_DIR/cava"
        "$CONFIG_DIR/mpv"
        "$CONFIG_DIR/qt5ct"
        "$CONFIG_DIR/spicetify"
        "$CONFIG_DIR/Thunar"
        "$CONFIG_DIR/viewnior"
        "$CONFIG_DIR/xarchiver"
        "$CONFIG_DIR/fontconfig"
        "$USER_HOME/.zshrc"
        "$USER_HOME/.zprofile"
        "$USER_HOME/.gtkrc-2.0"
    )

    for item in "${items_to_backup[@]}"; do
        if [[ -e "$item" ]]; then
            cp -ra "$item" "$BACKUP_DIR/" || true
        fi
    done

    run_root chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.config-backups"
    log_success "Snapshot saved to: $BACKUP_DIR"
}

# ------------------------------------------------------------------------------
# 5. Fonts, GTK Themes, Icons & Cursors
# ------------------------------------------------------------------------------
install_assets() {
    log_section "Step 4: Installing Fonts, GTK Themes, Icons & Cursors"

    run_as_user mkdir -p "$DATA_DIR/fonts" "$DATA_DIR/themes" "$DATA_DIR/icons"

    cp -rf "$SRC_DIR/fonts"/* "$DATA_DIR/fonts/"
    cp -rf "$SRC_DIR/gtk/theme"/* "$DATA_DIR/themes/"
    cp -rf "$SRC_DIR/gtk/icons"/* "$DATA_DIR/icons/"
    cp -rf "$SRC_DIR/gtk/cursor"/* "$DATA_DIR/icons/"

    run_root chown -R "$TARGET_USER:$TARGET_USER" "$DATA_DIR"
    log_info "Updating font cache..."
    run_as_user fc-cache -fv || true

    log_success "Fonts, themes, icons, and cursors installed."
}

# ------------------------------------------------------------------------------
# 6. Deploying Dotfiles & App Configurations
# ------------------------------------------------------------------------------
deploy_dotfiles() {
    log_section "Step 5: Deploying Desktop & Application Dotfiles"

    run_as_user mkdir -p "$CONFIG_DIR" "$USER_HOME/Pictures" "$USER_HOME/boot-recovery"
    run_as_user xdg-user-dirs-update || true

    # Core Hyprland & Hyprcat configs
    cp -rf "$SRC_DIR/dotfiles/hypr" "$CONFIG_DIR/"
    cp -rf "$SRC_DIR/dotfiles/hyprcat" "$CONFIG_DIR/"

    # Profile picture for Hyprlock
    if [[ -f "$SRC_DIR/dotfiles/hypr/wallpapers/dp.jpeg" && ! -f "$USER_HOME/Pictures/dp.jpeg" ]]; then
        cp -f "$SRC_DIR/dotfiles/hypr/wallpapers/dp.jpeg" "$USER_HOME/Pictures/dp.jpeg"
    elif [[ -f "$SRC_DIR/dotfiles/hypr/wallpapers/profile.jpg" && ! -f "$USER_HOME/Pictures/dp.jpeg" ]]; then
        cp -f "$SRC_DIR/dotfiles/hypr/wallpapers/profile.jpg" "$USER_HOME/Pictures/dp.jpeg"
    fi

    # Boot recovery script in ~/boot-recovery
    if [[ -f "$SRC_DIR/boot-recovery/recover-boot.sh" ]]; then
        cp -pf "$SRC_DIR/boot-recovery/recover-boot.sh" "$USER_HOME/boot-recovery/recover-boot.sh"
        chmod +x "$USER_HOME/boot-recovery/recover-boot.sh"
    fi

    # Kitty & Alacritty top-level configs
    mkdir -p "$CONFIG_DIR/kitty" "$CONFIG_DIR/alacritty"
    cat > "$CONFIG_DIR/kitty/kitty.conf" << 'EOF'
## Main Kitty Configuration
include ~/.config/hypr/kitty/colors.conf
include ~/.config/hypr/kitty/fonts.conf

cursor_shape block
cursor_beam_thickness 6
window_padding_width 12
remember_window_size no
initial_window_width 785
initial_window_height 450
allow_remote_control yes
EOF

    cat > "$CONFIG_DIR/alacritty/alacritty.toml" << 'EOF'
## Main Alacritty Configuration
[general]
import = ["~/.config/hypr/alacritty/colors.toml", "~/.config/hypr/alacritty/fonts.toml"]
live_config_reload = true
ipc_socket = true

[window]
padding = { x = 12, y = 12 }
dynamic_padding = true
opacity = 1.0

[cursor]
style = { shape = "Block", blinking = "On" }
EOF

    # Deploy synced app directories from arch/dotfiles/
    local synced_apps=(nvim yazi btop cava mpv qt5ct spicetify Thunar viewnior xarchiver fontconfig)
    for app in "${synced_apps[@]}"; do
        if [[ -d "$SRC_DIR/dotfiles/$app" ]]; then
            mkdir -p "$CONFIG_DIR/$app"
            cp -rf "$SRC_DIR/dotfiles/$app"/. "$CONFIG_DIR/$app/"
        fi
    done

    # Deploy misc configs (gtk-3.0, gtk-4.0, .gtkrc-2.0, geany, ncmpcpp, ranger, mimeapps, xdg-terminals, transmission wrapper)
    mkdir -p "$CONFIG_DIR/gtk-3.0" "$CONFIG_DIR/gtk-4.0" "$CONFIG_DIR/geany" "$CONFIG_DIR/ncmpcpp" "$CONFIG_DIR/ranger" "$USER_HOME/.local/bin"
    [[ -f "$SRC_DIR/misc/.gtkrc-2.0" ]] && cp -f "$SRC_DIR/misc/.gtkrc-2.0" "$USER_HOME/.gtkrc-2.0"
    [[ -f "$SRC_DIR/misc/gtk-3.0/gtk.css" ]] && cp -f "$SRC_DIR/misc/gtk-3.0/gtk.css" "$CONFIG_DIR/gtk-3.0/"
    [[ -f "$SRC_DIR/misc/gtk-3.0/settings.ini" ]] && cp -f "$SRC_DIR/misc/gtk-3.0/settings.ini" "$CONFIG_DIR/gtk-3.0/"
    [[ -f "$SRC_DIR/misc/gtk-4.0/settings.ini" ]] && cp -f "$SRC_DIR/misc/gtk-4.0/settings.ini" "$CONFIG_DIR/gtk-4.0/"
    [[ -f "$SRC_DIR/misc/xdg-terminals.list" ]] && cp -f "$SRC_DIR/misc/xdg-terminals.list" "$CONFIG_DIR/xdg-terminals.list"
    [[ -f "$SRC_DIR/misc/mimeapps.list" ]] && cp -f "$SRC_DIR/misc/mimeapps.list" "$CONFIG_DIR/mimeapps.list"
    if [[ -f "$SRC_DIR/misc/transmission-qt" ]]; then
        cp -pf "$SRC_DIR/misc/transmission-qt" "$USER_HOME/.local/bin/transmission-qt"
        chmod +x "$USER_HOME/.local/bin/transmission-qt"
    fi
    [[ -d "$SRC_DIR/misc/geany" ]] && cp -rf "$SRC_DIR/misc/geany"/* "$CONFIG_DIR/geany/"
    [[ -d "$SRC_DIR/misc/ncmpcpp" ]] && cp -rf "$SRC_DIR/misc/ncmpcpp"/* "$CONFIG_DIR/ncmpcpp/"
    [[ -d "$SRC_DIR/misc/ranger" ]] && cp -rf "$SRC_DIR/misc/ranger"/* "$CONFIG_DIR/ranger/"

    # Deploy extra wallpapers to ~/Pictures/wallpapers (used by theme.sh --pywal & .zshrc aliases)
    if [[ -d "$SRC_DIR/dotfiles/wallpapers" ]]; then
        mkdir -p "$USER_HOME/Pictures/wallpapers"
        cp -rf "$SRC_DIR/dotfiles/wallpapers"/. "$USER_HOME/Pictures/wallpapers/"
    fi

    # Deploy bundled Antigravity custom skills & plugins
    if [[ -d "$SRC_DIR/dotfiles/antigravity/skills" ]]; then
        mkdir -p "$USER_HOME/.gemini/config/skills"
        cp -rf "$SRC_DIR/dotfiles/antigravity/skills"/. "$USER_HOME/.gemini/config/skills/"
    fi
    if [[ -d "$SRC_DIR/dotfiles/antigravity/plugins" ]]; then
        mkdir -p "$USER_HOME/.gemini/config/plugins"
        cp -rf "$SRC_DIR/dotfiles/antigravity/plugins"/. "$USER_HOME/.gemini/config/plugins/"
    fi

    # Environment variables
    mkdir -p "$CONFIG_DIR/environment.d"
    if [[ -d "$SRC_DIR/misc/environment.d" ]]; then
        cp -rf "$SRC_DIR/misc/environment.d"/* "$CONFIG_DIR/environment.d/"
    else
        cat > "$CONFIG_DIR/environment.d/10-terminal.conf" << 'EOF'
TERMINAL=kitty
BROWSER=firefox
EDITOR=nvim
VISUAL=nvim
QT_QPA_PLATFORMTHEME=qt5ct
QT_STYLE_OVERRIDE=Fusion
EOF
    fi

    # Setup Zsh & Oh-My-Zsh if enabled
    if [[ "$INSTALL_SHELL_TUI" == true ]]; then
        if [[ ! -d "$USER_HOME/.oh-my-zsh" ]]; then
            log_info "Installing Oh-My-Zsh for $TARGET_USER..."
            run_as_user sh -c 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' || true
        fi
        [[ -f "$SRC_DIR/dotfiles/zsh/.zshrc" ]] && cp -f "$SRC_DIR/dotfiles/zsh/.zshrc" "$USER_HOME/.zshrc"
        [[ -f "$SRC_DIR/dotfiles/zsh/.zprofile" ]] && cp -f "$SRC_DIR/dotfiles/zsh/.zprofile" "$USER_HOME/.zprofile"
        run_root usermod -s /bin/zsh "$TARGET_USER" || true
    fi

    # Dynamic path normalization: rewrite /home/user -> $USER_HOME if username differs
    if [[ "$USER_HOME" != "/home/user" ]]; then
        log_info "Normalizing paths from /home/user to $USER_HOME..."
        local files_to_rewrite=(
            "$CONFIG_DIR/hypr/hyprlock.conf"
            "$CONFIG_DIR/hypr/hyprpaper.conf"
            "$CONFIG_DIR/hypr/hyprland.lua"
            "$CONFIG_DIR/hypr/theme/current.bash"
            "$CONFIG_DIR/hyprcat/hyprlock.conf"
            "$CONFIG_DIR/hyprcat/hyprpaper.conf"
            "$CONFIG_DIR/hyprcat/hyprland.lua"
            "$CONFIG_DIR/hyprcat/theme/current.bash"
            "$CONFIG_DIR/spicetify/config-xpui.ini"
            "$USER_HOME/.zshrc"
        )
        for f in "${files_to_rewrite[@]}"; do
            if [[ -f "$f" ]]; then
                sed -i "s|/home/user|${USER_HOME}|g" "$f" || true
            fi
        done
    fi

    # Ensure scripts are executable
    chmod +x "$CONFIG_DIR"/hypr/scripts/* "$CONFIG_DIR"/hyprcat/scripts/* \
        "$CONFIG_DIR"/hypr/theme/theme.sh "$CONFIG_DIR"/hyprcat/theme/theme.sh \
        "$CONFIG_DIR"/hypr/waybar/lightmode || true

    run_root chown -R "$TARGET_USER:$TARGET_USER" "$CONFIG_DIR" "$USER_HOME/Pictures" "$USER_HOME/boot-recovery" "$USER_HOME/.local" "$USER_HOME/.gemini" "$USER_HOME/.gtkrc-2.0" "$USER_HOME/.zshrc" "$USER_HOME/.zprofile" || true

    log_success "Dotfiles and application configs deployed."
}

# ------------------------------------------------------------------------------
# 7. System Session Launchers, SDDM, GRUB, ZRAM & Services
# ------------------------------------------------------------------------------
configure_system_and_services() {
    log_section "Step 6: Configuring System Sessions, SDDM, GRUB, ZRAM & Services"

    local MISC_DIR="$SRC_DIR/misc"

    # Session launch scripts
    run_root cp -f "$MISC_DIR/run-hyprland" /usr/local/bin/run-hyprland
    run_root cp -f "$MISC_DIR/run-hyprland-cat" /usr/local/bin/run-hyprland-cat

    # Configure GPU Wayland profile in config.d and environment.d
    log_info "Configuring GPU Wayland profile (choice: $GPU_CHOICE)..."
    mkdir -p "$CONFIG_DIR/hypr/config.d" "$CONFIG_DIR/environment.d"
    case "$GPU_CHOICE" in
        1)
            cat > "$CONFIG_DIR/hypr/config.d/00-gpu.conf" << 'EOF'
# Force desktop apps, wallpaper & browser to integrated Intel Iris Xe
env = AQ_DRM_DEVICES,/dev/dri/card1
env = __EGL_VENDOR_LIBRARY_FILENAMES,/usr/share/glvnd/egl_vendor.d/50_mesa.json
env = VK_DRIVER_FILES,/usr/share/vulkan/icd.d/intel_icd.json
env = LIBVA_DRIVER_NAME,iHD
env = MOZ_DRM_DEVICE,/dev/dri/renderD128
env = DRI_PRIME,pci-0000_00_02_0
EOF
            cat > "$CONFIG_DIR/environment.d/00-gpu.conf" << 'EOF'
AQ_DRM_DEVICES=/dev/dri/card1
__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
VK_DRIVER_FILES=/usr/share/vulkan/icd.d/intel_icd.json
LIBVA_DRIVER_NAME=iHD
MOZ_DRM_DEVICE=/dev/dri/renderD128
DRI_PRIME=pci-0000_00_02_0
EOF
            ;;
        2)
            cat > "$CONFIG_DIR/hypr/config.d/00-gpu.conf" << 'EOF'
# AMD GPU Configuration
env = LIBVA_DRIVER_NAME,radeonsi
env = VDPAU_DRIVER,radeonsi
EOF
            cat > "$CONFIG_DIR/environment.d/00-gpu.conf" << 'EOF'
LIBVA_DRIVER_NAME=radeonsi
VDPAU_DRIVER=radeonsi
EOF
            ;;
        3)
            cat > "$CONFIG_DIR/hypr/config.d/00-gpu.conf" << 'EOF'
# NVIDIA Wayland Configuration
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = ELECTRON_OZONE_PLATFORM_HINT,auto
EOF
            cat > "$CONFIG_DIR/environment.d/00-gpu.conf" << 'EOF'
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
NVD_BACKEND=direct
ELECTRON_OZONE_PLATFORM_HINT=auto
EOF
            if ! grep -q "LIBVA_DRIVER_NAME=nvidia" /usr/local/bin/run-hyprland; then
                run_root sed -i '/^export XDG_SESSION_DESKTOP/a export LIBVA_DRIVER_NAME=nvidia\nexport GBM_BACKEND=nvidia-drm\nexport __GLX_VENDOR_LIBRARY_NAME=nvidia\nexport NVD_BACKEND=direct\nexport ELECTRON_OZONE_PLATFORM_HINT=auto' /usr/local/bin/run-hyprland
            fi
            ;;
        *)
            rm -f "$CONFIG_DIR/hypr/config.d/00-gpu.conf" "$CONFIG_DIR/environment.d/00-gpu.conf"
            ;;
    esac
    chown -R "$TARGET_USER:$TARGET_USER" "$CONFIG_DIR/hypr/config.d" "$CONFIG_DIR/environment.d" 2>/dev/null || true
    run_root chmod +x /usr/local/bin/run-hyprland /usr/local/bin/run-hyprland-cat

    # Wayland desktop sessions
    run_root mkdir -p /usr/share/wayland-sessions
    run_root cp -f "$MISC_DIR/hyprland-cat.desktop" /usr/share/wayland-sessions/hyprland-cat.desktop
    run_root tee /usr/share/wayland-sessions/hyprland.desktop >/dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=run-hyprland
Type=Application
DesktopNames=Hyprland
Keywords=tiling;wayland;compositor;
EOF

    # Pacman hooks
    run_root mkdir -p /etc/pacman.d/hooks
    run_root cp -f "$MISC_DIR/archcraft-hook-hyprland.hook" /etc/pacman.d/hooks/
    run_root cp -f "$MISC_DIR/archcraft-hook-hyprland-uwsm.hook" /etc/pacman.d/hooks/

    # Configure ZRAM swap (/etc/systemd/zram-generator.conf)
    log_info "Configuring ZRAM swap (/etc/systemd/zram-generator.conf)..."
    run_root mkdir -p /etc/systemd
    run_root tee /etc/systemd/zram-generator.conf >/dev/null << 'EOF'
[zram0]
zram-size = 7803
compression-algorithm = lz4
EOF
    run_root systemctl daemon-reload || true
    run_root systemctl start systemd-zram-setup@zram0.service || true

    # SDDM Theme configuration
    if [[ "$SDDM_CHOICE" == "1" ]]; then
        log_info "Configuring SDDM with customized 'corners' theme..."
        if [[ -d "$SRC_DIR/themes/sddm/corners" ]]; then
            run_root mkdir -p /usr/share/sddm/themes/corners
            run_root cp -rf "$SRC_DIR/themes/sddm/corners"/. /usr/share/sddm/themes/corners/
        fi
        run_root mkdir -p /etc/sddm.conf.d
        run_root tee /etc/sddm.conf >/dev/null << 'EOF'
[Theme]
    Current=corners
EOF
        run_root tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null << 'EOF'
[General]
    InputMethod=qtvirtualkeyboard
EOF
    elif [[ "$SDDM_CHOICE" == "2" ]]; then
        log_info "Configuring SDDM with 'sddm-astronaut-theme'..."
        run_root mkdir -p /etc/sddm.conf.d
        run_root tee /etc/sddm.conf >/dev/null << 'EOF'
[Theme]
    Current=sddm-astronaut-theme
[General]
    InputMethod=qtvirtualkeyboard
EOF
        run_root tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null << 'EOF'
[General]
    InputMethod=qtvirtualkeyboard
EOF
    fi

    # GRUB Theme configuration
    if [[ "$INSTALL_GRUB_THEME" == true && -d "$SRC_DIR/themes/grub/Elegant-wave-window-right-dark" && -f /etc/default/grub ]]; then
        log_info "Installing Elegant GRUB2 theme to /boot/grub/themes/..."
        run_root mkdir -p /boot/grub/themes/Elegant-wave-window-right-dark
        run_root cp -rf "$SRC_DIR/themes/grub/Elegant-wave-window-right-dark"/. /boot/grub/themes/Elegant-wave-window-right-dark/

        run_root cp -a /etc/default/grub "/etc/default/grub.bak-$(date +%Y%m%d-%H%M%S)"
        run_root sed -i '/^#\?GRUB_THEME=/d' /etc/default/grub
        run_root sed -i '/^#\?GRUB_BACKGROUND=/d' /etc/default/grub
        run_root sed -i '/^#\?GRUB_DISABLE_OS_PROBER=/d' /etc/default/grub
        run_root sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080,auto/' /etc/default/grub
        cat << 'EOF' | run_root tee -a /etc/default/grub >/dev/null
GRUB_BACKGROUND="/boot/grub/themes/Elegant-wave-window-right-dark/background.jpg"
GRUB_THEME="/boot/grub/themes/Elegant-wave-window-right-dark/theme.txt"
GRUB_DISABLE_OS_PROBER=false
EOF
        if command -v grub-mkconfig &>/dev/null && [[ -d /boot/grub ]]; then
            log_info "Regenerating /boot/grub/grub.cfg..."
            run_root grub-mkconfig -o /boot/grub/grub.cfg || log_warn "grub-mkconfig returned non-zero; check bootloader configuration."
        fi
    fi

    # Enable systemd system & user services
    log_info "Enabling systemd services..."
    [[ "$SDDM_CHOICE" != "3" ]] && run_root systemctl enable sddm.service || true
    run_root systemctl enable NetworkManager.service || true
    run_root systemctl enable bluetooth.service || true
    run_root systemctl enable power-profiles-daemon.service || true
    run_root systemctl enable fstrim.timer || true

    # Enable PipeWire user sockets for target user
    run_as_user systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service || true

    if [[ "$INSTALL_VIRT" == true ]]; then
        run_root systemctl enable libvirtd.service || true
        run_root usermod -aG libvirt "$TARGET_USER" || true
    fi

    log_success "System sessions, themes, ZRAM, and services configured."
}

# ------------------------------------------------------------------------------
# 8. Optional Google Antigravity Setup & Final Theme Initialization
# ------------------------------------------------------------------------------
finalize_setup() {
    log_section "Step 7: Finalizing Theme & Optional Suites"

    if [[ "$INSTALL_ANTIGRAVITY" == true && -f "$SRC_DIR/setup-antigravity.sh" ]]; then
        log_info "Running Google Antigravity & AI Agent setup..."
        chmod +x "$SRC_DIR/setup-antigravity.sh"
        run_as_user bash "$SRC_DIR/setup-antigravity.sh" || log_warn "Antigravity setup encountered a non-fatal warning."
    fi

    # Apply initial GTK settings
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Manhattan' || true
    run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Luv-Folders-Dark' || true
    run_as_user gsettings set org.gnome.desktop.interface cursor-theme 'Qogirr-Dark' || true
    run_as_user gsettings set org.gnome.desktop.interface font-name 'Noto Sans 9' || true
    run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout ":" || true

    run_root chown -R "$TARGET_USER:$TARGET_USER" "$CONFIG_DIR" "$DATA_DIR" "$USER_HOME/.config-backups" "$USER_HOME/.gemini" "$USER_HOME/.local" || true

    set +x 2>/dev/null || true
    log_section "Installation & Configuration Complete!"
    echo -e "${GREEN}${BOLD}Your reproducible Arch Linux Hyprland setup is ready:${RESET}"
    echo -e "  ${CYAN}• Full Install Log           :${RESET} $LOG_FILE"
    echo -e "  ${CYAN}• Reboot into SDDM / Hyprland:${RESET} sudo reboot"
    echo -e "  ${CYAN}• Launch Hyprland from TTY   :${RESET} run-hyprland"
    echo -e "  ${CYAN}• Rollback / Clean Slate     :${RESET} $SRC_DIR/restore.sh"
    echo -e "  ${CYAN}• Boot Recovery Script       :${RESET} $USER_HOME/boot-recovery/recover-boot.sh"
    echo ""
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}║        IMPORTANT: MANUAL POST-INSTALL SENSITIVE SETUP        ║${RESET}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo -e "  Refer to ${BOLD}$SRC_DIR/README.md${RESET} for step-by-step instructions to manually configure:"
    echo -e "  ${YELLOW}1. SSH Keys & GitHub Auth :${RESET} ssh-keygen -t ed25519 / gh auth login"
    echo -e "  ${YELLOW}2. Git Global Identity    :${RESET} git config --global user.name & user.email"
    echo -e "  ${YELLOW}3. GPG Keys & API Tokens  :${RESET} Import sensitive keys & AI provider credentials"
    echo -e "  ${YELLOW}4. Antigravity Skills List:${RESET} Full inventory of your custom skills & plugins in README.md"
}

# ------------------------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------------------------
main() {
    echo -e "${CYAN}${BOLD}"
    echo " ╔═══════════════════════════════════════════════════════════╗"
    echo " ║   Arch Linux -> Aesthetic Hyprland Reproducible Builder   ║"
    echo " ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    log_info "Verbose logging active. All output is also saved to: $LOG_FILE"

    interactive_wizard

    # Enable automatic verbose command tracing for all installation steps
    export PS4=$'\033[2m+ [install:${FUNCNAME[0]:-main}:${LINENO}] \033[0m'
    set -x

    setup_user_account
    install_packages
    backup_existing
    install_assets
    deploy_dotfiles
    configure_system_and_services
    finalize_setup
}

main "$@"
