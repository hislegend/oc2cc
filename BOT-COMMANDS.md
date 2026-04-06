# CC 봇 개별 실행 명령어

> 맥미니 재시작 또는 봇 개별 재시작 시 참조
> 일괄 시작: `bash ~/agents/start-bots.sh`

---

## 뉴엔도 (@endo_claude_bot)
- **계정**: jk1
- **봇토큰**: `~/.claude/channels/telegram/.env`

```bash
cd ~/agents/devbot-channels && \
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

> CLAUDE_CONFIG_DIR 생략 → 기본 `~/.claude` 사용 (뉴엔도 전용)

---

## 토네가와 (@tonegawa_openclaw_bot)
- **계정**: jk1
- **봇토큰**: `~/agents/tonegawa-channels/.claude/channels/telegram/.env`
- **그룹**: 창작방 `-1003716946094`

```bash
cd ~/agents/tonegawa-channels && \
CLAUDE_CONFIG_DIR=~/agents/tonegawa-channels/.claude \
TELEGRAM_STATE_DIR=~/agents/tonegawa-channels/.claude/channels/telegram \
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

---

## 이치죠 (@ichijou_openclaw_bot 또는 실제 username 확인)
- **계정**: jk2
- **봇토큰**: `~/agents/ichijou-channels/.claude/channels/telegram/.env`
- **그룹**: 디자인실 `-1003899620039`

```bash
cd ~/agents/ichijou-channels && \
CLAUDE_CONFIG_DIR=~/agents/ichijou-channels/.claude \
TELEGRAM_STATE_DIR=~/agents/ichijou-channels/.claude/channels/telegram \
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

---

## 쿠로사키 (@kurosaki_openclaw_bot 또는 실제 username 확인)
- **계정**: jk2
- **봇토큰**: `~/agents/kurosaki-channels/.claude/channels/telegram/.env`
- **그룹**: 비즈니스방 `-1003871541930`

```bash
cd ~/agents/kurosaki-channels && \
CLAUDE_CONFIG_DIR=~/agents/kurosaki-channels/.claude \
TELEGRAM_STATE_DIR=~/agents/kurosaki-channels/.claude/channels/telegram \
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
Ctrl+B, 숫자키 (0=뉴엔도, 1=토네가와, 2=이치죠, 3=쿠로사키)

# 세션 유지하며 detach
Ctrl+B, d
```
