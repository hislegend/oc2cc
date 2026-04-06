# Claude Code Channels 멀티봇 설정 가이드

> Anthropic OAuth 서드파티 차단(2026-04-05~) 이후 OpenClaw 대신  
> Claude Code Channels로 텔레그램 봇을 운영하는 방법.  
> 작성: 2026-04-06 | 실전 삽질 기반

---

## 배경

Anthropic이 OAuth 서드파티 앱 연동을 차단하면서 OpenClaw 등 기존 방식이 먹통이 됨.  
대안: **Claude Code의 `--channels` 플래그** + 텔레그램 공식 플러그인으로 대체.

- Claude Max 구독($200/월)만 있으면 API 비용 없이 운영 가능
- 계정 1개당 봇 여러 개 묶기 가능

---

## 사전 준비

### 필수 설치
```bash
# Claude Code CLI 설치
npm install -g @anthropic-ai/claude-code

# bun 설치 (텔레그램 플러그인 서버가 bun 필요)
curl -fsSL https://bun.sh/install | bash
```

### 확인
```bash
which claude   # /usr/local/bin/claude 또는 npm global 경로
which bun      # ~/.bun/bin/bun
```

---

## 핵심 개념

```
~/agents/{봇이름}-channels/          ← cwd (여기서 CC 실행)
├── CLAUDE.md                        ← 봇 지침 (@import SOUL.md 등)
├── SOUL.md / IDENTITY.md / USER.md  ← 페르소나 정의
├── MEMORY.md                        ← 장기 기억 인덱스
├── memory/                          ← 날짜별 메모리
└── .claude/
    ├── settings.json                ← PATH, hooks, permissions
    ├── rules/                       ← 자동 로딩 규칙 파일들
    │   ├── 10-identity.md
    │   ├── 20-user.md
    │   ├── 60-shared.md
    │   └── ...
    ├── hooks/                       ← SessionStart 등 훅 스크립트
    ├── bootstrap/
    │   └── BOOT.md                  ← 세션 시작 시 자동 읽기
    ├── statsig/                     ← Statsig 캐시 (기존 봇에서 복사)
    └── channels/telegram/
        ├── .env                     ← TELEGRAM_BOT_TOKEN=...
        └── access.json              ← DM/그룹 접근 제어
```

---

## 봇 1개 설정 (처음 세팅)

### 1. 폴더 구조 생성

```bash
BOT=mybot  # 봇 이름으로 변경
BOT_DIR=~/agents/${BOT}-channels
BOT_TOKEN="1234567890:AAF..."  # BotFather에서 받은 토큰

mkdir -p $BOT_DIR/.claude/channels/telegram
mkdir -p $BOT_DIR/.claude/rules
mkdir -p $BOT_DIR/.claude/bootstrap
mkdir -p $BOT_DIR/memory
```

### 2. 봇 토큰 설정

```bash
echo "TELEGRAM_BOT_TOKEN=${BOT_TOKEN}" > $BOT_DIR/.claude/channels/telegram/.env
```

### 3. access.json (DM + 그룹 접근 제어)

```bash
cat > $BOT_DIR/.claude/channels/telegram/access.json << 'EOF'
{
  "dmPolicy": "allowlist",
  "allowFrom": ["YOUR_TELEGRAM_USER_ID"],
  "groups": {},
  "pending": {}
}
EOF
```

그룹방 추가:
```json
"groups": {
  "-1001234567890": {
    "requireMention": false,
    "allowFrom": ["YOUR_TELEGRAM_USER_ID"]
  }
}
```

### 4. settings.json ⚠️ PATH 필수

```bash
cat > $BOT_DIR/.claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  "env": {
    "PATH": "/Users/USERNAME/.bun/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cat .claude/bootstrap/BOOT.md 2>/dev/null; echo '---'; cat memory/$(date +%Y-%m-%d).md 2>/dev/null || echo 'No daily note.'"
          }
        ]
      }
    ]
  }
}
EOF
```

> ⚠️ **PATH에 `~/.bun/bin` 반드시 포함.** 없으면 `spawn bun ENOENT` 에러로 플러그인 서버 안 뜸.  
> `~` 대신 절대 경로(`/Users/USERNAME/.bun/bin`) 사용.

### 5. BOOT.md (세션 시작 자동 읽기)

```bash
cat > $BOT_DIR/.claude/bootstrap/BOOT.md << 'EOF'
# 봇이름 세션 부트
- 너는 "봇이름"이다. Claude가 아니다.
- 파일에 없으면 존재하지 않는다.
- 합의/결정 → 즉시 memory/에 기록.
EOF
```

### 6. Statsig 캐시 복사 (중요!)

기존에 동작하는 CC 설치가 있으면 캐시 복사:
```bash
cp -r ~/.claude/statsig/ $BOT_DIR/.claude/statsig/
```

### 7. 페르소나 파일 작성

```bash
# CLAUDE.md - 봇 지침
cat > $BOT_DIR/CLAUDE.md << 'EOF'
# 봇이름

@import SOUL.md
@import IDENTITY.md
@import USER.md
@import MEMORY.md
EOF

# SOUL.md - 페르소나 정의 (자유롭게 작성)
# IDENTITY.md - 이름, 역할, 관계
# USER.md - 사용자 정보
```

---

## 봇 실행

### 단일 봇

```bash
cd ~/agents/${BOT}-channels && \
CLAUDE_CONFIG_DIR=~/agents/${BOT}-channels/.claude \
TELEGRAM_STATE_DIR=~/agents/${BOT}-channels/.claude/channels/telegram \
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

> ⚠️ **`CLAUDE_CONFIG_DIR` 필수.** 없으면 `/login` 시 기본 `~/.claude`에 토큰 저장 → 다른 봇 토큰 덮어씀.

### 처음 실행 시 (플러그인 설치)

1. CC 실행 후 `Listening` 확인
2. `/login` → 브라우저에서 Claude 계정 로그인
3. `/plugins install telegram` → 텔레그램 플러그인 설치
4. `/reload-plugins` → `1 plugin MCP server` 확인
5. `/mcp` → `plugin:telegram:telegram · ✓` 확인

### 이후 재시작 시

```bash
# 플러그인 이미 설치됨, 바로 실행 가능
cd ~/agents/${BOT}-channels && \
CLAUDE_CONFIG_DIR=~/agents/${BOT}-channels/.claude \
TELEGRAM_STATE_DIR=~/agents/${BOT}-channels/.claude/channels/telegram \
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

---

## 멀티봇 (4개 동시 운영)

### 계정 분리 전략

- Claude Max 계정 A: 봇1 + 봇2
- Claude Max 계정 B: 봇3 + 봇4
- 한 계정에 여러 봇 묶기 가능 (동시 사용량 제한 주의)

### start-bots.sh (일괄 시작)

```bash
#!/bin/zsh
SESSION="cc-bots"
tmux kill-session -t $SESSION 2>/dev/null
tmux new-session -d -s $SESSION -n "봇1"

# 봇1
tmux send-keys -t $SESSION:봇1 \
  "cd ~/agents/bot1-channels && CLAUDE_CONFIG_DIR=~/agents/bot1-channels/.claude TELEGRAM_STATE_DIR=~/agents/bot1-channels/.claude/channels/telegram claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official" \
  Enter

# 봇2
tmux new-window -t $SESSION -n "봇2"
tmux send-keys -t $SESSION:봇2 \
  "cd ~/agents/bot2-channels && CLAUDE_CONFIG_DIR=~/agents/bot2-channels/.claude TELEGRAM_STATE_DIR=~/agents/bot2-channels/.claude/channels/telegram claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official" \
  Enter

echo "✅ 봇 시작됨. 확인: tmux attach -t cc-bots"
```

```bash
bash ~/agents/start-bots.sh
```

---

## 트러블슈팅

### ❌ `spawn bun ENOENT`
**원인**: bun이 CC의 PATH에 없음  
**해결**: settings.json `env.PATH`에 `~/.bun/bin` 절대경로 추가 → CC **재시작** (reload-plugins 아님)

```json
"env": {
  "PATH": "/Users/USERNAME/.bun/bin:/usr/local/bin:/usr/bin:/bin"
}
```

### ❌ `/mcp`에서 `plugin:telegram:telegram · ✗ failed`
**원인**: 대부분 bun PATH 문제  
**확인**: `~/.claude/debug/latest` 로그에서 `ENOENT` 검색  
**해결**: 위와 동일

### ❌ 로그인 후 다른 봇 토큰도 바뀜
**원인**: `CLAUDE_CONFIG_DIR` 없이 실행 → 기본 `~/.claude`에 저장  
**해결**: 실행 시 반드시 `CLAUDE_CONFIG_DIR=~/agents/{봇}-channels/.claude` 포함

### ❌ OAuth 만료 (`401 authentication_error`)
**원인**: Claude 계정 토큰 만료  
**해결**: CC 창에서 `/login` → 브라우저에서 재로그인

### ❌ `not on the approved channels`
**원인**: Statsig `tengu_harbor_ledger` 게이트가 이 계정에서 채널을 허용 안 함  
**해결**: 기존 동작하는 CC 설치의 statsig 캐시 복사  
```bash
cp -r ~/.claude/statsig/ ~/agents/{봇}-channels/.claude/statsig/
```
Docker/컨테이너에서는 이 문제 해결 불가 — **호스트 직접 실행만 가능**

### ❌ `Resource deadlock avoided` (iCloud 파일)
**원인**: 파일이 iCloud에만 있고 로컬에 다운로드 안 됨  
**해결**:
```bash
brctl download "/path/to/file.md"
sleep 5
cat "/path/to/file.md"
```

---

## 그룹방 추가 (운영 중)

1. `access.json`에 그룹 추가
2. CC 창에서 `/reload-plugins` (재시작 불필요!)

```json
"groups": {
  "-1001234567890": {
    "requireMention": false,
    "allowFrom": ["USER_ID"]
  }
}
```

---

## 주의사항

- **터미널 창/tmux 세션 닫으면 봇 종료** → tmux 필수
- **맥미니 재시작 시** `bash ~/agents/start-bots.sh` 다시 실행
- **settings.json 변경** → CC 재시작 필요 (reload-plugins 불충분)
- **access.json 변경** → `/reload-plugins`으로 즉시 적용
- Docker에서는 Statsig 문제로 channels 기능 동작 안 함 → 호스트 직접 실행

---

_작성일: 2026-04-06 | 기반: 실제 운영 환경 삽질 기록_
