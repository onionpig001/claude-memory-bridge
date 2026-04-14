---
allowed-tools: Read, Bash(cat *), Bash(ssh -p {{TUNNEL_PORT}} {{REMOTE_USER}}@localhost *)
description: Review cross-session memory - show current context and history
---

## Context

- Capabilities: !`cat {{CROSS_SESSION_DIR}}/capabilities.md`
- Active context: !`cat {{CROSS_SESSION_DIR}}/active-context.md`
- Full session journal: !`cat {{CROSS_SESSION_DIR}}/journal.md`
- SSH tunnel status: !`ssh -p {{TUNNEL_PORT}} -o ConnectTimeout=3 {{REMOTE_USER}}@localhost "echo 'tunnel OK'" 2>&1 || echo "tunnel DOWN"`

## Your task

Present the complete cross-session memory state to the user:

1. **Environment Capabilities**: available capabilities (SSH tunnel status, accessible services)
2. **Current State**: in-progress and recently completed work
3. **History**: chronological summary of all session records
4. **Sync Status**: whether the tunnel is available

Use a concise format for quick overview.
