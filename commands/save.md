---
allowed-tools: Read, Write, Edit, Bash(bash {{CROSS_SESSION_DIR}}/sync-to-local.sh), Bash(date *)
description: Save current session context to cross-session memory, sync to local machine
---

## Context

- Current active context: !`cat {{CROSS_SESSION_DIR}}/active-context.md`
- Recent session journal: !`tail -20 {{CROSS_SESSION_DIR}}/journal.md`
- Current time: !`date '+%Y-%m-%d %H:%M'`

## Your task

Save cross-session memory by performing these three steps:

### 1. Append to session journal
Read `{{CROSS_SESSION_DIR}}/journal.md` and append a new entry at the end:
```
## {current datetime}
- {important work completed in this session, one item per line}
```
Only record substantive work, not casual conversation.

### 2. Update active context
Overwrite `{{CROSS_SESSION_DIR}}/active-context.md` with:
- **Last Updated**: current time
- **In Progress**: current unfinished work (if any)
- **Recently Completed**: what was just done
- **Environment Status**: SSH tunnel, service status, and other key info

### 3. Sync to local machine
Run `bash {{CROSS_SESSION_DIR}}/sync-to-local.sh`. If tunnel is unavailable, inform user but don't error.

After completion, briefly inform the user what was saved.
