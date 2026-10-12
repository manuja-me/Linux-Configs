#!/usr/bin/env bash
# ==============================================================================
# Arch Linux TTY Cloud Bootstrapper (1-Command curl | sh Entrypoint)
# ==============================================================================
# Usage from fresh minimal Arch Linux TTY:
#   curl -fsSL https://raw.githubusercontent.com/manuja-me/nixos-config/main/arch/bootstrap.sh | bash
# ==============================================================================

set -Eeuo pipefail

# Attach stdin to /dev/tty immediately so sudo/su/interactive prompts work when piped via curl | bash
if [[ -e /dev/tty ]]; then
    exec </dev/tty
fi

REPO_URL="${REPO_URL:-https://github.com/manuja-me/nixos-config.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"

BOLD="\033[1m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info() { printf "${CYAN}${BOLD}[*]${RESET} %s\n" "$1"; }
ok()   { printf "${GREEN}${BOLD}[✓]${RESET} %s\n" "$1"; }
warn() { printf "${YELLOW}${BOLD}[!]${RESET} %s\n" "$1"; }
err()  { printf "${RED}${BOLD}[✗]${RESET} %s\n" "$1" >&2; exit 1; }

on_error() {
    local exit_code=$?
    local line_no=$1
    local cmd=$2
    set +x 2>/dev/null || true
    printf "\n${RED}${BOLD}[✗] ERROR in bootstrap.sh at line %s (exit code %s)${RESET}\n" "$line_no" "$exit_code" >&2
    printf "${RED}${BOLD}    Failed command:${RESET} %s\n\n" "$cmd" >&2
}
trap 'on_error $LINENO "$BASH_COMMAND"' ERR

run_priv() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif command -v sudo &>/dev/null; then
        if ! sudo -n true 2>/dev/null; then
            warn "Sudo privileges required — please enter your sudo password:"
            if ! sudo -v </dev/tty; then
                warn "Sudo authentication failed or user not in sudoers. Falling back to root (su):"
                su -c "$(printf '%q ' "$@")" </dev/tty
                return $?
            fi
        fi
        sudo "$@"
    else
        warn "Root privileges required — please enter root password:"
        su -c "$(printf '%q ' "$@")" </dev/tty
    fi
}

printf "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}\n"
printf "${CYAN}${BOLD}║     Arch Linux Reproducible Setup — Cloud TTY Bootstrap      ║${RESET}\n"
printf "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}\n\n"

# Enable verbose command trace by default so all operations & errors are visible
export PS4=$'\033[2m+ [bootstrap:${LINENO}] \033[0m'
set -x

# 1. Verify Arch Linux environment
[[ -f /etc/arch-release ]] || err "This bootstrapper requires Arch Linux (/etc/arch-release not found)."

# 2. Check network connectivity (verbose error output enabled)
info "Checking internet connectivity..."
if ! curl -fIS --show-error --max-time 10 https://github.com >/dev/null; then
    err "No internet connection detected. Configure Wi-Fi/Ethernet first (e.g. 'nmtui' or 'iwctl')."
fi
ok "Internet connection verified."

# 3. Install bootstrap prerequisites
info "Ensuring git, base-devel, curl, sudo, and rsync are installed..."
run_priv pacman -Sy --needed --noconfirm git base-devel curl sudo rsync

# 4. Determine target clone location
if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]]; then
    TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    TARGET_HOME="${HOME:-/root}"
fi
CLONE_DIR="${CLONE_DIR:-${TARGET_HOME}/nixos-config}"

# 5. Clone or update repository
if [[ -d "${CLONE_DIR}/.git" ]]; then
    info "Existing repository found at ${CLONE_DIR}. Pulling latest changes..."
    git -C "${CLONE_DIR}" fetch --verbose origin "${REPO_BRANCH}"
    git -C "${CLONE_DIR}" checkout "${REPO_BRANCH}"
    git -C "${CLONE_DIR}" pull --verbose --ff-only origin "${REPO_BRANCH}" || warn "Could not fast-forward; using current checkout."
else
    info "Cloning ${REPO_URL} into ${CLONE_DIR}..."
    git clone --verbose --branch "${REPO_BRANCH}" "${REPO_URL}" "${CLONE_DIR}"
fi
ok "Repository ready at ${CLONE_DIR}."

chmod -v +x "${CLONE_DIR}/arch/install.sh" "${CLONE_DIR}/arch/restore.sh" "${CLONE_DIR}/arch/setup-antigravity.sh" "${CLONE_DIR}/arch/sync-from-live.sh"

# 6. Hand off to interactive installer with /dev/tty attached for stdin
set +x
info "Launching interactive Arch installer..."
if [[ -e /dev/tty ]]; then
    bash "${CLONE_DIR}/arch/install.sh" "$@" </dev/tty
else
    bash "${CLONE_DIR}/arch/install.sh" "$@"
fi
