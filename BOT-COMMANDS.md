# CC 봇 개별 실행 명령어

> 맥미니 재시작 또는 봇 개별 재시작 시 참조
> 일괄 시작: `bash ~/agents/start-bots.sh`

---

## Bot 1 (@your_bot1_username)
- **계정**: account-A
- **봇토큰**: `~/.claude/channels/telegram/.env`

```bash
cd ~/agents/bot1-channels && \
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

> CLAUDE_CONFIG_DIR 생략 → 기본 `~/.claude` 사용 (Bot 1 전용)

---

## Bot 2 (@your_bot2_username)
- **계정**: account-A
- **봇토큰**: `~/agents/bot2-channels/.claude/channels/telegram/.env`
- **그룹**: `-100XXXXXXXXXX`

```bash
cd ~/agents/bot2-channels && \
CLAUDE_CONFIG_DIR=~/agents/bot2-channels/.claude \
TELEGRAM_STATE_DIR=~/agents/bot2-channels/.claude/channels/telegram \
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

---

## Bot 3 (@your_bot3_username)
- **계정**: account-B
- **봇토큰**: `~/agents/bot3-channels/.claude/channels/telegram/.env`
- **그룹**: `-100XXXXXXXXXX`

```bash
cd ~/agents/bot3-channels && \
CLAUDE_CONFIG_DIR=~/agents/bot3-channels/.claude \
TELEGRAM_STATE_DIR=~/agents/bot3-channels/.claude/channels/telegram \
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

---

## 공통 주의사항

- **settings.json 변경** → CC 재시작 필요
- **access.json 변경** → `/reload-plugins`으로 즉시 적용
- **토큰 만료 시** → CC 창에서 `/login`
- **플러그인 에러 시** → `/mcp` 확인 → `failed`면 CC 재시작

## tmux 세션 관리

```bash
# 전체 시작
bash ~/agents/start-bots.sh

# 세션 접속
tmux attach -t cc-bots

# 특정 봇 창으로 이동 (접속 후)
Ctrl+B, 숫자키 (0=Bot1, 1=Bot2, 2=Bot3, ...)

# 세션 유지하며 detach
Ctrl+B, d
```
