# Barebone Arch Linux to Aesthetic Hyprland Rice: Master Guide

This guide walks you through transforming a **fresh barebone Arch Linux installation** into this exact, fully customized, aesthetically riced **Hyprland** desktop environment using your `hyprlandConfig` bundle.

---

## 🏗️ Architecture of the Rice

| Component | Software Used | Purpose |
| :--- | :--- | :--- |
| **Compositor** | `hyprland` (with `uwsm` / `start-hyprland`) | Dynamic tiling Wayland compositor |
| **Status Bar** | `waybar` | Top status bar with system stats, audio, network, battery, theme switcher |
| **App Launcher & Menus** | `rofi` (Wayland fork) + `wofi` | App launcher, powermenu, screenshot menu, network menu, bluetooth menu |
| **Terminals** | `kitty` (primary default), `alacritty`, `foot` | GPU-accelerated terminal emulators styled with rice colors |
| **Notifications** | `mako` | Lightweight Wayland notification daemon with custom icons & urgency colors |
| **Lock Screen & Idle** | `hyprlock` & `hypridle` | Fast, styled Wayland lock screen with blurred wallpaper |
| **Session Control** | `wlogout` | Aesthetic logout / lock / shutdown / reboot splash menu |
| **Dynamic Theming** | `pastel` + `python-pywal` + custom `theme.sh` | On-the-fly theme switching (Dark, Light, Catppuccin, Pywal wallpaper-adaptive) |
| **Display Manager** | `sddm` + `sddm-astronaut-theme` | Modern animated login screen with virtual keyboard support |
| **GTK & Icons** | `Manhattan` / `Catppuccin-Mocha`, `Luv-Folders-Dark`, `Qogirr-Dark` | Unified dark/light theme consistency across GTK3, GTK4, and Qt apps |

---

## ⚡ Quick Start: 1-Click Automated Rice Deployment

Both `/home/user/install_hyprland_rice.sh` and [install.sh](file:///home/user/Downloads/hyprlandConfig/install.sh) have been created.

When installing on your new Arch machine:

```bash
# 1. Copy or clone your hyprlandConfig folder to your new system
cd ~/Downloads/hyprlandConfig

# 2. Make the installer executable & run it
chmod +x install.sh
./install.sh
```

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

Navigate to your `hyprlandConfig` directory:

```bash
SRC="$HOME/Downloads/hyprlandConfig"

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

# 3. App configs (GTK3 CSS, Ncmpcpp, Ranger, Geany)
mkdir -p ~/.config/gtk-3.0 ~/.config/geany ~/.config/ncmpcpp ~/.config/ranger
cp -f "$SRC/misc/gtk-3.0/gtk.css" ~/.config/gtk-3.0/ 2>/dev/null || true
cp -rf "$SRC/misc/geany"/* ~/.config/geany/ 2>/dev/null || true
cp -rf "$SRC/misc/ncmpcpp"/* ~/.config/ncmpcpp/ 2>/dev/null || true
cp -rf "$SRC/misc/ranger"/* ~/.config/ranger/ 2>/dev/null || true

# 4. Default Environment Variables
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/10-terminal.conf << 'EOF'
TERMINAL=kitty
BROWSER=firefox
EDITOR=nvim
VISUAL=nvim
EOF

# Make all scripts executable
chmod +x ~/.config/hypr/scripts/* ~/.config/hyprcat/scripts/* ~/.config/hypr/theme/theme.sh ~/.config/hyprcat/theme/theme.sh
```

---

### Step 6: Critical Modern Hyprland Compatibility Fixes

The raw bundle contains older configuration syntax that causes errors on modern Hyprland versions. Apply these exact fixes:

#### 6.1 Clean Obsolete Options in `~/.config/hypr/config.d/`
```bash
# In 02-decoration.conf: Remove deprecated 'ignore_window'
sed -i '/ignore_window[[:space:]]*=[[:space:]]*true/d' ~/.config/hypr/config.d/02-decoration.conf

# In 09-misc.conf: Remove deprecated 'vfr' and 'cm_fs_passthrough'
sed -i '/vfr[[:space:]]*=[[:space:]]*true/d' ~/.config/hypr/config.d/09-misc.conf
sed -i '/cm_fs_passthrough/d' ~/.config/hypr/config.d/09-misc.conf

# In 30-layout-dwindle.conf: Remove deprecated 'pseudotile' and obsolete aspect ratio
sed -i '/pseudotile/d' ~/.config/hypr/config.d/30-layout-dwindle.conf
sed -i '/single_window_aspect_ratio/d' ~/.config/hypr/config.d/30-layout-dwindle.conf
```

#### 6.2 Fix Rofi Menus Toggle Behavior
By default, running a rofi launcher while one is open causes an error or stays stuck. Adding a toggle check allows hotkeys to toggle the menu smoothly:

```bash
for script in ~/.config/hypr/scripts/rofi_*; do
    if ! grep -q 'pgrep -x "rofi"' "$script"; then
        sed -i '2i\
# Toggle rofi if already open\
if pgrep -x "rofi" >/dev/null; then\
\tpkill -x "rofi"\
\texit 0\
fi\
' "$script"
    fi
done
```

---

### Step 7: System Session Launchers & Pacman Hooks

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

### Step 8: Configure SDDM Display Manager

Configure SDDM to use the `sddm-astronaut-theme` with virtual keyboard support:

```bash
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

sudo systemctl enable sddm.service
```

---

### Step 9: Initialize Theme & Apply GTK Settings

```bash
# Apply Default Theme
bash ~/.config/hypr/theme/theme.sh --default

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
| `Super + Shift + F` | Open File Manager (`thunar`) |
| `Super + Shift + E` | Open Text Editor (`geany`) |
| `Super + Shift + W` | Open Web Browser (`firefox`) |
| `Super + X` | Open Power Menu (`rofi`) |
| `Super + S` | Open Screenshot Menu (`rofi`) |
| `Super + N` | Open WiFi / Network Menu (`rofi`) |
| `Super + B` | Open Bluetooth Menu (`rofi`) |
| `Super + P` | Color Picker (`hyprpicker`) |
| `Super + C` | Close Active Window |
| `Super + Q` | Force Kill Active Window |
| `Super + Space` | Toggle Window Floating |
| `Super + F` | Toggle Window Fullscreen |
| `Super + 1..9` | Switch to Workspace 1–9 |
| `Super + Shift + 1..9` | Move Active Window to Workspace 1–9 |
| `Ctrl + Alt + L` | Lock Screen (`hyprlock`) |
| `Print` | Instant Screenshot |
| `Super + Print` | Select Area Screenshot |
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

To configure an identical **Google Antigravity** environment on your Arch Linux system—complete with integrated memory recall, context optimization, skills, and plugins—use the included automated script:

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

