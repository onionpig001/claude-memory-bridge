
## Claude Environment Capabilities (claude-memory-bridge)

### SSH Reverse Tunnel → Local Machine
Local machine is connected via SSH reverse tunnel, allowing Claude to execute commands remotely.
- **Command**: `ssh -p {{TUNNEL_PORT}} {{REMOTE_USER}}@localhost`
- **Username**: {{REMOTE_USER}}
- **Note**: Tunnel requires active SSH connection; test with `ssh -p {{TUNNEL_PORT}} {{REMOTE_USER}}@localhost "echo ok"` before use

### Cross-Session Memory System
On every new session, **read cross-session memory first** to restore context:
1. `{{CROSS_SESSION_DIR}}/active-context.md` — current work state (highest priority)
2. `{{CROSS_SESSION_DIR}}/journal.md` — session journal (read last 50 lines)
3. `{{CROSS_SESSION_DIR}}/capabilities.md` — full capabilities registry

**After completing important work**, you must:
1. Append to journal.md (record what was done)
2. Update active-context.md (current state)
3. Sync: `bash {{CROSS_SESSION_DIR}}/sync-to-local.sh`
