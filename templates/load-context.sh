#!/bin/bash
# Cross-session memory loader - called by UserPromptSubmit hook
# Output is injected into Claude's conversation context

CROSS_SESSION_DIR="{{CROSS_SESSION_DIR}}"

echo "=== Cross-session memory loaded ==="
echo ""

# 1. Capabilities (static, rarely changes)
if [ -f "$CROSS_SESSION_DIR/capabilities.md" ]; then
    echo "--- capabilities ---"
    cat "$CROSS_SESSION_DIR/capabilities.md"
    echo ""
fi

# 2. Active context (current state, highest priority)
if [ -f "$CROSS_SESSION_DIR/active-context.md" ]; then
    echo "--- active-context ---"
    cat "$CROSS_SESSION_DIR/active-context.md"
    echo ""
fi

# 3. Session journal (last 30 lines)
if [ -f "$CROSS_SESSION_DIR/journal.md" ]; then
    echo "--- recent-journal (last 30 lines) ---"
    tail -30 "$CROSS_SESSION_DIR/journal.md"
    echo ""
fi

echo "=== Memory load complete ==="
