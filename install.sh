#!/bin/bash
set -e

# ============================================================
# claude-memory-bridge installer
# Cross-session persistent memory for Claude Code
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "╔══════════════════════════════════════════════╗"
echo "║   claude-memory-bridge installer             ║"
echo "║   Cross-session memory for Claude Code       ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ---- Step 1: Collect configuration ----
echo "📋 Configuration"
echo "─────────────────────────────────────────"

read -p "SSH tunnel port (default: 2222): " TUNNEL_PORT
TUNNEL_PORT="${TUNNEL_PORT:-2222}"

read -p "Local machine SSH username: " REMOTE_USER
if [ -z "$REMOTE_USER" ]; then
    echo "Error: username is required"
    exit 1
fi

read -p "Local machine OS (default: macOS): " LOCAL_OS
LOCAL_OS="${LOCAL_OS:-macOS}"

SERVER_OS="$(uname -s) $(uname -r)"

CROSS_SESSION_DIR="$CLAUDE_DIR/cross-session"
LOCAL_MEMORY_DIR="~/claude-memory"

read -p "Local memory directory (default: ~/claude-memory): " LOCAL_MEMORY_DIR_INPUT
LOCAL_MEMORY_DIR="${LOCAL_MEMORY_DIR_INPUT:-$LOCAL_MEMORY_DIR}"

INSTALL_DATE="$(date '+%Y-%m-%d %H:%M')"

echo ""
echo "📝 Configuration summary:"
echo "   Tunnel port:     $TUNNEL_PORT"
echo "   Remote user:     $REMOTE_USER"
echo "   Local OS:        $LOCAL_OS"
echo "   Server OS:       $SERVER_OS"
echo "   Memory dir:      $CROSS_SESSION_DIR"
echo "   Local backup:    $LOCAL_MEMORY_DIR"
echo ""
read -p "Proceed with installation? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# ---- Step 2: Template substitution helper ----
render_template() {
    local file="$1"
    sed -e "s|{{TUNNEL_PORT}}|$TUNNEL_PORT|g" \
        -e "s|{{REMOTE_USER}}|$REMOTE_USER|g" \
        -e "s|{{LOCAL_OS}}|$LOCAL_OS|g" \
        -e "s|{{SERVER_OS}}|$SERVER_OS|g" \
        -e "s|{{CROSS_SESSION_DIR}}|$CROSS_SESSION_DIR|g" \
        -e "s|{{LOCAL_MEMORY_DIR}}|$LOCAL_MEMORY_DIR|g" \
        -e "s|{{INSTALL_DATE}}|$INSTALL_DATE|g" \
        "$file"
}

# ---- Step 3: Create cross-session directory ----
echo ""
echo "📁 Creating cross-session memory directory..."
mkdir -p "$CROSS_SESSION_DIR"

render_template "$SCRIPT_DIR/templates/capabilities.md" > "$CROSS_SESSION_DIR/capabilities.md"
render_template "$SCRIPT_DIR/templates/journal.md" > "$CROSS_SESSION_DIR/journal.md"
render_template "$SCRIPT_DIR/templates/active-context.md" > "$CROSS_SESSION_DIR/active-context.md"
render_template "$SCRIPT_DIR/templates/load-context.sh" > "$CROSS_SESSION_DIR/load-context.sh"
render_template "$SCRIPT_DIR/templates/sync-to-local.sh" > "$CROSS_SESSION_DIR/sync-to-local.sh"
chmod +x "$CROSS_SESSION_DIR/load-context.sh"
chmod +x "$CROSS_SESSION_DIR/sync-to-local.sh"
echo "   ✓ Memory files created"

# ---- Step 4: Install slash commands ----
echo "⚡ Installing slash commands..."
mkdir -p "$CLAUDE_DIR/commands"

for cmd_file in "$SCRIPT_DIR/commands/"*.md; do
    cmd_name="$(basename "$cmd_file")"
    render_template "$cmd_file" > "$CLAUDE_DIR/commands/$cmd_name"
done
echo "   ✓ Commands installed: /save, /recall, /mac"

# ---- Step 5: Configure hooks in settings.json ----
echo "🔗 Configuring hooks..."

SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    # Check if hooks already exist
    if python3 -c "import json; d=json.load(open('$SETTINGS_FILE')); exit(0 if 'hooks' in d else 1)" 2>/dev/null; then
        echo "   ⚠ hooks already exist in settings.json, skipping (manual merge may be needed)"
        echo "   Add these hooks manually if needed:"
        echo "   UserPromptSubmit: bash $CROSS_SESSION_DIR/load-context.sh"
        echo "   PostToolUse (Write|Edit): bash $CROSS_SESSION_DIR/sync-to-local.sh"
    else
        # Add hooks to existing settings
        python3 -c "
import json
with open('$SETTINGS_FILE', 'r') as f:
    d = json.load(f)
d['hooks'] = {
    'UserPromptSubmit': [{
        'matcher': '',
        'hooks': [{
            'type': 'command',
            'command': 'bash $CROSS_SESSION_DIR/load-context.sh',
            'timeout': 5000
        }]
    }],
    'PostToolUse': [{
        'matcher': 'Write|Edit',
        'hooks': [{
            'type': 'command',
            'command': 'bash $CROSS_SESSION_DIR/sync-to-local.sh',
            'timeout': 10000
        }]
    }]
}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
        echo "   ✓ Hooks configured"
    fi
else
    # Create new settings.json with hooks
    cat > "$SETTINGS_FILE" << SETTINGSEOF
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash $CROSS_SESSION_DIR/load-context.sh",
            "timeout": 5000
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash $CROSS_SESSION_DIR/sync-to-local.sh",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
SETTINGSEOF
    echo "   ✓ settings.json created with hooks"
fi

# ---- Step 6: Append to CLAUDE.md ----
echo "📄 Updating CLAUDE.md..."

CLAUDE_MD="$HOME/CLAUDE.md"
MARKER="## Claude Environment Capabilities (claude-memory-bridge)"

if [ -f "$CLAUDE_MD" ] && grep -q "claude-memory-bridge" "$CLAUDE_MD" 2>/dev/null; then
    echo "   ⚠ CLAUDE.md already contains claude-memory-bridge section, skipping"
else
    echo "" >> "$CLAUDE_MD"
    render_template "$SCRIPT_DIR/templates/claude-md-snippet.md" >> "$CLAUDE_MD"
    echo "   ✓ CLAUDE.md updated"
fi

# ---- Step 7: Test tunnel & sync ----
echo "🔗 Testing SSH tunnel..."

if ssh -p "$TUNNEL_PORT" -o ConnectTimeout=5 "$REMOTE_USER@localhost" "echo ok" &>/dev/null; then
    echo "   ✓ Tunnel is active"

    echo "📤 Initial sync to local machine..."
    ssh -p "$TUNNEL_PORT" "$REMOTE_USER@localhost" "mkdir -p $LOCAL_MEMORY_DIR"
    bash "$CROSS_SESSION_DIR/sync-to-local.sh"
    echo "   ✓ Synced to local machine"
else
    echo "   ⚠ Tunnel not available (will sync when tunnel is established)"
fi

# ---- Done ----
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   ✅ Installation complete!                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "Available commands:"
echo "  /save    - Save session context + sync"
echo "  /recall  - Review full memory state"
echo "  /mac     - Run commands on local machine"
echo ""
echo "Memory is auto-loaded on every message (via hook)."
echo "Restart Claude Code to activate."
