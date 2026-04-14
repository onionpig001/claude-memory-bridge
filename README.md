# claude-memory-bridge

Cross-session persistent memory for [Claude Code](https://claude.ai/code). Makes Claude remember context across multiple SSH windows and sessions.

> **Problem**: Every time you open a new SSH window or start a new Claude Code session, Claude forgets everything — your environment setup, what you were working on, even its own capabilities.
>
> **Solution**: A lightweight memory layer that auto-loads context on every message and syncs between server and local machine.

## How It Works

```
┌─────────────────────────────────────────────┐
│  SSH Window 1 (Claude Code)                 │
│  SSH Window 2 (Claude Code)  ── read/write ─┤
│  SSH Window N (Claude Code)                 │
└──────────────────┬──────────────────────────┘
                   │
         ┌─────────▼──────────┐
         │  Server Memory      │
         │  ~/.claude/         │
         │  └─ cross-session/  │
         │     ├─ capabilities │  ← what Claude can do
         │     ├─ journal      │  ← what happened (append-only)
         │     └─ context      │  ← what's happening now
         └─────────┬──────────┘
                   │ SSH reverse tunnel
                   │ auto-sync
         ┌─────────▼──────────┐
         │  Local Machine      │
         │  ~/claude-memory/   │
         │  (mirror backup)    │
         └────────────────────┘
```

### Components

| Component | Purpose |
|-----------|---------|
| **UserPromptSubmit Hook** | Auto-injects memory into every conversation |
| **PostToolUse Hook** | Auto-syncs to local machine after file changes |
| **capabilities.md** | Registry of Claude's abilities (SSH tunnel, services, etc.) |
| **journal.md** | Append-only session log — what was done and when |
| **active-context.md** | Current work state — overwritten each update |
| **Slash Commands** | `/save`, `/recall`, `/mac` for manual control |

## Prerequisites

- A remote server running [Claude Code](https://claude.ai/code)
- SSH reverse tunnel from your local machine to the server
- `rsync` installed on both machines
- `python3` on the server (for JSON manipulation during install)

### Setting up the SSH Reverse Tunnel

From your local machine:
```bash
# -R binds server port 2222 to your local SSH port 22
ssh -R 2222:localhost:22 user@your-server
```

To make it persistent, add to your `~/.ssh/config`:
```
Host your-server
    RemoteForward 2222 localhost:22
```

## Installation

```bash
git clone https://github.com/onionpig001/claude-memory-bridge.git
cd claude-memory-bridge
bash install.sh
```

The installer will ask for:
- **SSH tunnel port** (default: 2222)
- **Local machine SSH username**
- **Local machine OS** (default: macOS)
- **Local memory directory** (default: ~/claude-memory)

Then it automatically:
1. Creates memory files in `~/.claude/cross-session/`
2. Installs slash commands to `~/.claude/commands/`
3. Configures hooks in `~/.claude/settings.json`
4. Appends capability docs to `~/CLAUDE.md`
5. Tests the tunnel and runs initial sync

**Restart Claude Code after installation.**

## Usage

### Automatic (zero effort)

Just use Claude Code normally. The hook automatically loads memory on every message you send. Claude will know:
- What capabilities it has (SSH tunnel, services)
- What you were working on last session
- What was recently completed

### Slash Commands

| Command | Description |
|---------|-------------|
| `/save` | Manually save current context + sync to local machine |
| `/recall` | Display full memory state (capabilities, context, history, tunnel status) |
| `/mac <command>` | Execute a command on your local machine via SSH tunnel |

### Examples

```
> /mac ls ~/Desktop
# Lists files on your local Desktop

> /recall
# Shows full memory state, tunnel status, history

> /save
# Saves current work context and syncs
```

## Uninstall

```bash
cd claude-memory-bridge
bash uninstall.sh
```

This removes all server-side components. Your local backup (`~/claude-memory/`) is preserved.

## File Structure

```
claude-memory-bridge/
├── install.sh              # Interactive installer
├── uninstall.sh            # Clean uninstaller
├── templates/
│   ├── capabilities.md     # Capability registry template
│   ├── journal.md          # Session journal template
│   ├── active-context.md   # Active context template
│   ├── load-context.sh     # Hook loader script template
│   ├── sync-to-local.sh    # Sync script template
│   └── claude-md-snippet.md # CLAUDE.md addition template
├── commands/
│   ├── save.md             # /save slash command
│   ├── recall.md           # /recall slash command
│   └── mac.md              # /mac slash command
└── README.md
```

## How Memory Flows

```
You type a message
    ↓
UserPromptSubmit hook fires
    ↓
load-context.sh runs → injects capabilities + context + journal
    ↓
Claude reads injected context → knows everything from prior sessions
    ↓
Claude does work → writes/edits files
    ↓
PostToolUse hook fires
    ↓
sync-to-local.sh runs → rsync to local machine
    ↓
You type /save (or Claude remembers to update)
    ↓
journal.md appended + active-context.md updated + synced
```

## Limitations

- **Tunnel dependency**: Memory sync requires an active SSH reverse tunnel. If the tunnel drops, sync silently skips (no data loss — server copy is authoritative).
- **Hook timing**: The `UserPromptSubmit` hook runs on every message. For very large memory files, this adds a small delay. Keep journal.md pruned if it grows large.
- **Single-writer**: If two windows update memory simultaneously, the last write wins. In practice this is rare since you typically focus on one window at a time.

## License

MIT

---

Built with [Claude Code](https://claude.ai/code) 🤖
