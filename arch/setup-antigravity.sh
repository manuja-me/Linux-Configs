#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo "  Google Antigravity Arch Linux Environment Setup"
echo "=========================================================="

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

echo "==> Configuring environment for user: $TARGET_USER ($USER_HOME)"

# -----------------------------------------------------------------------------
# 1. System Dependencies via pacman
# -----------------------------------------------------------------------------
echo "==> [1/7] Installing base system dependencies with pacman..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    curl \
    wget \
    ripgrep \
    fd \
    nodejs \
    npm \
    python \
    python-pip \
    bun

# Detect AUR helper
AUR_HELPER=""
if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
fi

# -----------------------------------------------------------------------------
# 2. Antigravity & UV Installation
# -----------------------------------------------------------------------------
echo "==> [2/7] Installing Antigravity and uv..."
if [ -n "$AUR_HELPER" ]; then
    echo "Found AUR helper ($AUR_HELPER). Installing packages..."
    $AUR_HELPER -S --needed --noconfirm antigravity-cli antigravity-ide uv || true
else
    echo "No AUR helper found. Installing via official standalone install scripts..."
    if ! command -v agy &>/dev/null; then
        curl -fsSL https://antigravity.google/cli/install.sh | sh
    fi
    if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
fi

# Add local binary paths to environment
export PATH="$USER_HOME/.local/bin:$USER_HOME/.cargo/bin:$USER_HOME/.bun/bin:$PATH"

# -----------------------------------------------------------------------------
# 3. Python Tools (headroom & specify)
# -----------------------------------------------------------------------------
echo "==> [3/7] Installing Python tools via uv (headroom-ai, specify-cli)..."
uv tool install --force headroom-ai
uv tool install --force specify-cli

# -----------------------------------------------------------------------------
# 4. Claude-Mem Installation (MCP Server & Lifecycle Worker)
# -----------------------------------------------------------------------------
echo "==> [4/7] Setting up claude-mem repository & dependencies..."
CLAUDE_MEM_DIR="$USER_HOME/.claude/plugins/marketplaces/thedotmack"
mkdir -p "$CLAUDE_MEM_DIR"

if [ ! -d "$CLAUDE_MEM_DIR/.git" ]; then
    git clone https://github.com/thedotmack/claude-mem.git "$CLAUDE_MEM_DIR"
else
    echo "Updating existing claude-mem repository..."
    git -C "$CLAUDE_MEM_DIR" pull --rebase || true
fi

echo "Installing claude-mem dependencies with bun..."
(cd "$CLAUDE_MEM_DIR/plugin" && bun install)

# Create claude-mem cross-session context rule
mkdir -p "$USER_HOME/.agents/rules"
cat << 'EOF' > "$USER_HOME/.agents/rules/claude-mem-context.md"
<claude-mem-context>
# claude-mem: Cross-Session Memory

*No context yet. Complete your first session and context will appear here.*

Use claude-mem's MCP search tools for manual memory queries.
</claude-mem-context>
EOF

# -----------------------------------------------------------------------------
# 5. Task Observer Skill Installation
# -----------------------------------------------------------------------------
echo "==> [5/7] Installing task-observer skill..."
SKILLS_DIR="$USER_HOME/.gemini/config/skills"
mkdir -p "$SKILLS_DIR"

if [ ! -d "$SKILLS_DIR/task-observer/.git" ]; then
    git clone https://github.com/rebelytics/one-skill-to-rule-them-all.git "$SKILLS_DIR/task-observer"
else
    echo "Updating existing task-observer repository..."
    git -C "$SKILLS_DIR/task-observer" pull --rebase || true
fi

# Initialize observations directory
OBS_DIR="$USER_HOME/.gemini/skill-observations"
mkdir -p "$OBS_DIR/observation-log/archive"
if [ ! -f "$OBS_DIR/last-review-date.txt" ]; then
    echo "never" > "$OBS_DIR/last-review-date.txt"
fi

if [ ! -f "$OBS_DIR/cross-cutting-principles.md" ]; then
    cat << 'EOF' > "$OBS_DIR/cross-cutting-principles.md"
# Cross-Cutting Principles

Principles that apply across all skills and workflows.
EOF
fi

# -----------------------------------------------------------------------------
# 6. Antigravity Configuration Files
# -----------------------------------------------------------------------------
echo "==> [6/7] Writing Antigravity configuration files..."
mkdir -p "$USER_HOME/.gemini/config"
mkdir -p "$USER_HOME/.gemini/antigravity"

# 6.1 Skills Registry (skills.json)
cat << EOF > "$USER_HOME/.gemini/config/skills.json"
{
  "entries": [
    {
      "path": "$USER_HOME/.gemini/config/skills"
    }
  ]
}
EOF

# 6.2 Global Rule File (GEMINI.md)
cat << 'EOF' > "$USER_HOME/.gemini/GEMINI.md"
<claude-mem-context>
# Memory Context from Past Sessions

*No context yet. Complete your first session and context will appear here.*
</claude-mem-context>

<headroom-context>
# Headroom Context Optimization
Headroom is available via MCP tools (`headroom_compress`, `headroom_retrieve`, `headroom_stats`) for on-demand context compression and retrieving original uncompressed content.
</headroom-context>

<task-observer-context>
# Task Observer (Meta-Skill)
The `task-observer` skill is installed globally at `~/.gemini/config/skills/task-observer`.
During multi-step tasks and agentic workflows, monitor for user corrections, workflow patterns, and opportunities for skill discovery or refinement. Log observations in `~/.gemini/skill-observations/observation-log/`.
</task-observer-context>

# Autonomous Tool Orchestration Protocol
For every prompt and task in Antigravity, actively think and autonomously decide when to leverage your integrated capabilities:
1. **Memory Recall (`claude-mem`)**: Autonomously search historical decisions, project context, and past solutions via claude-mem MCP tools (`search`, `timeline`, `get_observations`) whenever tackling existing codebases, bug investigations, or recurring workflows.
2. **Context Optimization (`headroom`)**: Proactively compress voluminous logs, deep file contents, and extensive search responses using `headroom_compress`, and retrieve original uncompressed chunks with `headroom_retrieve` whenever detailed analysis is required.
3. **Continuous Learning (`task-observer`)**: Silently observe task execution, user corrections, and friction points. Record actionable patterns in `~/.gemini/skill-observations/observation-log/` to systematically evolve reusable skills.
4. **Spec-Driven Governance (`speckit`)**: When designing major architectures or initializing projects, consider Spec-Driven Development (`specify init --here --integration antigravity`) to anchor implementation to verifiable specifications.
EOF

# 6.3 MCP Configuration (mcp_config.json)
cat << EOF > "$USER_HOME/.gemini/config/mcp_config.json"
{
  "mcpServers": {
    "claude-mem": {
      "command": "node",
      "args": [
        "$USER_HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/mcp-server.cjs"
      ]
    },
    "headroom": {
      "command": "headroom",
      "args": [
        "mcp",
        "serve"
      ]
    }
  }
}
EOF
cp "$USER_HOME/.gemini/config/mcp_config.json" "$USER_HOME/.gemini/antigravity/mcp_config.json"

# 6.4 Lifecycle Hooks (settings.json)
BUN_BIN=$(command -v bun || echo "$USER_HOME/.bun/bin/bun")
cat << EOF > "$USER_HOME/.gemini/settings.json"
{
  "security": {
    "auth": {
      "selectedType": "oauth-personal"
    }
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "name": "claude-mem",
            "type": "command",
            "command": "$BUN_BIN $USER_HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs hook antigravity-cli context",
            "timeout": 10000
          }
        ]
      }
    ],
    "BeforeAgent": [
      {
        "matcher": "*",
        "hooks": [
          {
            "name": "claude-mem",
            "type": "command",
            "command": "$BUN_BIN $USER_HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs hook antigravity-cli session-init",
            "timeout": 10000
          }
        ]
      }
    ],
    "AfterAgent": [
      {
        "matcher": "*",
        "hooks": [
          {
            "name": "claude-mem",
            "type": "command",
            "command": "$BUN_BIN $USER_HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs hook antigravity-cli observation",
            "timeout": 10000
          }
        ]
      }
    ],
    "BeforeTool": [
      {
        "matcher": "*",
        "hooks": [
          {
            "name": "claude-mem",
            "type": "command",
            "command": "$BUN_BIN $USER_HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs hook antigravity-cli observation",
            "timeout": 10000
          }
        ]
      }
    ],
    "AfterTool": [
      {
        "matcher": "*",
        "hooks": [
          {
            "name": "claude-mem",
            "type": "command",
            "command": "$BUN_BIN $USER_HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs hook antigravity-cli observation",
            "timeout": 10000
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "*",
        "hooks": [
          {
            "name": "claude-mem",
            "type": "command",
            "command": "$BUN_BIN $USER_HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs hook antigravity-cli observation",
            "timeout": 10000
          }
        ]
      }
    ],
    "PreCompress": [
      {
        "matcher": "*",
        "hooks": [
          {
            "name": "claude-mem",
            "type": "command",
            "command": "$BUN_BIN $USER_HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs hook antigravity-cli summarize",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
EOF

# 6.5 UI Preferences, Permissions & Plugins Configuration (config.json)
cat << 'EOF' > "$USER_HOME/.gemini/config/config.json"
{
  "plugins": {
    "chrome-devtools-plugin": {
      "enabled": true
    },
    "google-antigravity-sdk": {
      "enabled": true
    },
    "modern-web-guidance-plugin": {
      "enabled": true
    }
  },
  "userSettings": {
    "autoExecutionPolicy": "CASCADE_COMMANDS_AUTO_EXECUTION_EAGER",
    "conversationWidth": "CONVERSATION_WIDTH_WIDE",
    "customThemeSeedsDark": {
      "background": "#101010",
      "foregroundOverride": "#FFFFFF",
      "primary": "#FFC799"
    },
    "customThemeSeedsLight": {
      "background": "#FAF4E5",
      "foregroundOverride": "#435155",
      "primary": "#CB4B16"
    },
    "enableTerminalSandbox": false,
    "globalPermissionGrants": {
      "allow": [
        "command(gh auth status)",
        "command(npm install)",
        "mcp(claude-mem/search)",
        "mcp(claude-mem/prime_corpus)",
        "mcp(claude-mem/get_observations)",
        "mcp(claude-mem/smart_outline)"
      ]
    },
    "nonWorkspaceFileAccessPolicy": "AGENT_SETTING_POLICY_ALLOW",
    "remoteControlEnabled": false,
    "themeMode": "THEME_MODE_DARK"
  }
}
EOF

# 6.6 Global Plugin Manifests
mkdir -p "$USER_HOME/.gemini/config/plugins/chrome-devtools-plugin"
cat << 'EOF' > "$USER_HOME/.gemini/config/plugins/chrome-devtools-plugin/plugin.json"
{
  "name": "chrome-devtools-plugin",
  "version": "0.21.0",
  "description": "Reliable automation, in-depth debugging, and performance analysis in Chrome using Chrome DevTools and Puppeteer",
  "author": { "name": "Chrome DevTools Team", "email": "devtools-dev@chromium.org" },
  "repository": "https://github.com/ChromeDevTools/chrome-devtools-mcp",
  "license": "Apache-2.0"
}
EOF

mkdir -p "$USER_HOME/.gemini/config/plugins/google-antigravity-sdk"
cat << 'EOF' > "$USER_HOME/.gemini/config/plugins/google-antigravity-sdk/plugin.json"
{
  "name": "google-antigravity-sdk",
  "version": "0.0.4",
  "description": "Using the Google Antigravity Python SDK to build AI agents",
  "author": { "name": "Google" },
  "license": "Apache-2.0"
}
EOF

mkdir -p "$USER_HOME/.gemini/config/plugins/modern-web-guidance-plugin"
cat << 'EOF' > "$USER_HOME/.gemini/config/plugins/modern-web-guidance-plugin/plugin.json"
{
  "name": "modern-web-guidance-plugin",
  "version": "0.0.151",
  "description": "Keep your coding agent up to date with the latest web best practices",
  "author": { "name": "Google Chrome" }
}
EOF

# -----------------------------------------------------------------------------
# 7. Verification & Permissions
# -----------------------------------------------------------------------------
echo "==> [7/7] Fixing permissions & testing installation..."
chown -R "$TARGET_USER:$TARGET_USER" \
    "$USER_HOME/.gemini" \
    "$USER_HOME/.claude" \
    "$USER_HOME/.agents" 2>/dev/null || true

echo "=========================================================="
echo "  Google Antigravity Setup Complete!"
echo "=========================================================="
echo "To verify active MCP servers, run:"
echo "  agy mcp list"
echo ""
echo "To test claude-mem, start agy and verify memory hooks are loaded."
echo "=========================================================="
