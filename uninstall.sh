#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
CROSS_SESSION_DIR="$CLAUDE_DIR/cross-session"

echo "╔══════════════════════════════════════════════╗"
echo "║   claude-memory-bridge uninstaller           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

echo "This will remove:"
echo "  - $CROSS_SESSION_DIR/"
echo "  - $CLAUDE_DIR/commands/save.md"
echo "  - $CLAUDE_DIR/commands/recall.md"
echo "  - $CLAUDE_DIR/commands/mac.md"
echo "  - Hooks from $CLAUDE_DIR/settings.json"
echo "  - claude-memory-bridge section from ~/CLAUDE.md"
echo ""
echo "Note: Local machine backup (~/claude-memory/) will NOT be removed."
echo ""
read -p "Proceed? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Remove cross-session directory
if [ -d "$CROSS_SESSION_DIR" ]; then
    rm -rf "$CROSS_SESSION_DIR"
    echo "✓ Removed $CROSS_SESSION_DIR"
fi

# Remove commands
for cmd in save.md recall.md mac.md; do
    if [ -f "$CLAUDE_DIR/commands/$cmd" ]; then
        rm "$CLAUDE_DIR/commands/$cmd"
        echo "✓ Removed $CLAUDE_DIR/commands/$cmd"
    fi
done

# Remove hooks from settings.json
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    python3 -c "
import json
with open('$SETTINGS_FILE', 'r') as f:
    d = json.load(f)
if 'hooks' in d:
    del d['hooks']
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write('\n')
" 2>/dev/null && echo "✓ Removed hooks from settings.json" || echo "⚠ Could not update settings.json"
fi

# Remove CLAUDE.md section
CLAUDE_MD="$HOME/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
    python3 -c "
with open('$CLAUDE_MD', 'r') as f:
    content = f.read()
start = content.find('## Claude Environment Capabilities (claude-memory-bridge)')
if start != -1:
    # Find next ## heading or end of file
    rest = content[start+1:]
    next_section = rest.find('\n## ')
    if next_section != -1:
        content = content[:start] + rest[next_section+1:]
    else:
        content = content[:start].rstrip()
    with open('$CLAUDE_MD', 'w') as f:
        f.write(content + '\n')
" 2>/dev/null && echo "✓ Cleaned CLAUDE.md" || echo "⚠ Could not update CLAUDE.md"
fi

echo ""
echo "✅ Uninstalled. Restart Claude Code to take effect."
