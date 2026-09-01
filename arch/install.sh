#!/usr/bin/env bash
# ==============================================================================
# Arch Linux -> Aesthetic Hyprland Rice Installer & Tinkering Script
# ==============================================================================
# Works with the hyprlandConfig bundle (Archcraft / Hyprland Rice)
# Transforms a barebone Arch Linux installation into a fully configured desktop.
# ==============================================================================

set -euo pipefail

# Text styling
BOLD="$(tput bold 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
BLUE="$(tput setaf 4 2>/dev/null || echo '')"
CYAN="$(tput setaf 6 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
RED="$(tput setaf 1 2>/dev/null || echo '')"
RESET="$(tput sgr0 2>/dev/null || echo '')"

log_info()    { echo -e "${BLUE}${BOLD}[*]${RESET} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[✓]${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $1"; }
log_err()     { echo -e "${RED}${BOLD}[✗]${RESET} $1"; }
log_section() { echo -e "\n${CYAN}${BOLD}=== $1 ===${RESET}\n"; }

# ------------------------------------------------------------------------------
# 0. Configuration & Path Detection
# ------------------------------------------------------------------------------
CURRENT_USER="${SUDO_USER:-$(whoami)}"
USER_HOME=$(getent passwd "$CURRENT_USER" | cut -d: -f6)
CONFIG_DIR="$USER_HOME/.config"
DATA_DIR="$USER_HOME/.local/share"
BACKUP_DIR="$USER_HOME/.config-backups/hypr-rice-$(date +%Y%m%d-%H%M%S)"

# Locate hyprlandConfig folder
find_config_source() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local candidates=(
        "$script_dir"
        "$PWD"
        "$USER_HOME/Downloads/hyprlandConfig"
        "/downloads/hyprlandConfig"
        "$USER_HOME/hyprlandConfig"
        "/tmp/hyprlandConfig"
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
    log_err "Could not find valid 'hyprlandConfig' directory."
    log_warn "Please run this script from inside the hyprlandConfig directory or place it at ~/Downloads/hyprlandConfig"
    exit 1
fi

log_info "Using hyprlandConfig source from: ${BOLD}$SRC_DIR${RESET}"
log_info "Target user: ${BOLD}$CURRENT_USER${RESET} (Home: $USER_HOME)"

# ------------------------------------------------------------------------------
# 1. Package Management & Dependencies
# ------------------------------------------------------------------------------
PACMAN_DEPS=(
    # Base Wayland & Hyprland
    hyprland hyprlock hypridle hyprpaper hyprpicker hyprsunset xorg-xwayland
    xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    xdg-user-dirs xdg-utils qt5-wayland qt6-wayland qt5ct

    # Status Bar, Launchers, UI & Notifications
    waybar rofi wofi mako yad libnotify
    polkit-gnome polkit-kde-agent

    # Audio & Media
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
    pavucontrol pulsemixer pamixer mpd mpc mpv

    # Terminals & File Management
    kitty alacritty foot thunar thunar-archive-plugin thunar-volman
    tumbler file-roller xarchiver viewnior geany

    # Screenshots, Wallpaper & Theming Tools
    grim slurp swappy imagemagick wl-clipboard wf-recorder
    python-pywal brightnessctl light pastel fastfetch btop

    # Network & Bluetooth
    networkmanager network-manager-applet bluez bluez-utils blueman

    # Fonts & Base System
    noto-fonts noto-fonts-emoji ttf-jetbrains-mono ttf-jetbrains-mono-nerd
    ttf-nerd-fonts-symbols otf-font-awesome
)

AUR_DEPS=(
    wlogout
    sddm-astronaut-theme
)

install_packages() {
    log_section "Step 1: Installing Required Packages"

    log_info "Updating pacman repositories..."
    sudo pacman -Sy --needed --noconfirm "${PACMAN_DEPS[@]}"

    # Detect or install AUR helper
    local aur_helper=""
    if command -v paru &>/dev/null; then
        aur_helper="paru"
    elif command -v yay &>/dev/null; then
        aur_helper="yay"
    else
        log_warn "No AUR helper found. Installing yay-bin..."
        local tmp_dir
        tmp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin"
        (cd "$tmp_dir/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp_dir"
        aur_helper="yay"
    fi

    log_info "Installing AUR dependencies using $aur_helper..."
    $aur_helper -S --needed --noconfirm "${AUR_DEPS[@]}" || log_warn "Some AUR packages failed to install, proceeding..."

    log_success "Packages installed successfully."
}

# ------------------------------------------------------------------------------
# 2. Backup Existing Configurations
# ------------------------------------------------------------------------------
backup_existing() {
    log_section "Step 2: Backing Up Existing Configurations"
    mkdir -p "$BACKUP_DIR"

    local items_to_backup=(
        "$CONFIG_DIR/hypr"
        "$CONFIG_DIR/hyprcat"
        "$CONFIG_DIR/kitty"
        "$CONFIG_DIR/alacritty"
        "$CONFIG_DIR/waybar"
        "$CONFIG_DIR/rofi"
        "$CONFIG_DIR/mako"
        "$CONFIG_DIR/wlogout"
        "$CONFIG_DIR/wofi"
        "$CONFIG_DIR/gtk-3.0"
        "$CONFIG_DIR/ncmpcpp"
        "$CONFIG_DIR/ranger"
        "$CONFIG_DIR/geany"
    )

    for item in "${items_to_backup[@]}"; do
        if [[ -e "$item" ]]; then
            log_info "Backing up $(basename "$item") to $BACKUP_DIR"
            cp -ra "$item" "$BACKUP_DIR/"
        fi
    done

    log_success "Backup saved in: $BACKUP_DIR"
}

# ------------------------------------------------------------------------------
# 3. Installing Fonts, GTK Themes, Icons & Cursors
# ------------------------------------------------------------------------------
install_assets() {
    log_section "Step 3: Installing Fonts, GTK Themes, Icons & Cursors"

    # 1. Fonts
    log_info "Installing fonts into $DATA_DIR/fonts..."
    mkdir -p "$DATA_DIR/fonts"
    cp -rf "$SRC_DIR/fonts"/* "$DATA_DIR/fonts/"
    log_info "Updating font cache..."
    fc-cache -fv >/dev/null 2>&1

    # 2. GTK Themes
    log_info "Installing GTK themes into $DATA_DIR/themes..."
    mkdir -p "$DATA_DIR/themes"
    cp -rf "$SRC_DIR/gtk/theme"/* "$DATA_DIR/themes/"

    # 3. Icons & Cursors
    log_info "Installing Icons & Cursors into $DATA_DIR/icons..."
    mkdir -p "$DATA_DIR/icons"
    cp -rf "$SRC_DIR/gtk/icons"/* "$DATA_DIR/icons/"
    cp -rf "$SRC_DIR/gtk/cursor"/* "$DATA_DIR/icons/"

    log_success "Fonts, GTK themes, and icons installed."
}

# ------------------------------------------------------------------------------
# 4. Deploying Dotfiles
# ------------------------------------------------------------------------------
deploy_dotfiles() {
    log_section "Step 4: Deploying Desktop Configurations"

    mkdir -p "$CONFIG_DIR"

    # Deploy hypr & hyprcat
    log_info "Deploying ~/.config/hypr and ~/.config/hyprcat..."
    cp -rf "$SRC_DIR/dotfiles/hypr" "$CONFIG_DIR/"
    cp -rf "$SRC_DIR/dotfiles/hyprcat" "$CONFIG_DIR/"

    # Deploy terminals config
    log_info "Setting up terminal configs (Kitty, Alacritty, Foot)..."
    mkdir -p "$CONFIG_DIR/kitty" "$CONFIG_DIR/alacritty"
    
    # Kitty configuration
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

    # Alacritty configuration
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

    # Deploy misc app configs (gtk-3.0, geany, ncmpcpp, ranger)
    log_info "Deploying GTK3, Geany, Ncmpcpp, Ranger configs..."
    mkdir -p "$CONFIG_DIR/gtk-3.0" "$CONFIG_DIR/geany" "$CONFIG_DIR/ncmpcpp" "$CONFIG_DIR/ranger"
    
    [[ -f "$SRC_DIR/misc/gtk-3.0/gtk.css" ]] && cp -f "$SRC_DIR/misc/gtk-3.0/gtk.css" "$CONFIG_DIR/gtk-3.0/"
    [[ -d "$SRC_DIR/misc/geany" ]] && cp -rf "$SRC_DIR/misc/geany"/* "$CONFIG_DIR/geany/"
    [[ -d "$SRC_DIR/misc/ncmpcpp" ]] && cp -rf "$SRC_DIR/misc/ncmpcpp"/* "$CONFIG_DIR/ncmpcpp/"
    [[ -d "$SRC_DIR/misc/ranger" ]] && cp -rf "$SRC_DIR/misc/ranger"/* "$CONFIG_DIR/ranger/"

    # Environment variables for terminals/apps
    mkdir -p "$CONFIG_DIR/environment.d"
    cat > "$CONFIG_DIR/environment.d/10-terminal.conf" << 'EOF'
TERMINAL=kitty
BROWSER=firefox
EDITOR=nvim
VISUAL=nvim
EOF

    # Ensure scripts have execute permissions
    chmod +x "$CONFIG_DIR"/hypr/scripts/* "$CONFIG_DIR"/hyprcat/scripts/* "$CONFIG_DIR"/hypr/theme/theme.sh "$CONFIG_DIR"/hyprcat/theme/theme.sh 2>/dev/null || true

    log_success "Dotfiles deployed."
}

# ------------------------------------------------------------------------------
# 5. Applying Hyprland Modern Syntax Fixes & Quality of Life Tweaks
# ------------------------------------------------------------------------------
apply_tweaks_and_fixes() {
    log_section "Step 5: Applying Modern Hyprland Fixes & Tweaks"

    # Fix 1: Deprecated options in 02-decoration.conf, 09-misc.conf, 30-layout-dwindle.conf
    local HYPR_DIR="$CONFIG_DIR/hypr"
    
    # Remove deprecated shadow ignore_window
    sed -i '/ignore_window[[:space:]]*=[[:space:]]*true/d' "$HYPR_DIR/config.d/02-decoration.conf" 2>/dev/null || true
    # Remove deprecated vfr/cm_fs_passthrough
    sed -i '/vfr[[:space:]]*=[[:space:]]*true/d' "$HYPR_DIR/config.d/09-misc.conf" 2>/dev/null || true
    sed -i '/cm_fs_passthrough/d' "$HYPR_DIR/config.d/09-misc.conf" 2>/dev/null || true
    # Remove pseudotile and obsolete aspect ratio lines
    sed -i '/pseudotile/d' "$HYPR_DIR/config.d/30-layout-dwindle.conf" 2>/dev/null || true
    sed -i '/single_window_aspect_ratio/d' "$HYPR_DIR/config.d/30-layout-dwindle.conf" 2>/dev/null || true

    # Fix 2: Enable rofi toggling in all scripts so pressing hotkey toggles menu
    local rofi_scripts=(
        "$HYPR_DIR/scripts/rofi_launcher"
        "$HYPR_DIR/scripts/rofi_runner"
        "$HYPR_DIR/scripts/rofi_powermenu"
        "$HYPR_DIR/scripts/rofi_screenshot"
        "$HYPR_DIR/scripts/rofi_bluetooth"
        "$HYPR_DIR/scripts/rofi_mpd"
        "$HYPR_DIR/scripts/rofi_spotify"
        "$HYPR_DIR/scripts/rofi_asroot"
    )

    for script in "${rofi_scripts[@]}"; do
        if [[ -f "$script" ]] && ! grep -q 'pgrep -x "rofi"' "$script"; then
            sed -i '2i\
# Toggle rofi if already open\
if pgrep -x "rofi" >/dev/null; then\
\tpkill -x "rofi"\
\texit 0\
fi\
' "$script"
        fi
    done

    # Fix 3: Add keyboard backlight script if missing
    if [[ ! -f "$HYPR_DIR/scripts/kbd_backlight" ]]; then
        cat > "$HYPR_DIR/scripts/kbd_backlight" << 'EOF'
#!/usr/bin/env bash
iDIR="$HOME/.config/hypr/mako/icons"
KBD_PATH=$(ls -d /sys/class/leds/*::kbd_backlight 2>/dev/null | head -n 1 || true)
if [[ -z "$KBD_PATH" ]]; then exit 0; fi

get_backlight() { cat "$KBD_PATH/brightness"; }
get_max_backlight() { cat "$KBD_PATH/max_brightness"; }
get_icon() {
	backlight=$(get_backlight)
	if [[ "$backlight" -eq 0 ]]; then icon="$iDIR"/brightness-20.png; else icon="$iDIR"/brightness-60.png; fi
}
notify_user() { notify-send -h string:x-canonical-private-synchronous:sys-notify-backlight -u low -i "$icon" "Keyboard Brightness : $(get_backlight)"; }
inc_backlight() {
	backlight=$(get_backlight); max=$(get_max_backlight); new=$(( backlight + 1 ))
	[[ "$new" -gt "$max" ]] && new="$max"
	echo "$new" > "$KBD_PATH/brightness"
	get_icon && notify_user
}
dec_backlight() {
	backlight=$(get_backlight); new=$(( backlight - 1 ))
	[[ "$new" -lt 0 ]] && new=0
	echo "$new" > "$KBD_PATH/brightness"
	get_icon && notify_user
}
if [[ "$1" == '--inc' ]]; then inc_backlight; elif [[ "$1" == '--dec' ]]; then dec_backlight; else get_backlight; fi
EOF
        chmod +x "$HYPR_DIR/scripts/kbd_backlight"
    fi

    # Fix 4: Set default terminal to Kitty in 60-key-bindings.conf
    sed -i 's/^bind = SUPER,       Return, exec, $alacritty/#bind = SUPER,       Return, exec, $alacritty/' "$HYPR_DIR/config.d/60-key-bindings.conf" 2>/dev/null || true
    sed -i 's/^#bind = SUPER,       Return, exec, $kitty/bind = SUPER,       Return, exec, $kitty/' "$HYPR_DIR/config.d/60-key-bindings.conf" 2>/dev/null || true
    sed -i 's/^#bind = SUPER_SHIFT, Return, exec, $kitty -f/bind = SUPER_SHIFT, Return, exec, $kitty -f/' "$HYPR_DIR/config.d/60-key-bindings.conf" 2>/dev/null || true
    sed -i 's/^#bind = SUPER_ALT,   Return, exec, $kitty -F/bind = SUPER_ALT,   Return, exec, $kitty -F/' "$HYPR_DIR/config.d/60-key-bindings.conf" 2>/dev/null || true

    log_success "Tweaks and fixes applied."
}

# ------------------------------------------------------------------------------
# 6. System Session Files & Pacman Hooks
# ------------------------------------------------------------------------------
install_system_files() {
    log_section "Step 6: Installing System Session Launchers & Hooks"

    local MISC_DIR="$SRC_DIR/misc"

    # Install session launch scripts
    log_info "Installing run-hyprland to /usr/local/bin..."
    sudo cp -f "$MISC_DIR/run-hyprland" /usr/local/bin/run-hyprland
    sudo cp -f "$MISC_DIR/run-hyprland-cat" /usr/local/bin/run-hyprland-cat
    sudo chmod +x /usr/local/bin/run-hyprland /usr/local/bin/run-hyprland-cat

    # Install Wayland session desktop entries
    log_info "Installing wayland session files to /usr/share/wayland-sessions..."
    sudo mkdir -p /usr/share/wayland-sessions
    sudo cp -f "$MISC_DIR/hyprland-cat.desktop" /usr/share/wayland-sessions/hyprland-cat.desktop
    
    if [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
        sudo sed -i -e 's/^Exec=.*/Exec=run-hyprland/' /usr/share/wayland-sessions/hyprland.desktop
    else
        sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=run-hyprland
Type=Application
DesktopNames=Hyprland
Keywords=tiling;wayland;compositor;
EOF
    fi

    # Install Pacman hooks
    log_info "Installing Pacman hooks to /etc/pacman.d/hooks..."
    sudo mkdir -p /etc/pacman.d/hooks
    sudo cp -f "$MISC_DIR/archcraft-hook-hyprland.hook" /etc/pacman.d/hooks/
    sudo cp -f "$MISC_DIR/archcraft-hook-hyprland-uwsm.hook" /etc/pacman.d/hooks/

    log_success "System session files and hooks installed."
}

# ------------------------------------------------------------------------------
# 7. SDDM Display Manager & System Services
# ------------------------------------------------------------------------------
configure_services() {
    log_section "Step 7: Configuring Display Manager & System Services"

    # Configure SDDM
    log_info "Configuring SDDM Theme (sddm-astronaut-theme)..."
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf > /dev/null << 'EOF'
[Theme]
    Current=sddm-astronaut-theme
[General]
    InputMethod=qtvirtualkeyboard
EOF

    sudo tee /etc/sddm.conf.d/virtualkbd.conf > /dev/null << 'EOF'
[General]
    InputMethod=qtvirtualkeyboard
EOF

    # Add user to required groups
    log_info "Adding user '$CURRENT_USER' to video, input, and seat groups..."
    sudo usermod -aG video,input "$CURRENT_USER" 2>/dev/null || true

    # Enable essential services
    log_info "Enabling systemd services (sddm, NetworkManager, bluetooth)..."
    sudo systemctl enable sddm.service || true
    sudo systemctl enable NetworkManager.service || true
    sudo systemctl enable bluetooth.service || true

    log_success "Display manager and services configured."
}

# ------------------------------------------------------------------------------
# 8. Permissions & Initial Theme Generation
# ------------------------------------------------------------------------------
finalize_setup() {
    log_section "Step 8: Finalizing Permissions & Initial Theme"

    # Fix ownership of user files
    log_info "Fixing file ownership for $CURRENT_USER..."
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$CONFIG_DIR" "$DATA_DIR" "$USER_HOME/.config-backups" 2>/dev/null || true

    # Initialize Default Theme
    log_info "Applying default theme via theme.sh..."
    if [[ -x "$CONFIG_DIR/hypr/theme/theme.sh" ]]; then
        bash "$CONFIG_DIR/hypr/theme/theme.sh" --default || true
    fi

    # Set initial GTK settings
    gsettings set org.gnome.desktop.interface gtk-theme 'Manhattan' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Luv-Folders-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Qogirr-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'Noto Sans 9' 2>/dev/null || true
    gsettings set org.gnome.desktop.wm.preferences button-layout ":" 2>/dev/null || true

    log_section "🎉 Installation & Configuration Complete!"
    echo -e "${GREEN}${BOLD}You can now reboot your machine into Hyprland or start it immediately:${RESET}"
    echo -e "  ${CYAN}• Reboot System:${RESET} sudo reboot"
    echo -e "  ${CYAN}• Or Launch Hyprland:${RESET} run-hyprland"
}

# ------------------------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------------------------
main() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo " ╔═══════════════════════════════════════════════════════════╗"
    echo " ║     Arch Linux -> Aesthetic Hyprland Rice Setup Script    ║"
    echo " ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"

    install_packages
    backup_existing
    install_assets
    deploy_dotfiles
    apply_tweaks_and_fixes
    install_system_files
    configure_services
    finalize_setup
}

main "$@"
