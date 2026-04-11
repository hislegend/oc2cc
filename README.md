# oc2cc

> **OpenClaw → Claude Code Channels** migration toolkit  
> Run multiple Telegram bots on Claude Code — no API costs, no OAuth dependencies.

[한국어](./README.ko.md)

> **v1.2** — Forum topic support, auto-recovery, wildcard permissions, plugin cache cleanup.  
> Already set up? See [UPGRADE.md](./UPGRADE.md) for what's new.

---

## Why oc2cc?

Anthropic blocked third-party OAuth on April 5, 2026.  
OpenClaw and similar gateway products stopped working overnight.

**oc2cc** is a battle-tested migration guide and starter kit for moving your OpenClaw multi-bot setup to **Claude Code Channels** — the official, native way to run Claude as a Telegram bot.

## What you get

- ✅ Step-by-step migration guide (OpenClaw → CC Channels)
- ✅ Upgrade guide for existing users ([UPGRADE.md](./UPGRADE.md))
- ✅ Bot workspace template (SOUL.md, IDENTITY.md, USER.md, MEMORY.md)
- ✅ `settings.json` with lifecycle hooks (SessionStart, PreCompact)
- ✅ `start-bots.sh` — launch all bots in one command via tmux
- ✅ Troubleshooting guide (bun PATH, CLAUDE_CONFIG_DIR, Statsig, iCloud)
- ✅ Multi-account strategy (run 4+ bots on 2 Claude Max accounts)

## Quick Start

```bash
git clone https://github.com/hislegend/oc2cc.git
cd oc2cc
```

Then follow [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md).

## Prerequisites

- Claude Code CLI: `npm install -g @anthropic-ai/claude-code`
- bun: `curl -fsSL https://bun.sh/install | bash`
- Claude Max subscription ($200/mo) — one account can run 2–3 bots

## Structure

```
oc2cc/
├── MIGRATION-GUIDE.md          ← Full OpenClaw → CC Channels guide
├── UPGRADE.md                  ← v1.1 upgrade guide for existing users
├── BOT-COMMANDS.md             ← Per-bot start commands reference
├── start-bots.sh               ← Launch all bots via tmux (+ cache cleanup)
└── templates/
    ├── scripts/
    │   ├── check-bots.sh       ← Auto-recovery via cron
    │   └── cleanup-telegram-ghosts.sh  ← Kill stale polling processes
    └── bot-workspace/          ← Copy this for each new bot
        ├── CLAUDE.md
        ├── SOUL.md
        ├── IDENTITY.md
        ├── USER.md
        ├── MEMORY.md
        └── .claude/
            ├── settings.json
            ├── rules/
            │   ├── 10-identity.md
            │   └── 60-shared.md
            ├── bootstrap/
            │   └── BOOT.md
            └── channels/
                └── telegram/
                    ├── .env.example
                    └── access.json.example
```

## Key Differences from OpenClaw

| Feature | OpenClaw | CC Channels |
|---|---|---|
| Auth | OAuth (blocked) | Claude account login |
| Cost | API usage | Claude Max subscription |
| Multi-bot | Built-in | CLAUDE_CONFIG_DIR per bot |
| Memory | OpenClaw managed | File-based (MEMORY.md) |
| Rules | AGENTS.md | .claude/rules/*.md |

## Troubleshooting

See [MIGRATION-GUIDE.md#troubleshooting](./MIGRATION-GUIDE.md#troubleshooting) for:
- `spawn bun ENOENT` — bun PATH fix
- Token overwrite between bots — CLAUDE_CONFIG_DIR fix
- `not on the approved channels` — Statsig cache fix
- iCloud file deadlock — brctl download fix

## License

MIT
