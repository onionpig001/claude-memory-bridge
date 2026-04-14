#!/bin/bash
# Sync server-side cross-session memory to local machine
# Via SSH reverse tunnel

REMOTE_USER="{{REMOTE_USER}}"
REMOTE_PORT="{{TUNNEL_PORT}}"
REMOTE_DIR="{{LOCAL_MEMORY_DIR}}/"
LOCAL_DIR="{{CROSS_SESSION_DIR}}/"

# Check if tunnel is available
if ! ssh -p "$REMOTE_PORT" -o ConnectTimeout=3 "$REMOTE_USER@localhost" "echo ok" &>/dev/null; then
    # Silently skip if tunnel is not available
    exit 0
fi

# Ensure remote directory exists
ssh -p "$REMOTE_PORT" "$REMOTE_USER@localhost" "mkdir -p {{LOCAL_MEMORY_DIR}}"

# Sync
rsync -az --delete \
    -e "ssh -p $REMOTE_PORT" \
    "$LOCAL_DIR" \
    "$REMOTE_USER@localhost:$REMOTE_DIR"
