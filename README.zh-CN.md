# claude-memory-bridge

[Claude Code](https://claude.ai/code) 的跨会话持久记忆系统。让 Claude 在多个 SSH 窗口和会话之间保持上下文连续。

[English](README.md) | **中文**

> **问题**：每次打开新 SSH 窗口或启动新的 Claude Code 会话，Claude 都会遗忘一切——你的环境配置、正在做的工作、甚至它自身的能力。
>
> **方案**：一个轻量级的记忆层，在每条消息发送时自动加载上下文，并在服务器与本地机器之间双向同步。

## 工作原理

```
┌─────────────────────────────────────────────┐
│  SSH 窗口 1 (Claude Code)                   │
│  SSH 窗口 2 (Claude Code)  ── 读写记忆 ────┤
│  SSH 窗口 N (Claude Code)                   │
└──────────────────┬──────────────────────────┘
                   │
         ┌─────────▼──────────┐
         │  服务器端记忆        │
         │  ~/.claude/         │
         │  └─ cross-session/  │
         │     ├─ capabilities │  ← Claude 能做什么
         │     ├─ journal      │  ← 做过什么（仅追加）
         │     └─ context      │  ← 正在做什么
         └─────────┬──────────┘
                   │ SSH 反向隧道
                   │ 自动同步
         ┌─────────▼──────────┐
         │  本地机器            │
         │  ~/claude-memory/   │
         │  （镜像备份）        │
         └────────────────────┘
```

### 组件一览

| 组件 | 用途 |
|------|------|
| **UserPromptSubmit Hook** | 每次发消息时自动注入记忆到对话上下文 |
| **PostToolUse Hook** | 文件变更后自动同步到本地机器 |
| **capabilities.md** | Claude 的能力清单（SSH 隧道、可用服务等） |
| **journal.md** | 会话日志，仅追加——记录做了什么、何时做的 |
| **active-context.md** | 当前工作状态，每次更新时覆盖写入 |
| **Slash Commands** | `/save`、`/recall`、`/mac` 三个快捷命令 |

## 前置条件

- 一台运行 [Claude Code](https://claude.ai/code) 的远程服务器
- 从本地机器到服务器的 SSH 反向隧道
- 两台机器都安装了 `rsync`
- 服务器上安装了 `python3`（安装脚本中处理 JSON 需要）

### 建立 SSH 反向隧道

从本地机器执行：
```bash
# -R 将服务器的 2222 端口绑定到本地的 22 端口
ssh -R 2222:localhost:22 user@your-server
```

如需持久化，可在 `~/.ssh/config` 中添加：
```
Host your-server
    RemoteForward 2222 localhost:22
```

## 安装

```bash
git clone https://github.com/onionpig001/claude-memory-bridge.git
cd claude-memory-bridge
bash install.sh
```

安装脚本会询问以下信息：
- **SSH 隧道端口**（默认：2222）
- **本地机器 SSH 用户名**
- **本地机器操作系统**（默认：macOS）
- **本地记忆备份目录**（默认：~/claude-memory）

然后自动完成：
1. 在 `~/.claude/cross-session/` 创建记忆文件
2. 安装 slash commands 到 `~/.claude/commands/`
3. 在 `~/.claude/settings.json` 中配置 hooks
4. 在 `~/CLAUDE.md` 中追加能力说明
5. 测试隧道连通性并执行首次同步

**安装完成后需重启 Claude Code。**

## 使用方式

### 自动模式（零操作）

照常使用 Claude Code 即可。Hook 会在你每次发送消息时自动加载记忆。Claude 将知道：
- 它有哪些能力（SSH 隧道、可访问的服务）
- 上一次会话你在做什么
- 最近完成了哪些工作

### Slash Commands

| 命令 | 说明 |
|------|------|
| `/save` | 手动保存当前上下文 + 同步到本地机器 |
| `/recall` | 展示完整的记忆状态（能力、上下文、历史、隧道状态） |
| `/mac <command>` | 通过 SSH 隧道在本地机器上执行命令 |

### 示例

```
> /mac ls ~/Desktop
# 列出本地机器桌面上的文件

> /recall
# 展示完整记忆状态、隧道连通性、历史记录

> /save
# 保存当前工作上下文并同步
```

## 卸载

```bash
cd claude-memory-bridge
bash uninstall.sh
```

卸载会清除服务器端所有组件，本地备份（`~/claude-memory/`）会保留。

## 文件结构

```
claude-memory-bridge/
├── install.sh              # 交互式安装脚本
├── uninstall.sh            # 卸载脚本
├── templates/
│   ├── capabilities.md     # 能力清单模板
│   ├── journal.md          # 会话日志模板
│   ├── active-context.md   # 活跃上下文模板
│   ├── load-context.sh     # Hook 加载脚本模板
│   ├── sync-to-local.sh    # 同步脚本模板
│   └── claude-md-snippet.md # CLAUDE.md 追加片段模板
├── commands/
│   ├── save.md             # /save 命令定义
│   ├── recall.md           # /recall 命令定义
│   └── mac.md              # /mac 命令定义
└── README.md
```

## 记忆流转过程

```
你发送一条消息
    ↓
UserPromptSubmit hook 触发
    ↓
load-context.sh 执行 → 注入 能力清单 + 当前上下文 + 日志
    ↓
Claude 读取注入的上下文 → 恢复所有历史会话信息
    ↓
Claude 执行工作 → 写入/编辑文件
    ↓
PostToolUse hook 触发
    ↓
sync-to-local.sh 执行 → rsync 同步到本地机器
    ↓
你输入 /save（或 Claude 主动更新）
    ↓
journal.md 追加记录 + active-context.md 更新 + 同步完成
```

## 已知限制

- **隧道依赖**：记忆同步需要 SSH 反向隧道保持连接。隧道断开时同步会静默跳过（不会丢失数据——服务器端副本为权威源）。
- **Hook 延迟**：`UserPromptSubmit` hook 在每条消息时运行。如果记忆文件非常大，会有轻微延迟。建议定期清理 journal.md。
- **单写者**：如果两个窗口同时更新记忆，以最后写入为准。实际使用中很少出现，因为通常只在一个窗口中工作。

## 许可证

MIT

---

使用 [Claude Code](https://claude.ai/code) 构建
