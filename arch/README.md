# Barebone Arch Linux to Aesthetic Hyprland Rice: Master Guide

This guide walks you through transforming a **fresh barebone Arch Linux installation** into this exact, fully customized, aesthetically riced **Hyprland** desktop environment using your `hyprlandConfig` bundle.

---

## 🏗️ Architecture of the Rice

| Component | Software Used | Purpose |
| :--- | :--- | :--- |
| **Compositor** | `hyprland` (with `uwsm` / `start-hyprland`) | Dynamic tiling Wayland compositor |
| **Status Bar** | `waybar` (managed via `systemd --user`) | Top status bar with system stats, audio, network, battery, theme switcher & auto-restart |
| **App Launcher & Menus** | `rofi` (Wayland fork) + `wofi` | App launcher, powermenu, screenshot menu, network menu, bluetooth menu |
| **Terminals** | `kitty` (primary default), `alacritty`, `foot` | GPU-accelerated terminal emulators styled with rice colors |
| **Notifications** | `mako` | Lightweight Wayland notification daemon with custom icons & urgency colors |
| **Lock Screen & Idle** | `hyprlock` & `hypridle` | Fast, styled Wayland lock screen with blurred wallpaper |
| **Session Control** | `wlogout` | Aesthetic logout / lock / shutdown / reboot splash menu |
| **Dynamic Theming** | `pastel` + `python-pywal` + custom `theme.sh` | On-the-fly theme switching (Dark, Light, Catppuccin, Pywal wallpaper-adaptive) |
| **Display Manager & Boot** | `sddm` (`corners` / `sddm-astronaut-theme`) + `grub` (`Elegant-wave-window-right-dark`) | Custom Catppuccin Mocha SDDM login & themed GRUB2 dual-boot menu |
| **GTK, Qt & Icons** | `Manhattan` / `Catppuccin-Mocha`, `Luv-Folders-Dark`, `Qogirr-Dark`, `qt5ct` | Unified dark/light theme consistency across GTK2/3/4 and Qt apps |
| **Shell & TUI Suite** | `zsh` (`Oh-My-Zsh`), `neovim` (`Kickstart Neovim`), `yazi`, `btop`, `cava`, `fastfetch`, `zathura` | Full terminal productivity and media workflow |
| **Power & Refresh Rate** | `auto_refresh.sh` (`udevadm` power monitor) | Automatically switches refresh rate between 144Hz (AC) and 60Hz (Battery) |
| **Sinhala Typography** | `fontconfig` (`fonts.conf`) | Screen-optimized Sinhala typography with Yaldevi SemiBold & Abhaya Libre SemiBold fallbacks |

---

## ⚡ Quick Start: 1-Command TTY Cloud Bootstrap (`curl | bash`)

From a **fresh minimal Arch Linux TTY** (logged in as `root` or your user with network connected):

```bash
curl -fsSL https://raw.githubusercontent.com/manuja-me/Linux-Configs/main/arch/bootstrap.sh | bash
```

### Order of Execution on a Fresh Minimal Arch Build:
1. **Install Minimal Base Arch**: Boot Arch ISO → run `archinstall` (select `Minimal` profile, `NetworkManager`, `grub` bootloader) → reboot into fresh TTY.
2. **Connect Network (if using Wi-Fi)**: Run `nmtui` or `nmcli device wifi connect <SSID> password <PASS>`.
3. **Run Cloud Bootstrap Command**: Execute the `curl ... | bash` command above.
   - `bootstrap.sh` attaches `/dev/tty` for interactive password/prompt input, installs `git`, `base-devel`, `curl`, `sudo`, `rsync`, clones `manuja-me/Linux-Configs` into `~/nixos-config`, and launches `arch/install.sh`.
4. **Answer Interactive Prompts & Sudo Password**:
   - **Target Username**: Uses your current user or creates a new user account (`wheel`, `video`, `input` groups + sudo access). Prompts for your `sudo` (or `root` via `su`) password whenever privileges are needed along the way.
   - **GPU Drivers**: Choose `1) Intel`, `2) AMD`, `3) NVIDIA`, or `4) VM/Skip`.
   - **SDDM & GRUB Themes**: Choose `Corners` (Catppuccin Mocha) or `Astronaut`, and toggle the `Elegant-wave-window-right-dark` GRUB theme.
   - **Optional Feature Bundles**: Toggle Shell/TUI (`zsh`, `nvim`/Kickstart, `yazi`, `btop`, `cava`), Media (`spotify`, `spicetify`, `easyeffects`, `mpv`), Extra Desktop Apps (`firefox`, `chromium`, `localsend`, `timeshift`), KVM/QEMU Virtualization, and Google Antigravity AI Suite.
5. **Automatic Verbose Execution & Error Diagnostics**:
   - All scripts (`bootstrap.sh`, `install.sh`, `restore.sh`) run in **automatic verbose mode (`set -x`)**, printing every command with `[script:function:line]` prefixes in real time and streaming full output to `/tmp/arch-hypr-install-<timestamp>.log`.
   - If any step fails, an `ERR` trap immediately prints the exact failing function, line number, exit code, failed command, log path, and rollback command (`./restore.sh`).
6. **Reboot**: Run `sudo reboot` to boot directly into themed GRUB → SDDM → Hyprland.

> **Unattended Mode**: To skip all prompts and install everything with default live-system settings:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/manuja-me/Linux-Configs/main/arch/bootstrap.sh | bash -s -- --defaults
> ```

---

## 🔄 Rollback, Clean Arch Slate & Live Sync Utilities

| Script | Command | Description |
| :--- | :--- | :--- |
| **Restore / Clean Slate** | `./restore.sh` | Interactive recovery tool (logged to `/tmp/arch-hypr-restore-<timestamp>.log`): **Mode 1** restores any pre-install snapshot from `~/.config-backups/`; **Mode 2** wipes all rice configs, hooks, SDDM/GRUB themes, and optionally purges desktop packages back to a **Clean Arch Slate**. |
| **Sync Live Changes** | `./sync-from-live.sh` | Copies your latest live `~/.config/*`, `~/.zshrc`, SDDM, and GRUB themes back into `arch/` so you can commit and push updates to GitHub. |
| **Bootloader Recovery** | `sudo ./boot-recovery/recover-boot.sh` | Run from an Arch Live USB to repair EFI/GRUB & Windows dual-boot entries. |

---

## 📋 Complete Step-by-Step Manual Guide

If you are starting from a raw, freshly installed Arch Linux system (from `archinstall` or manual bootstrap), follow these detailed steps.

---

### Step 1: Base System Prerequisites & GPU Drivers

Ensure your network, audio, Bluetooth, and GPU drivers are installed and active.

#### 1.1 GPU Drivers
```bash
# For Intel Graphics:
sudo pacman -S --needed mesa vulkan-intel intel-media-driver libva-intel-driver

# For AMD Graphics:
sudo pacman -S --needed mesa vulkan-radeon libva-mesa-driver

# For NVIDIA Graphics (refer to NVIDIA section below for Wayland env vars):
sudo pacman -S --needed nvidia-dkms nvidia-utils libva-nvidia-driver
```

#### 1.2 PipeWire Audio System
```bash
sudo pacman -S --needed pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol pulsemixer pamixer
systemctl --user enable --now pipewire wireplumber pipewire-pulse
```

#### 1.3 Bluetooth & Network
```bash
sudo pacman -S --needed networkmanager network-manager-applet bluez bluez-utils blueman
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
```

#### 1.4 User Permissions
Ensure your user belongs to `video`, `input`, and `seat` groups to control screen brightness and input devices:
```bash
sudo usermod -aG video,input $USER
```

---

### Step 2: Install AUR Helper (`yay` or `paru`)

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
cd /tmp/yay-bin && makepkg -si --noconfirm
cd ~ && rm -rf /tmp/yay-bin
```

---

### Step 3: Install Core Desktop Packages

```bash
# Official Packages
sudo pacman -S --needed \
    hyprland hyprlock hypridle hyprpaper hyprpicker hyprsunset xorg-xwayland \
    xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    xdg-user-dirs xdg-utils qt5-wayland qt6-wayland qt5ct \
    waybar rofi wofi mako yad libnotify \
    polkit-gnome polkit-kde-agent \
    kitty alacritty foot thunar thunar-archive-plugin thunar-volman \
    tumbler file-roller xarchiver viewnior geany mpd mpc mpv \
    grim slurp swappy imagemagick wl-clipboard wf-recorder \
    python-pywal brightnessctl light pastel fastfetch btop \
    noto-fonts noto-fonts-emoji ttf-jetbrains-mono ttf-jetbrains-mono-nerd \
    ttf-nerd-fonts-symbols otf-font-awesome sddm

# AUR Packages
yay -S --needed wlogout sddm-astronaut-theme
```

---

### Step 4: Installing Fonts, GTK Themes, Icons & Cursors

Navigate to your `arch/` directory inside the cloned repo:

```bash
SRC="$HOME/nixos-config/arch"

# 1. Fonts
mkdir -p ~/.local/share/fonts
cp -rf "$SRC/fonts"/* ~/.local/share/fonts/
fc-cache -fv

# 2. GTK Themes (Catppuccin-Mocha, Manhattan, White)
mkdir -p ~/.local/share/themes
cp -rf "$SRC/gtk/theme"/* ~/.local/share/themes/

# 3. Icons and Cursors (Archcraft, Luv-Folders, Qogirr, Sweet)
mkdir -p ~/.local/share/icons
cp -rf "$SRC/gtk/icons"/* ~/.local/share/icons/
cp -rf "$SRC/gtk/cursor"/* ~/.local/share/icons/
```

---

### Step 5: Deploying Configurations (`dotfiles`)

```bash
mkdir -p ~/.config

# 1. Main Hyprland & Hyprcat configs
cp -rf "$SRC/dotfiles/hypr" ~/.config/
cp -rf "$SRC/dotfiles/hyprcat" ~/.config/

# 2. Terminals (Kitty & Alacritty)
mkdir -p ~/.config/kitty ~/.config/alacritty

cat > ~/.config/kitty/kitty.conf << 'EOF'
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

cat > ~/.config/alacritty/alacritty.toml << 'EOF'
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

# 3. Editor, TUI & Desktop App Configs (Kickstart Neovim, yazi, btop, cava, mpv, qt5ct, spicetify, Thunar, viewnior, xarchiver, fontconfig)
for app in nvim yazi btop cava mpv qt5ct spicetify Thunar viewnior xarchiver fontconfig; do
    mkdir -p ~/.config/"$app"
    cp -rf "$SRC/dotfiles/$app"/. ~/.config/"$app"/
done

# 4. Zsh & Oh-My-Zsh Config
cp -f "$SRC/dotfiles/zsh/.zshrc" ~/.zshrc
cp -f "$SRC/dotfiles/zsh/.zprofile" ~/.zprofile 2>/dev/null || true

# 5. Misc App Configs (GTK2/3, Ncmpcpp, Ranger, Geany, MIME defaults)
mkdir -p ~/.config/gtk-3.0 ~/.config/geany ~/.config/ncmpcpp ~/.config/ranger
cp -f "$SRC/misc/.gtkrc-2.0" ~/.gtkrc-2.0
cp -f "$SRC/misc/gtk-3.0/gtk.css" ~/.config/gtk-3.0/
cp -f "$SRC/misc/gtk-3.0/settings.ini" ~/.config/gtk-3.0/
cp -f "$SRC/misc/xdg-terminals.list" ~/.config/
cp -f "$SRC/misc/mimeapps.list" ~/.config/
cp -rf "$SRC/misc/geany"/* ~/.config/geany/
cp -rf "$SRC/misc/ncmpcpp"/* ~/.config/ncmpcpp/
cp -rf "$SRC/misc/ranger"/* ~/.config/ranger/

# 6. Default Environment Variables
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/10-terminal.conf << 'EOF'
TERMINAL=kitty
BROWSER=firefox
EDITOR=nvim
VISUAL=nvim
QT_QPA_PLATFORMTHEME=qt5ct
QT_STYLE_OVERRIDE=Fusion
EOF

# Make all scripts executable
chmod +x ~/.config/hypr/scripts/* ~/.config/hyprcat/scripts/* ~/.config/hypr/theme/theme.sh ~/.config/hyprcat/theme/theme.sh ~/.config/hypr/waybar/lightmode
```

---

### Step 6: System Session Launchers & Pacman Hooks

This sets up Wayland session files so your display manager (SDDM) can properly launch Hyprland with all environment variables loaded.

```bash
# 1. Install session launch scripts to /usr/local/bin
sudo cp -f "$SRC/misc/run-hyprland" /usr/local/bin/run-hyprland
sudo cp -f "$SRC/misc/run-hyprland-cat" /usr/local/bin/run-hyprland-cat
sudo chmod +x /usr/local/bin/run-hyprland /usr/local/bin/run-hyprland-cat

# 2. Desktop session entries
sudo mkdir -p /usr/share/wayland-sessions
sudo cp -f "$SRC/misc/hyprland-cat.desktop" /usr/share/wayland-sessions/hyprland-cat.desktop

sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=run-hyprland
Type=Application
DesktopNames=Hyprland
Keywords=tiling;wayland;compositor;
EOF

# 3. Pacman hooks (prevents future Hyprland package updates from overwriting Exec=run-hyprland)
sudo mkdir -p /etc/pacman.d/hooks
sudo cp -f "$SRC/misc/archcraft-hook-hyprland.hook" /etc/pacman.d/hooks/
sudo cp -f "$SRC/misc/archcraft-hook-hyprland-uwsm.hook" /etc/pacman.d/hooks/
```

---

### Step 7: Configure SDDM Display Manager & GRUB2 Theme

Configure SDDM with the custom Catppuccin Mocha `corners` theme (or `sddm-astronaut-theme`) and install the `Elegant-wave-window-right-dark` GRUB2 theme:

```bash
# 1. SDDM Corners Theme
sudo mkdir -p /usr/share/sddm/themes/corners /etc/sddm.conf.d
sudo cp -rf "$SRC/themes/sddm/corners"/. /usr/share/sddm/themes/corners/

sudo tee /etc/sddm.conf > /dev/null << 'EOF'
[Theme]
    Current=corners
EOF

sudo tee /etc/sddm.conf.d/virtualkbd.conf > /dev/null << 'EOF'
[General]
    InputMethod=qtvirtualkeyboard
EOF

sudo systemctl enable sddm.service

# 2. Elegant GRUB2 Bootloader Theme
sudo mkdir -p /boot/grub/themes/Elegant-wave-window-right-dark
sudo cp -rf "$SRC/themes/grub/Elegant-wave-window-right-dark"/. /boot/grub/themes/Elegant-wave-window-right-dark/
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

### Step 8: Initialize Theme & Apply GTK Settings

```bash
# Set initial GTK settings
gsettings set org.gnome.desktop.interface gtk-theme 'Manhattan'
gsettings set org.gnome.desktop.interface icon-theme 'Luv-Folders-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Qogirr-Dark'
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 9'
gsettings set org.gnome.desktop.wm.preferences button-layout ":"
```

---

## ⌨️ Keybindings Cheat Sheet

| Key Combination | Action |
| :--- | :--- |
| `Super + Return` | Open Terminal (`kitty`) |
| `Super + Shift + Return` | Open Floating Terminal (`kitty -f`) |
| `Super + Alt + Return` | Open Fullscreen Terminal (`kitty -F`) |
| `Super` or `Super + D` or `Alt + F1` | Open App Launcher (`rofi`) |
| `Alt + F2` | Open Command Runner (`rofi`) |
| `Super + V` | Open Clipboard History (`rofi_clipboard` + `cliphist`) |
| `Super + R` | Open Run-as-Root App Menu (`rofi_asroot`) |
| `Super + M` | Open Music / Spotify Menu (`rofi_spotify`) |
| `Super + Shift + F` | Open File Manager (`thunar`) |
| `Super + Shift + E` | Open Text Editor (`geany`) |
| `Super + Shift + W` | Open Web Browser (`firefox`) |
| `Super + X` | Open Power Menu (`rofi_powermenu`) |
| `Super + S` | Open Screenshot Menu (`rofi_screenshot`) |
| `Super + N` | Open WiFi / Network Menu (`rofi_network`) |
| `Super + B` | Open Bluetooth Menu (`rofi_bluetooth`) |
| `Super + Escape` / `Super + Shift + B` | Restart / Toggle Waybar Status Bar (`statusbar`) |
| `Super + F5` or `XF86Launch3/4` | Cycle Power Profile (`power-saver` / `balanced` / `performance`) |
| `Super + P` | Color Picker (`hyprpicker`) |
| `Super + Shift + P` | Pin Floating Window Across Workspaces |
| `Super + C` | Close Active Window |
| `Super + Q` | Force Kill Active Window |
| `Super + Space` | Toggle Window Floating & Center |
| `Super + F` | Toggle Window Fullscreen |
| `Super + 1..9` | Switch to Workspace 1–9 |
| `Super + Shift + 1..9` | Move Active Window to Workspace 1–9 |
| `Ctrl + Alt + L` | Lock Screen (`hyprlock`) |
| `Print` | Select Area Screenshot |
| `Super + Print` | Instant Fullscreen Screenshot |
| `Ctrl + Print` | Active Window Screenshot |
| `XF86AudioRaiseVolume / LowerVolume` | Raise / Lower Volume (with Mako OSD) |
| `XF86MonBrightnessUp / Down` | Raise / Lower Screen Brightness (with Mako OSD) |

---

## 🎨 Tinkering & Customization

### 1. Switching Color Schemes on the Fly
The rice includes a master theme engine in `~/.config/hypr/theme/theme.sh` that synchronizes colors across Hyprland borders, Waybar, Rofi, Wofi, Mako, Wlogout, Kitty, Alacritty, Foot, and GTK:

```bash
# 1. Default Dark Theme (Manhattan palette)
~/.config/hypr/theme/theme.sh --default

# 2. Light Theme (White palette)
~/.config/hypr/theme/theme.sh --light

# 3. Dynamic Pywal Theme (Generates colors from current wallpaper in ~/Pictures/wallpapers)
~/.config/hypr/theme/theme.sh --pywal
```
> [!TIP]
> You can also click the **palette / sun icon** on the right side of the Waybar status bar to switch themes with one click!

### 2. Multi-Monitor & Resolution Setup
Edit [20-monitor.conf](file:///home/user/.config/hypr/config.d/20-monitor.conf):
```ini
# Syntax: monitor = name, resolution@refresh, position, scale
monitor = , preferred, auto, 1

# Examples:
# monitor = DP-1, 2560x1440@144, 0x0, 1
# monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1
```

### 3. Touchpad Gestures & Keyboard Layout
Edit [04-input.conf](file:///home/user/.config/hypr/config.d/04-input.conf) and [05-gestures.conf](file:///home/user/.config/hypr/config.d/05-gestures.conf):
- **Natural Scrolling**: In `04-input.conf`, set `touchpad { natural_scroll = true }`
- **Caps Lock as Escape**: `kb_options = caps:swapescape`
- **3-Finger Swipe**: Swipes across workspaces
- **4-Finger Swipe**: Navigates focus between windows

---

## 🛠️ Troubleshooting & NVIDIA Notes

### NVIDIA Users
Add these environment variables to `/usr/local/bin/run-hyprland` before `start-hyprland`:
```bash
export LIBVA_DRIVER_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export NVD_BACKEND=direct
export ELECTRON_OZONE_PLATFORM_HINT=auto
```
Also ensure `nvidia_drm.modeset=1` is added to your kernel parameters in GRUB/systemd-boot.

### Screen Sharing / Portals
If OBS Studio or Discord cannot share screen:
```bash
systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal
```
Make sure only `xdg-desktop-portal-hyprland` and `xdg-desktop-portal-gtk` are installed (avoid running `xdg-desktop-portal-gnome` or `xdg-desktop-portal-wlr` alongside it).

---

## 🤖 Google Antigravity & AI Agent Setup

To configure an identical **Google Antigravity** environment on your Arch Linux system—complete with integrated memory recall, context optimization, skills, and plugins—use the included automated script (or select **Y** during the interactive `install.sh` wizard, which also restores synced skills and plugins from `arch/dotfiles/antigravity/`):

```bash
chmod +x setup-antigravity.sh
./setup-antigravity.sh
```

### Components Provisioned:
1. **Antigravity Tooling**: Installs `antigravity-cli` (`agy`) and `antigravity-ide` via AUR / official installer.
2. **Memory Engine (`claude-mem`)**:
   - Clones and builds `thedotmack/claude-mem` runtime via Bun.
   - Registers Stdio MCP server (`mcp-server.cjs`).
   - Hooks lifecycle events (`SessionStart`, `BeforeAgent`, `AfterAgent`, `BeforeTool`, `AfterTool`, `Notification`, `PreCompress`).
3. **Context Optimization Layer (`headroom`)**:
   - Installs `headroom-ai` and exposes `headroom mcp serve` via MCP.
4. **Skills & Orchestration (`task-observer` & `speckit`)**:
   - Installs `rebelytics/one-skill-to-rule-them-all` into `~/.gemini/config/skills/task-observer`.
   - Initializes `~/.gemini/skill-observations/` and registers global `skills.json`.
   - Provisions `specify-cli` for spec-driven workflows.
5. **Rules & Plugins**:
   - Writes `~/.gemini/GEMINI.md` enforcing the Autonomous Tool Orchestration Protocol.
   - Enables `chrome-devtools-plugin`, `google-antigravity-sdk`, and `modern-web-guidance-plugin`.
   - Sets dark theme, eager execution policy, and permission grants.

### Verification:
```bash
agy mcp list
```
Expected output:
```text
NAME        TYPE   STATUS   COMMAND/URL
claude-mem  stdio  enabled  node /home/<user>/.claude/plugins/marketplaces/thedotmack/plugin/scripts/mcp-server.cjs
headroom    stdio  enabled  headroom mcp serve
```

---

## 🧠 Complete Antigravity Skills & Plugins Inventory

All custom skills and plugins currently active on this Linux Antigravity setup are documented below AND backed up directly inside [`arch/dotfiles/antigravity/`](dotfiles/antigravity) (automatically restored by `install.sh` when the Antigravity bundle is enabled, or copied manually via the commands below).

### 1. Standalone User Skills (`~/.gemini/config/skills/`)

| Skill Name | Path | Purpose / Trigger | Source / Manual Install |
| :--- | :--- | :--- | :--- |
| **`canvas-design`** | `~/.gemini/config/skills/canvas-design/SKILL.md` | Create visual art, illustrations, vector graphics, and posters in SVG, HTML5 Canvas, `.png`, and `.pdf` using deliberate design philosophies. | Backed up in `arch/dotfiles/antigravity/skills/canvas-design` |
| **`chisle`** | `~/.gemini/config/skills/chisle/SKILL.md` | **Mandatory Always-On Efficiency Mode**: Enforces terse high-signal prose, zero fluff, YAGNI Efficiency Ladder code decisions, and context diet. | Backed up in `arch/dotfiles/antigravity/skills/chisle` |
| **`chisle-audit`** | `~/.gemini/config/skills/chisle-audit/SKILL.md` | One-shot efficiency audit of a file, diff, or repo across both axes: over-engineered code and bloated prose (`/chisle-audit`). | Backed up in `arch/dotfiles/antigravity/skills/chisle-audit` |
| **`chisle-help`** | `~/.gemini/config/skills/chisle-help/SKILL.md` | Quick-reference card for Chisle commands (`/chisle-help`). | Backed up in `arch/dotfiles/antigravity/skills/chisle-help` |
| **`chisle-review`** | `~/.gemini/config/skills/chisle-review/SKILL.md` | Review a diff or file through the Chisle lens: flag over-engineering, speculative abstractions, and verbose code (`/chisle-review`). | Backed up in `arch/dotfiles/antigravity/skills/chisle-review` |
| **`deep-debugger`** | `~/.gemini/config/skills/deep-debugger/SKILL.md` | Systematic, hypothesis-driven debugging methodology for tricky bugs, test failures, race conditions, and memory leaks. | Backed up in `arch/dotfiles/antigravity/skills/deep-debugger` |
| **`frontend-design`** | `~/.gemini/config/skills/frontend-design/SKILL.md` | Guidance for distinctive, intentional visual design, typography, and aesthetic direction avoiding generic AI templates. | Backed up in `arch/dotfiles/antigravity/skills/frontend-design` |
| **`i-have-adhd`** | `~/.gemini/config/skills/i-have-adhd/SKILL.md` | Shapes AI output for ADHD readers: next physical action first, numbered steps, current state restatement, and honest time estimates. | `git clone https://github.com/ayghri/i-have-adhd.git ~/.gemini/config/skills/i-have-adhd` |
| **`pdf`** | `~/.gemini/config/skills/pdf/SKILL.md` | Read/extract text & tables, merge, split, rotate, watermark, create, fill forms, encrypt/decrypt, and OCR PDF files. | Backed up in `arch/dotfiles/antigravity/skills/pdf` |
| **`reverse-engineer-anything`** | `~/.gemini/config/skills/reverse-engineer-anything/SKILL.md` | Reverse engineer native, managed, Electron/JS, packaged, firmware, and browser targets using REA. | Backed up in `arch/dotfiles/antigravity/skills/reverse-engineer-anything` |
| **`sast-security-auditor`** | `~/.gemini/config/skills/sast-security-auditor/SKILL.md` | Systematic Static Application Security Testing (SAST), OWASP Top 10 vulnerability detection, secret scanning, and PR security audits. | Backed up in `arch/dotfiles/antigravity/skills/sast-security-auditor` |
| **`sinhala-explainer`** | `~/.gemini/config/skills/sinhala-explainer/SKILL.md` | Explains technical concepts, URLs, files, PDFs, or images in friendly spoken Sinhala (`/sinhala-explainer`). | Backed up in `arch/dotfiles/antigravity/skills/sinhala-explainer` |
| **`sinhala-explainer-only-from-content`** | `~/.gemini/config/skills/sinhala-explainer-only-from-content/SKILL.md` | Explains strictly provided lecture notes, slides, or documents in spoken Sinhala without outside web retrieval (`/sinhala-explainer-only-from-content`). | Backed up in `arch/dotfiles/antigravity/skills/sinhala-explainer-only-from-content` |
| **`sinhala-explainer-short`** | `~/.gemini/config/skills/sinhala-explainer-short/SKILL.md` | Concise, ceremony-free technical explanations in spoken Sinhala (`/sinhala-explainer-short`). | Backed up in `arch/dotfiles/antigravity/skills/sinhala-explainer-short` |
| **`task-observer`** | `~/.gemini/config/skills/task-observer/SKILL.md` | Continuous task observation and meta-learning skill (`one-skill-to-rule-them-all`). | `git clone https://github.com/rebelytics/one-skill-to-rule-them-all.git /tmp/ost && cp -r /tmp/ost/skills/task-observer ~/.gemini/config/skills/` |

### 2. Installed Plugins & Bundled Plugin Skills (`~/.gemini/config/plugins/`)

| Plugin Name | Version | Bundled Skills & Rules | Purpose |
| :--- | :--- | :--- | :--- |
| **`chisle`** (`Chisle Token Optimizer`) | `3.5.0` | **Rules**: `AGENTS.md`, `GEMINI.md`<br>**Skills**: `chisle`, `chisle-audit`, `chisle-help`, `chisle-review` | Always-on token efficiency rules and Chisle slash skills. |
| **`chrome-devtools-plugin`** (`Chrome DevTools`) | `0.21.0` | **Skills**:<br>• `chrome-devtools` (browser automation & inspection)<br>• `a11y-debugging` (accessibility auditing)<br>• `debug-optimize-lcp` (Core Web Vitals & LCP)<br>• `memory-leak-debugging` (heap snapshots & memlab)<br>• `troubleshooting` (MCP target recovery) | Full Chrome DevTools MCP integration and web performance/accessibility debugging suite. |
| **`modern-web-guidance-plugin`** (`Modern Web Guidance`) | `1.0.6` | **Skills**:<br>• `modern-web-guidance` (modern HTML/CSS/JS APIs, View Transitions, `:has()`, Popover, Anchor Positioning)<br>• `chrome-extensions` (Manifest V3 extension engineering & Web Store publishing) | Up-to-date modern web platform and Chrome Extension MV3 guidance. |
| **`i-have-adhd`** | `git` | **Skill**: `i-have-adhd` | ADHD-friendly output formatting plugin (`https://github.com/ayghri/i-have-adhd.git`). |

### 3. Built-in Antigravity System Skills (`~/.gemini/antigravity/builtin/skills/`)
Automatically provided by the Antigravity IDE/CLI runtime:
- `agy-customizations`: Guide for creating and managing Antigravity skills, rules, plugins, hooks, and MCP servers.
- `antigravity-guide`: Reference and sitemap for Antigravity IDE, `agy` CLI, SDK, slash commands, and keybindings.
- `automation`: Interactive guide for creating scheduled background automations (`/automation`).
- `generative_ui`: Render interactive HTML widgets inline in chat or as standalone artifacts.
- `migrate-workflows`: Migrate legacy workflows to modern `SKILL.md` files.
- `plugin`: Package, install, enable, and disable Antigravity plugins (`/plugin`).
- `ui-extension`: Build and debug side-pane UI extensions using the Node.js Sidecar SDK.
- `ui-plugin-navigation`: Surface one-click pills in chat to toggle UI plugin panels.

### Manual Skill & Plugin Restore Command
If you ever want to restore all custom skills and plugins manually without running the full installer:
```bash
mkdir -p ~/.gemini/config/skills ~/.gemini/config/plugins
cp -rf ~/nixos-config/arch/dotfiles/antigravity/skills/* ~/.gemini/config/skills/
cp -rf ~/nixos-config/arch/dotfiles/antigravity/plugins/* ~/.gemini/config/plugins/
```

---

## 🔐 Post-Install Manual Setup (SSH Keys, Git & Sensitive Credentials)

Because private cryptographic keys, tokens, and personal credentials **must never be stored in a public Git repository**, complete these steps manually after `install.sh` finishes and you reboot into Hyprland:

### 1. Generate or Restore SSH Keys (`~/.ssh`)
```bash
# Create ~/.ssh with strict permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate a new Ed25519 SSH key for GitHub & remote servers
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519

# Start ssh-agent and add your key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard (Wayland) to paste into GitHub -> Settings -> SSH Keys
wl-copy < ~/.ssh/id_ed25519.pub
# (Or print it to terminal: cat ~/.ssh/id_ed25519.pub)
```

Optional `~/.ssh/config`:
```ssh-config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
```
Fix permissions if restoring existing keys from a USB backup:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* ~/.ssh/config
chmod 644 ~/.ssh/*.pub ~/.ssh/known_hosts
```

### 2. Configure Git Identity & SSH Signing
```bash
git config --global user.name "Manuja"
git config --global user.email "your_email@example.com"
git config --global init.defaultBranch main

# Optional: Sign commits using your SSH key
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
```

### 3. Authenticate GitHub CLI (`gh`) & Switch Repo Remote to SSH
```bash
# Authenticate GitHub CLI interactively
gh auth login

# Test SSH connection to GitHub
ssh -T git@github.com

# Switch your local Linux-Configs clone from HTTPS to SSH so you can push updates
cd ~/nixos-config
git remote set-url origin git@github.com:manuja-me/Linux-Configs.git
```

### 4. Authenticate AI & Cloud CLIs (Antigravity, Spotify, etc.)
- **Google Antigravity**: Launch Antigravity or run `agy` and sign in to your Google account; reconnect any MCP plugin accounts via the Plugins Manager.
- **Spotify + Spicetify**:
  1. Launch `spotify` once and log in to your account.
  2. Run `spicetify backup apply` in a terminal to activate your custom Spicetify theme (`~/.config/spicetify`).
- **Environment Secrets / API Keys**: Store any private API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.) in `~/.zsh_secrets` (chmod `600`) and source it from `~/.zshrc` (`[[ -f ~/.zsh_secrets ]] && source ~/.zsh_secrets`) so they stay untracked by Git.

---

## 🛡️ Bootloader Recovery (`boot-recovery/recover-boot.sh`)

Automated emergency GRUB EFI bootloader restoration script for this machine (dual-boot Arch on NVMe + Windows NVMe).

### Usage (from Arch Live USB as root):
```bash
chmod +x boot-recovery/recover-boot.sh
./boot-recovery/recover-boot.sh
```

### What it does:
- Validates UEFI boot environment and checks partition block devices by UUID.
- Backs up existing `/etc/default/grub`, `grub.cfg`, and `efibootmgr` state with timestamps.
- Mounts root and `/boot` ESP partitions, chroots into system.
- Ensures `GRUB_DISABLE_OS_PROBER=false` is configured and rebuilds `mkinitcpio -P`.
- Runs `grub-install` (UEFI target + `--removable` fallback) and `grub-mkconfig`.
- Restores GRUB to the top priority in `efibootmgr` firmware boot order.


