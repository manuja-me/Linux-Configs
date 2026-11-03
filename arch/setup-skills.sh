#!/usr/bin/env bash
# ==============================================================================
# Setup Antigravity Skills & Plugins in One Go
# ==============================================================================
# Installs and updates all custom, external Git-based, and plugin skills used
# by Google Antigravity in one idempotent command.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="$(eval echo "~$TARGET_USER")"

SKILLS_DIR="$USER_HOME/.gemini/config/skills"
PLUGINS_DIR="$USER_HOME/.gemini/config/plugins"
CONFIG_DIR="$USER_HOME/.gemini/config"

echo "==> Installing Antigravity skills & plugins for user: $TARGET_USER"
mkdir -p "$SKILLS_DIR" "$PLUGINS_DIR" "$CONFIG_DIR"

# -----------------------------------------------------------------------------
# 1. Restore Bundled Skills & Plugins from Repository
# -----------------------------------------------------------------------------
if [[ -d "$SCRIPT_DIR/dotfiles/antigravity/skills" ]]; then
    echo "==> [1/4] Copying bundled standalone skills from repository..."
    cp -rf "$SCRIPT_DIR/dotfiles/antigravity/skills"/. "$SKILLS_DIR/"
fi

if [[ -d "$SCRIPT_DIR/dotfiles/antigravity/plugins" ]]; then
    echo "==> [2/4] Copying bundled plugins from repository..."
    cp -rf "$SCRIPT_DIR/dotfiles/antigravity/plugins"/. "$PLUGINS_DIR/"
fi

# -----------------------------------------------------------------------------
# 2. Clone / Update External Git Repositories
# -----------------------------------------------------------------------------
echo "==> [3/4] Cloning & updating external Git skills and plugins..."

# 2.1 andrej-karpathy-skills (karpathy-guidelines)
KARPATHY_DIR="$PLUGINS_DIR/andrej-karpathy-skills"
if [[ ! -d "$KARPATHY_DIR/.git" ]]; then
    echo " -> Cloning andrej-karpathy-skills..."
    rm -rf "$KARPATHY_DIR"
    git clone https://github.com/multica-ai/andrej-karpathy-skills "$KARPATHY_DIR"
else
    echo " -> Updating andrej-karpathy-skills..."
    git -C "$KARPATHY_DIR" pull --rebase || true
fi

# 2.2 i-have-adhd (ADHD-optimized output)
ADHD_PLUGIN_DIR="$PLUGINS_DIR/i-have-adhd"
if [[ ! -d "$ADHD_PLUGIN_DIR/.git" ]]; then
    echo " -> Cloning i-have-adhd plugin..."
    rm -rf "$ADHD_PLUGIN_DIR"
    git clone https://github.com/ayghri/i-have-adhd.git "$ADHD_PLUGIN_DIR"
else
    echo " -> Updating i-have-adhd plugin..."
    git -C "$ADHD_PLUGIN_DIR" pull --rebase || true
fi
# Ensure standalone skill mirror is in place
if [[ -d "$ADHD_PLUGIN_DIR/skills/i-have-adhd" ]]; then
    cp -rf "$ADHD_PLUGIN_DIR/skills/i-have-adhd" "$SKILLS_DIR/"
fi

# 2.3 task-observer (Continuous learning & meta-observation)
TASK_OBS_DIR="$SKILLS_DIR/task-observer"
if [[ ! -d "$TASK_OBS_DIR/.git" ]]; then
    echo " -> Cloning task-observer..."
    rm -rf "$TASK_OBS_DIR"
    git clone https://github.com/rebelytics/one-skill-to-rule-them-all.git "$TASK_OBS_DIR"
else
    echo " -> Updating task-observer..."
    git -C "$TASK_OBS_DIR" pull --rebase || true
fi

# Initialize observations directory if not present
OBS_DIR="$USER_HOME/.gemini/skill-observations"
mkdir -p "$OBS_DIR/observation-log/archive"
[[ ! -f "$OBS_DIR/last-review-date.txt" ]] && echo "never" > "$OBS_DIR/last-review-date.txt"
if [[ ! -f "$OBS_DIR/cross-cutting-principles.md" ]]; then
    cat << 'EOF' > "$OBS_DIR/cross-cutting-principles.md"
# Cross-Cutting Principles

Principles that apply across all skills and workflows.
EOF
fi

# -----------------------------------------------------------------------------
# 3. Configure Antigravity Registry & Plugins
# -----------------------------------------------------------------------------
echo "==> [4/4] Updating skills.json & config.json plugin activations..."

cat << EOF > "$CONFIG_DIR/skills.json"
{
  "entries": [
    {
      "path": "$SKILLS_DIR"
    }
  ]
}
EOF

# Update config.json with all active plugins enabled using python or jq
python3 - << EOF
import json, os

config_path = "$CONFIG_DIR/config.json"
config = {}
if os.path.exists(config_path):
    try:
        with open(config_path, "r") as f:
            config = json.load(f)
    except Exception:
        config = {}

if "plugins" not in config:
    config["plugins"] = {}

plugins_to_enable = [
    "andrej-karpathy-skills",
    "chisle",
    "chrome-devtools-plugin",
    "google-antigravity-sdk",
    "i-have-adhd",
    "modern-web-guidance-plugin"
]

for p in plugins_to_enable:
    if p not in config["plugins"]:
        config["plugins"][p] = {"enabled": True}
    else:
        config["plugins"][p]["enabled"] = True

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)
EOF

# Fix permissions
if [[ "$TARGET_USER" != "root" ]]; then
    chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.gemini" 2>/dev/null || true
fi

echo "=========================================================="
echo "  All Antigravity Skills & Plugins Installed Successfully!"
echo "=========================================================="
