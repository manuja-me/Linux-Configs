# 🐧 Linux Configurations & Dotfiles

A multi-distribution configuration repository containing declarative system configs for **NixOS** and a riced **Arch Linux Hyprland** desktop setup.

---

## 📂 Repository Structure

```tree
.
├── arch/                     # Arch Linux Hyprland Rice & Dotfiles
│   ├── dotfiles/             # Hyprland, Hyprcat, Waybar, Rofi, Kitty, Mako configs
│   ├── fonts/                # Custom Nerd Fonts & Icon fonts
│   ├── gtk/                  # GTK Themes (Manhattan, Catppuccin), Icons & Cursors
│   ├── misc/                 # System session launchers & Pacman hooks
│   ├── screenshots/          # Showcase screenshots
│   ├── install.sh            # 1-Click Automated Setup Script
│   ├── setup-antigravity.sh  # 1-Click Google Antigravity & AI Agent Setup
│   └── README.md             # Complete step-by-step installation & tinkering guide
│
├── nixos/                    # NixOS Flakes & Home Manager Declarative Configurations
│   ├── home-manager/         # User environment & dotfiles via Home Manager
│   ├── hosts/                # Host-specific hardware and system configurations
│   ├── modules/              # Reusable NixOS system modules
│   ├── pkgs/                 # Custom Nix packages
│   ├── themes/               # Theming configuration
│   ├── flake.nix             # Nix Flake definition
│   └── README.md             # NixOS deployment & usage instructions
│
└── README.md                 # Root documentation
```

---

## 🚀 Quick Navigation

### 🔷 [Arch Linux Hyprland Rice (`arch/`)](arch/README.md)
Transforms a barebone Arch Linux installation into a fully configured, aesthetic Hyprland desktop environment.

**Highlights:**
- **Compositor**: Hyprland (with `uwsm` / `start-hyprland` session launcher)
- **Status Bar**: Waybar with system status, media control, and live theme switcher
- **Application Launcher & Menus**: Rofi (Wayland) with toggle support
- **Terminals**: Kitty (primary), Alacritty, Foot
- **Dynamic Theming**: On-the-fly Dark / Light / Pywal wallpaper / Catppuccin switching
- **Display Manager**: SDDM with Astronaut theme

**To install on Arch Linux:**
```bash
git clone https://github.com/manuja-me/Linux-Configs.git ~/linux-configs
cd ~/linux-configs/arch
chmod +x install.sh
./install.sh
```

👉 See the [Arch Linux Rice Guide](arch/README.md) for keybindings, manual steps, and custom tinkering instructions.

---

### 🤖 [Google Antigravity Setup (`arch/setup-antigravity.sh`)](arch/README.md#google-antigravity-setup)
1-click environment setup replicating the Google Antigravity developer workspace, including `claude-mem` MCP & lifecycle hooks, `headroom` context compression layer, `task-observer` continuous learning skill, `specify-cli`, and custom plugins/orchestration rules.

```bash
cd ~/linux-configs/arch
chmod +x setup-antigravity.sh
./setup-antigravity.sh
```

---

### ❄️ [NixOS Configurations (`nixos/`)](nixos/README.md)
Declarative NixOS setup using modern Flakes and Home Manager.

**To rebuild on NixOS:**
```bash
cd nixos
sudo nixos-rebuild switch --flake .#
```

👉 See the [NixOS Guide](nixos/README.md) for full instructions and module references.

---

## 📜 License
Personal system configurations provided as-is for reference and deployment. Individual themes, fonts, and utilities retain their respective creators' licenses.
