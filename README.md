# 🐧 Linux Configurations & Dotfiles

A multi-distribution configuration repository containing declarative system configs for **NixOS** and a riced **Arch Linux Hyprland** desktop setup.

---

## 📂 Repository Structure

```tree
.
├── arch/                     # Arch Linux Hyprland Rice & Reproducible Builder
│   ├── boot-recovery/        # GRUB EFI bootloader recovery script (recover-boot.sh)
│   ├── dotfiles/             # Synced live user configurations:
│   │   ├── hypr/ & hyprcat/  #   Hyprland, Waybar, Rofi, Kitty, Alacritty, Foot, Mako, Wlogout
│   │   ├── nvim/             #   LazyVim Neovim configuration & locked plugins (lazy-lock.json)
│   │   ├── zsh/              #   Oh-My-Zsh (.zshrc, .zprofile, aliases, Yazi wrapper)
│   │   ├── yazi/             #   Yazi terminal file manager config, keymaps & plugins
│   │   ├── btop/ & cava/     #   System monitor & audio visualizer configs/themes
│   │   ├── spicetify/        #   Spotify custom themes & marketplace config
│   │   └── qt5ct/, mpv/, ... #   Qt5ct, MPV, Thunar, Viewnior, Xarchiver, Fontconfig
│   ├── fonts/                # Custom Nerd Fonts (JetBrainsMono, FiraCode, Iosevka, RobotoMono)
│   ├── gtk/                  # GTK Themes (Manhattan, Catppuccin-Mocha, White), Icons & Cursors
│   ├── misc/                 # Session launchers (run-hyprland), GTK2/3 settings & Pacman hooks
│   ├── screenshots/          # Showcase screenshots
│   ├── themes/               # System themes:
│   │   ├── grub/             #   Elegant-wave-window-right-dark GRUB2 bootloader theme
│   │   └── sddm/             #   Customized Catppuccin Mocha 'corners' SDDM login theme
│   ├── bootstrap.sh          # 1-Line Cloud TTY Entrypoint (curl | bash)
│   ├── install.sh            # Interactive Modular System & Rice Installer
│   ├── restore.sh            # Interactive Snapshot Rollback & "Clean Arch Slate" Reset
│   ├── sync-from-live.sh     # Sync live machine changes back into this repository
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

### 🔷 [Arch Linux Reproducible Hyprland Build (`arch/`)](arch/README.md)
Transforms a fresh, minimal barebone Arch Linux TTY installation into this exact, fully configured Hyprland desktop environment.

**Highlights:**
- **1-Line TTY Cloud Bootstrap**: Run directly from a fresh minimal Arch TTY via `curl | bash` (binds `/dev/tty` for interactive prompts and `sudo`/`su` password entry along the way).
- **Automatic Verbose Mode & Error Diagnostics**: Runs with live command tracing (`set -x`), streams full output to `/tmp/arch-hypr-install-<timestamp>.log`, and uses an `ERR` trap to display the exact failing function, line number, exit code, and command on any error.
- **Interactive Setup Wizard**: Prompts for target username (creates user & configures `wheel` sudo access if needed), GPU drivers (Intel/AMD/NVIDIA/VM), SDDM & GRUB themes, and optional feature bundles.
- **Compositor & Bar**: Hyprland + Waybar + Rofi (`cliphist` clipboard history, power profile switcher, network, bluetooth, screenshots) + Mako + Hyprlock + Wlogout.
- **Shell, Editor & TUI**: Zsh (`Oh-My-Zsh`), Neovim (`LazyVim` with locked plugins), Yazi, Btop, Cava, Fastfetch, Zathura.
- **Media, Gaming & Virtualization**: PipeWire + EasyEffects + MPV + MPD/ncmpcpp + Spotify/Spicetify + QEMU/KVM/Virt-Manager.
- **Boot & Login Aesthetics**: SDDM (`corners` Catppuccin Mocha & `astronaut` themes) + Elegant GRUB2 theme (`Elegant-wave-window-right-dark`).
- **Clean-Slate Rollback (`restore.sh`)**: Restore pre-install snapshots or reset the system back to a clean minimal Arch TTY slate (also logged to `/tmp/arch-hypr-restore-<timestamp>.log`).

**1-Command Install from Fresh Arch TTY:**
```bash
curl -fsSL https://raw.githubusercontent.com/manuja-me/nixos-config/main/arch/bootstrap.sh | bash
```

**Or Manual Clone & Install:**
```bash
git clone https://github.com/manuja-me/nixos-config.git ~/nixos-config
cd ~/nixos-config/arch
./install.sh
```

**Rollback / Reset to Clean Arch Slate:**
```bash
~/nixos-config/arch/restore.sh
```

**Sync Live Machine Tweaks Back to Repo:**
```bash
~/nixos-config/arch/sync-from-live.sh
```

👉 See the [Arch Linux Rice Guide](arch/README.md) for the full execution order, keybindings, and manual tinkering reference.

---

### 🛡️ [GRUB Bootloader Recovery (`arch/boot-recovery/`)](arch/boot-recovery/recover-boot.sh)
Emergency EFI/GRUB recovery script for UEFI dual-boot setups (Arch + Windows NVMe partitions). Run from an Arch live USB to mount partitions via UUID, chroot, restore initramfs, re-install GRUB with os-prober, and configure `efibootmgr` boot order.

---

### 🤖 [Google Antigravity Setup (`arch/setup-antigravity.sh`)](arch/README.md#google-antigravity-setup)
1-click environment setup replicating the Google Antigravity developer workspace, including `claude-mem` MCP & lifecycle hooks, `headroom` context compression layer, `task-observer` continuous learning skill, `specify-cli`, and custom plugins/orchestration rules.

```bash
cd ~/nixos-config/arch
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
