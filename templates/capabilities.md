# Claude Capabilities Registry

## Environment
- **Server**: {{SERVER_OS}}
- **Local Machine**: {{LOCAL_OS}}
- **Connection**: User connects via SSH, reverse tunnel back to local machine

## SSH Reverse Tunnel
- **Command**: `ssh -p {{TUNNEL_PORT}} {{REMOTE_USER}}@localhost`
- **Port**: {{TUNNEL_PORT}} → Local Machine SSH
- **Username**: {{REMOTE_USER}}
- **Usage**: Execute commands on local machine from server

## Memory System Paths
- **Server memory**: {{CROSS_SESSION_DIR}}/
- **Local backup**: {{LOCAL_MEMORY_DIR}}/
- **Sync method**: rsync over SSH tunnel (port {{TUNNEL_PORT}})

## Notes
- Reverse tunnel depends on active SSH connection; unavailable when disconnected
- Local commands via `ssh -p {{TUNNEL_PORT}} {{REMOTE_USER}}@localhost "command"`
