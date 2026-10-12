#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Hyprland Rice -> Rollback & "Clean Arch Slate" Restore Script
# ==============================================================================
# Provides two recovery modes:
#   1) Restore a pre-install configuration snapshot from ~/.config-backups/
#   2) Full "Clean Arch Slate" reset (wipes rice configs, session hooks, SDDM,
#      GRUB theme, and optionally purges desktop packages back to minimal Arch)
# ==============================================================================

set -Eeuo pipefail

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

LOG_FILE="/tmp/arch-hypr-restore-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

on_error() {
    local exit_code=$?
    local line_no=$1
    local func_name="${2:-main}"
    local cmd="$3"
    set +x 2>/dev/null || true
    echo -e "\n${RED}${BOLD}[✗] ERROR in restore.sh (${func_name} at line ${line_no}, exit code ${exit_code})${RESET}" >&2
    echo -e "${RED}${BOLD}    Failed command:${RESET} ${cmd}" >&2
    echo -e "${YELLOW}${BOLD}    Full log      :${RESET} ${LOG_FILE}\n" >&2
}
trap 'on_error $LINENO "${FUNCNAME[0]:-main}" "$BASH_COMMAND"' ERR

if [[ -e /dev/tty ]]; then
    exec </dev/tty
fi

run_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        if ! sudo -n true 2>/dev/null; then
            log_warn "Sudo privileges required — please type your sudo password:"
            sudo -v </dev/tty
        fi
        sudo "$@"
    fi
}

prompt_input() {
    local prompt_text="$1"
    local default_val="$2"
    local reply=""
    if [[ -e /dev/tty ]]; then
        read -r -p "$prompt_text" reply </dev/tty || true
    fi
    echo "${reply:-$default_val}"
}

prompt_yn() {
    local prompt_text="$1"
    local default_ans="${2:-N}"
    local hint="[y/N]"
    [[ "$default_ans" =~ ^[Yy]$ ]] && hint="[Y/n]"
    local reply=""
    if [[ -e /dev/tty ]]; then
        read -r -p "${prompt_text} ${hint}: " reply </dev/tty || true
    fi
    reply="${reply:-$default_ans}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Detect target user
DETECTED_USER="${SUDO_USER:-$(whoami)}"
[[ "$DETECTED_USER" == "root" ]] && DETECTED_USER="user"
TARGET_USER="$(prompt_input "Enter target username to restore/reset [${DETECTED_USER}]: " "$DETECTED_USER")"

if ! id "$TARGET_USER" &>/dev/null; then
    log_err "User '$TARGET_USER' does not exist on this system."
    exit 1
fi

USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
CONFIG_DIR="$USER_HOME/.config"
DATA_DIR="$USER_HOME/.local/share"
BACKUP_ROOT="$USER_HOME/.config-backups"

# ------------------------------------------------------------------------------
# Mode 1: Restore Pre-Install Snapshot
# ------------------------------------------------------------------------------
restore_snapshot() {
    log_section "Mode 1: Restore Pre-Install Snapshot"

    if [[ ! -d "$BACKUP_ROOT" ]]; then
        log_err "No backup directory found at $BACKUP_ROOT."
        exit 1
    fi

    mapfile -t backups < <(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort -r)
    if [[ ${#backups[@]} -eq 0 ]]; then
        log_err "No configuration snapshots found in $BACKUP_ROOT."
        exit 1
    fi

    echo "Available snapshots:"
    local i=1
    for b in "${backups[@]}"; do
        echo "  $i) $(basename "$b")"
        ((i++))
    done

    local choice
    choice="$(prompt_input "Select snapshot number [1-${#backups[@]}, default: 1]: " "1")"
    local idx=$((choice - 1))
    if [[ $idx -lt 0 || $idx -ge ${#backups[@]} ]]; then
        log_err "Invalid selection."
        exit 1
    fi

    local selected="${backups[$idx]}"
    log_info "Restoring from $selected (verbose log: $LOG_FILE)..."

    export PS4=$'\033[2m+ [restore:${FUNCNAME[0]:-main}:${LINENO}] \033[0m'
    set -x

    mkdir -p "$CONFIG_DIR"
    shopt -s dotglob nullglob
    for item in "$selected"/*; do
        local base
        base="$(basename "$item")"
        if [[ "$base" == ".zshrc" || "$base" == ".zprofile" || "$base" == ".gtkrc-2.0" ]]; then
            cp -ra "$item" "$USER_HOME/$base"
            log_info "Restored ~/$base"
        else
            rm -rf "${CONFIG_DIR:?}/$base"
            cp -ra "$item" "$CONFIG_DIR/$base"
            log_info "Restored ~/.config/$base"
        fi
    done
    shopt -u dotglob nullglob

    run_root chown -R "$TARGET_USER:$TARGET_USER" "$CONFIG_DIR" "$USER_HOME/.zshrc" "$USER_HOME/.zprofile" "$USER_HOME/.gtkrc-2.0" || true
    set +x 2>/dev/null || true
    log_success "Snapshot $(basename "$selected") restored successfully."
}

# ------------------------------------------------------------------------------
# Mode 2: Full "Clean Arch Slate" Reset
# ------------------------------------------------------------------------------
clean_arch_slate() {
    log_section "Mode 2: Full 'Clean Arch Slate' Reset"

    log_warn "This will remove all Hyprland rice configs, themes, session launchers,"
    log_warn "Pacman hooks, SDDM login manager config, and optionally desktop packages."
    if ! prompt_yn "Are you sure you want to reset '$TARGET_USER' to a Clean Arch Slate?" "N"; then
        log_info "Cancelled."
        exit 0
    fi

    export PS4=$'\033[2m+ [restore:${FUNCNAME[0]:-main}:${LINENO}] \033[0m'
    set -x

    # 1. Create final safety backup before wiping
    local safety_bk="$BACKUP_ROOT/pre-clean-slate-$(date +%Y%m%d-%H%M%S)"
    log_info "Saving safety backup to $safety_bk..."
    mkdir -p "$safety_bk"
    local rice_configs=(
        hypr hyprcat kitty alacritty waybar rofi mako wlogout wofi
        gtk-3.0 geany ncmpcpp ranger nvim yazi btop cava mpv
        qt5ct spicetify Thunar viewnior xarchiver fontconfig
    )
    for cfg in "${rice_configs[@]}"; do
        [[ -e "$CONFIG_DIR/$cfg" ]] && cp -ra "$CONFIG_DIR/$cfg" "$safety_bk/" || true
    done
    for dot in .zshrc .zprofile .gtkrc-2.0; do
        [[ -f "$USER_HOME/$dot" ]] && cp -ra "$USER_HOME/$dot" "$safety_bk/" || true
    done
    run_root chown -R "$TARGET_USER:$TARGET_USER" "$BACKUP_ROOT" || true

    # 2. Remove rice dotfiles & assets
    log_info "Removing deployed rice configurations from $CONFIG_DIR..."
    for cfg in "${rice_configs[@]}"; do
        rm -rf "${CONFIG_DIR:?}/$cfg"
    done
    rm -f "$CONFIG_DIR/environment.d/10-terminal.conf" "$CONFIG_DIR/xdg-terminals.list"
    rm -f "$USER_HOME/.gtkrc-2.0"
    rm -rf "$DATA_DIR/themes/Manhattan" "$DATA_DIR/themes/Catppuccin-Mocha" "$DATA_DIR/themes/White"
    rm -rf "$DATA_DIR/icons/Luv-Folders" "$DATA_DIR/icons/Luv-Folders-Dark" "$DATA_DIR/icons/Archcraft" "$DATA_DIR/icons/Archcraft-Dark"
    rm -rf "$DATA_DIR/icons/Qogirr" "$DATA_DIR/icons/Qogirr-Dark" "$DATA_DIR/icons/Sweet"

    # 3. Remove system session launchers & hooks
    log_info "Removing system session launchers and Pacman hooks..."
    run_root rm -f /usr/local/bin/run-hyprland /usr/local/bin/run-hyprland-cat
    run_root rm -f /usr/share/wayland-sessions/hyprland-cat.desktop
    run_root rm -f /etc/pacman.d/hooks/archcraft-hook-hyprland.hook /etc/pacman.d/hooks/archcraft-hook-hyprland-uwsm.hook

    # 4. Disable SDDM & revert SDDM config
    log_info "Disabling SDDM and reverting SDDM config (returning to clean TTY login)..."
    run_root systemctl disable sddm.service || true
    run_root rm -f /etc/sddm.conf /etc/sddm.conf.d/virtualkbd.conf

    # 5. Revert GRUB theme if present
    if [[ -f /etc/default/grub ]] && grep -q "Elegant-wave-window-right-dark" /etc/default/grub; then
        log_info "Reverting GRUB theme settings in /etc/default/grub..."
        run_root sed -i '/Elegant-wave-window-right-dark/d' /etc/default/grub
        if command -v grub-mkconfig &>/dev/null && [[ -d /boot/grub ]]; then
            run_root grub-mkconfig -o /boot/grub/grub.cfg || true
        fi
    fi

    set +x 2>/dev/null || true

    # 6. Optional shell reset to /bin/bash
    if prompt_yn "Reset '$TARGET_USER' default login shell back to /bin/bash (and remove ~/.zshrc)?" "Y"; then
        set -x
        run_root usermod -s /bin/bash "$TARGET_USER" || true
        rm -f "$USER_HOME/.zshrc" "$USER_HOME/.zprofile"
        rm -rf "$USER_HOME/.oh-my-zsh"
        set +x 2>/dev/null || true
        log_info "Shell reset to /bin/bash."
    fi

    # 7. Optional desktop package purge
    if prompt_yn "Also uninstall Hyprland & desktop rice packages to return to minimal base Arch?" "N"; then
        set -x
        log_info "Purging desktop and rice packages (preserving base Arch, kernel, bootloader, network, git, sudo)..."
        local pkgs_to_remove=(
            hyprland hyprlock hypridle hyprpaper hyprpicker hyprsunset uwsm
            waybar rofi wofi mako wlogout sddm sddm-theme-corners-git sddm-astronaut-theme
            kitty alacritty foot thunar thunar-archive-plugin thunar-volman
            tumbler file-roller xarchiver viewnior geany ranger
            grim slurp swappy wf-recorder cliphist python-pywal pastel
            lxappearance xfce4-settings materia-gtk-theme
            cava fastfetch yazi zathura zathura-pdf-mupdf
            spotify spicetify-cli easyeffects calf mpd mpc ncmpcpp
            localsend-bin linutil
        )
        local installed_to_remove=()
        for pkg in "${pkgs_to_remove[@]}"; do
            if pacman -Qi "$pkg" &>/dev/null; then
                installed_to_remove+=("$pkg")
            fi
        done
        if [[ ${#installed_to_remove[@]} -gt 0 ]]; then
            run_root pacman -Rns --noconfirm "${installed_to_remove[@]}" || log_warn "Some packages had dependents; removing with -Rdd or skipping."
        fi
        set +x 2>/dev/null || true
    fi

    log_section "Clean Arch Slate Restoration Complete!"
    echo -e "  ${CYAN}• Safety backup saved at:${RESET} $safety_bk"
    echo -e "  ${CYAN}• Full Restore Log      :${RESET} $LOG_FILE"
    echo -e "  ${CYAN}• Reboot to clean TTY   :${RESET} sudo reboot"
}

# ------------------------------------------------------------------------------
# Main Menu
# ------------------------------------------------------------------------------
main() {
    echo -e "${CYAN}${BOLD}"
    echo " ╔═══════════════════════════════════════════════════════════╗"
    echo " ║     Arch Linux Hyprland Rice -> Restore & Reset Utility   ║"
    echo " ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    log_info "Verbose logging active. All output is also saved to: $LOG_FILE"

    echo "Select recovery mode:"
    echo "  1) Restore Pre-Install Snapshot (from ~/.config-backups/)"
    echo "  2) Full 'Clean Arch Slate' Reset (remove rice configs, SDDM, hooks, optional packages)"
    echo "  3) Exit"
    echo ""

    local mode
    mode="$(prompt_input "Choose an option [1-3, default: 1]: " "1")"
    case "$mode" in
        1) restore_snapshot ;;
        2) clean_arch_slate ;;
        *) log_info "Exiting."; exit 0 ;;
    esac
}

main "$@"
