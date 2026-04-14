---
allowed-tools: Bash(ssh -p {{TUNNEL_PORT}} {{REMOTE_USER}}@localhost *)
description: Execute commands on local machine via SSH reverse tunnel
---

## Context

- Tunnel status: !`ssh -p {{TUNNEL_PORT}} -o ConnectTimeout=3 {{REMOTE_USER}}@localhost "echo 'tunnel OK'" 2>&1 || echo "tunnel DOWN"`

## Your task

The user wants to execute an operation on their local machine. Run it via SSH reverse tunnel: `ssh -p {{TUNNEL_PORT}} {{REMOTE_USER}}@localhost "command"`.

User's request: $ARGUMENTS

If the tunnel is unavailable, inform the user that the tunnel is disconnected and they need to re-establish their SSH connection.
If the user didn't provide a specific command, ask what they want to do on their local machine.
