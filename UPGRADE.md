# oc2cc 업그레이드 가이드

> 이미 oc2cc로 봇을 세팅한 사람을 위한 추가 설정 가이드.  
> 각 항목은 독립적이라 필요한 것만 골라서 적용할 수 있어요.  
> 최신 패치가 위에 있어요.

---

# v1.3 (2026-04-19)

## 1. 텔레그램 플러그인 0.0.6 업그레이드

### 뭐가 바뀌었나요?
텔레그램 플러그인 v0.0.6은 MCP 도구가 확장됐어요. 이전(v0.0.4)엔 `reply`만 있었는데 이제는:

- `reply` — 메시지 보내기 (기존)
- `edit_message` — 이미 보낸 메시지 수정 (중간 진행 업데이트용, 푸시 알림 없음)
- `react` — 이모지 반응 (👀 👍 ❤️ 🔥 👎 등 Telegram 허용 목록만)
- `download_attachment` — 상대가 보낸 파일(`attachment_file_id`) 다운로드

즉 긴 작업 중 중간 진행은 `edit_message`, 수신 확인은 `react`, 대화를 끊지 않고 처리 가능해요.

### 어떻게 하면 되나요?

CC 세션 안에서:
```
/plugin install telegram@claude-plugins-official
/reload-plugins
```

### ⚠️ 업그레이드 중 자주 발생하는 이슈

**(가) `.mcp.json` 누락**  
0.0.6 디렉토리는 생겼는데 `.mcp.json`이 빠지는 경우가 있어요. 이 상태에서 `/reload-plugins` 하면 MCP 서버가 로드 안 되고, 구버전 bun 프로세스가 그대로 돌아요.

**확인**:
```bash
ls ~/agents/봇-channels/.claude/plugins/cache/claude-plugins-official/telegram/0.0.6/.mcp.json
ls ~/agents/봇-channels/.claude/plugins/cache/claude-plugins-official/telegram/0.0.6/.claude-plugin/plugin.json
```

**복구 — 동작하는 다른 봇에서 전체 복사**:
```bash
rm -rf ~/agents/망가진봇-channels/.claude/plugins/cache/claude-plugins-official/telegram/0.0.6
cp -R ~/agents/정상봇-channels/.claude/plugins/cache/claude-plugins-official/telegram/0.0.6 \
      ~/agents/망가진봇-channels/.claude/plugins/cache/claude-plugins-official/telegram/
```

**(나) 구버전 bun 프로세스 잔존**  
`installed_plugins.json`은 0.0.6으로 바뀌었는데 실제 프로세스는 0.0.4 그대로인 경우:
```bash
ps aux | grep "bun run.*telegram" | grep -v grep
# --cwd 뒤 경로에서 버전 확인. 0.0.4 나오면 CC 세션 재시작 필요
```

CC 세션 종료 → 재진입하면 stdio 부모가 죽으면서 구버전 bun도 자동 정리돼요.

---

## 2. `installed_plugins.json` 중복 레코드 주의

### 뭐가 발생하나요?

`/plugin install telegram@claude-plugins-official` 실행하면 두 위치에 레코드가 생겨요:

- `~/.claude/plugins/installed_plugins.json` (global/user scope)
- `~/agents/봇-channels/.claude/plugins/installed_plugins.json` (project scope)

같은 플러그인이 **scope 다른 installPath**로 두세 번 등록되면 CC가 MCP 서버를 spawn 스킵하는 현상이 생겨요. 증상: `/reload-plugins` 출력이 "1 plugin MCP server"인데 텔레그램 MCP 도구가 세션에 뜨지 않음.

### 체크 방법

```bash
cat ~/.claude/plugins/installed_plugins.json | grep -A3 "telegram@claude-plugins-official"
cat ~/agents/봇-channels/.claude/plugins/installed_plugins.json
```

같은 projectPath·installPath 쌍이 여러 번 등장하거나, projectPath가 플러그인 캐시 서브디렉토리 같은 이상한 경로를 가리키면 corrupt.

### 해결

**한 쪽만 유지** (보통 project scope):
```bash
# 글로벌에서 해당 프로젝트 레코드만 수동 제거 (다른 프로젝트 레코드는 유지)
# ~/.claude/plugins/installed_plugins.json 편집

# 프로젝트 scope 레코드는 아래처럼 하나만:
cat > ~/agents/봇-channels/.claude/plugins/installed_plugins.json <<EOF
{
  "version": 2,
  "plugins": {
    "telegram@claude-plugins-official": [
      {
        "scope": "project",
        "projectPath": "$HOME/agents/봇-channels",
        "installPath": "$HOME/agents/봇-channels/.claude/plugins/cache/claude-plugins-official/telegram/0.0.6",
        "version": "0.0.6",
        "installedAt": "YYYY-MM-DDTHH:MM:SS.000Z",
        "lastUpdated": "YYYY-MM-DDTHH:MM:SS.000Z"
      }
    ]
  }
}
EOF
```

그 후 CC 완전 재시작.

---

## 3. `access.json` Hot Reload (재시작 없이 즉시 반영)

### 뭐가 되나요?

access.json을 수정하면 **봇 재시작 없이 즉시 반영**돼요. 그룹 추가·requireMention 토글·allowFrom 변경 같은 작업이 몇 초 안에 반영.

### 조건

환경변수 `TELEGRAM_ACCESS_MODE=static`이 **설정돼 있지 않아야** 함. 기본값은 dynamic이라 보통 그대로 두면 hot reload 됨.

**static 모드의 경우**:
- access.json이 부팅 시 한 번만 읽히고 그 후엔 파일 변경 무시
- 페어링(pending) 기능이 allowlist로 다운그레이드됨
- 빠른 iteration 중이라면 static 쓰지 말 것

### 확인

alias나 launch 스크립트에 `TELEGRAM_ACCESS_MODE=static`이 있는지 확인:
```bash
grep "TELEGRAM_ACCESS_MODE" ~/.zshrc ~/agents/*/start.sh 2>/dev/null
```

없으면 자동으로 dynamic 모드 → hot reload 작동.

### 활용

여러 그룹 추가하면서 requireMention 토글 자주 바꿔야 하는 초기 셋업 구간에서 유용해요. CC 세션 끄고 다시 켜는 시간 절약.

---

## 4. BotFather Privacy Mode — 그룹 봇-to-봇 대화 트러블슈팅

### 뭐가 안 됐나요?

두 봇(예: 엔도 + 이치죠)을 같은 그룹에 초대했는데, 이치죠 봇이 엔도 멘션해서 보낸 답글을 **엔도가 수신 못 하는** 현상.

원인: Telegram의 **Privacy Mode 기본 ON** + **봇-to-봇 이벤트 기본 차단**.

### Privacy Mode 동작

**ON (기본)**:
봇은 그룹에서 다음 4종만 수신:
- `@봇이름` 직접 멘션
- `/` 커맨드
- 봇 자신의 메시지에 대한 리플
- 서비스 메시지 (봇 추가·제거 이벤트 등)

**OFF**:
그룹의 모든 일반 메시지를 수신. 단 **다른 봇이 보낸 메시지**는 추가 권한이 있어야 받음.

### 해결 절차

**1단계 — BotFather에서 Privacy Mode OFF**:
```
@BotFather → /mybots → @봇이름 → Bot Settings → Group Privacy → Turn off
```

**2단계 — 그룹에서 봇 관리자 승격 + `Can read all messages` 권한 부여**

**3단계 — ⚠️ 봇 kick → 재초대 필수**

Privacy Mode 변경 직후 기존 그룹 멤버 상태의 봇에는 **즉시 반영 안 됨** (Telegram 클라이언트·서버 캐시). 반드시 다음을 수행:
1. 그룹에서 봇 제거 (kick)
2. 다시 초대
3. 재초대 시 새 Privacy Mode로 등록

### 검증 방법

`.claude/channels/telegram/message-store.jsonl`에서 해당 그룹의 다른 봇 메시지가 찍히는지 확인 (섹션 6 참고).

### DM만 쓸 거면 무시해도 되나요?

네. Privacy Mode는 **그룹 전용 규칙**. DM(1:1)은 영향 없음. 봇이 DM은 무조건 모두 수신.

---

## 5. `message-store.jsonl` 기반 수신 디버깅

### 뭐가 되나요?

텔레그램 플러그인 v0.0.6은 수신한 모든 메시지를 `~/agents/봇-channels/.claude/channels/telegram/message-store.jsonl`에 한 줄씩 저장해요 (jsonl 포맷). 이걸 분석해서 "왜 특정 메시지를 봇이 안 받냐"를 명확히 판정할 수 있어요.

### 활용 예시

**특정 그룹 수신 이력 전수 조회**:
```bash
grep '"chat_id": "-1003XXXXXXX"' ~/agents/봇-channels/.claude/channels/telegram/message-store.jsonl
```

**다른 봇 메시지가 내 봇 수신 큐에 들어왔는지 확인 (Privacy Mode 검증)**:
```bash
grep '"user_id": "다른_봇_id"' message-store.jsonl
# 없으면 → Telegram 봇-to-봇 필터 작동 중 (섹션 4 참고)
```

**요청이 필터에 걸리는지 수신 자체가 안 되는지 판별**:
- `message-store.jsonl`에 메시지가 있는데 봇이 응답 안 했다 → `access.json` 필터 (requireMention·allowFrom)
- `message-store.jsonl`에 메시지가 없다 → Telegram Bot API 이벤트 자체 미수신 (Privacy Mode·bot-to-bot 필터·봇 그룹 미가입 등)

### 보안 주의

`message-store.jsonl`은 평문이라 민감 정보(비밀번호·토큰·PII)가 수신되면 그대로 저장돼요. 정기적으로 로테이션하거나 민감 메시지 수신 후 수동 정리 고려. `.gitignore` 필수.

---

## 6. `research` 스킬 user scope 공유

### 뭐가 되나요?

여러 CC 봇이 **동일한 연구 방법론**(수신→수집→분석→아카이브→wiki→보고)을 자동으로 따르게 하는 user scope 스킬. 봇별로 반복 설치할 필요 없음.

### 어떻게 하면 되나요?

`~/.claude/skills/research/SKILL.md`를 한 번만 작성:

```yaml
---
name: research
description: Use when the user asks to research a topic, analyze links, collect references, or study a new tool/product (트리거 — 리서치, 연구, 조사, research). Follow the standardized pipeline to produce consistent research notes across all bots.
license: MIT
---

# Research Methodology Skill

(파이프라인 6단계 요약, frontmatter 필수 필드, 피어 리뷰 규칙, PII 금지 등을 여기 본문에)
```

그 후 모든 CC 봇이 세션 시작 시 자동 로드. 트리거 키워드(리서치·research·연구·조사·investigate·study) 감지 시 스킬이 활성화되면서 "가이드를 먼저 Read 하라"고 봇에게 지시.

### 실제 가이드 파일은 shared-knowledge에

스킬 본문은 요약만. 상세 방법론은:
```
~/.openclaw/workspace/shared-knowledge/guides/research-methodology.md
```
에 두고 스킬이 이 경로를 포인터로 안내.

shared-knowledge는 각 봇 워크스페이스에 symlink로 공유:
```bash
ln -s ~/.openclaw/workspace/shared-knowledge ~/agents/봇-channels/shared-knowledge
```

### 효과

- 신규 봇 생성해도 연구 방법론 자동 적용
- 가이드 하나 수정하면 모든 봇 즉시 반영 (symlink + user scope 스킬)
- 봇이 "까먹고 지나가는" 실수 방지 (스킬 트리거 = 강제 호출)

---

# v1.2 (2026-04-11)

## 텔레그램 Forum 토픽 지원

### 뭐가 안 됐나요?
CC 텔레그램 플러그인은 Forum 그룹의 토픽(Topic)을 구분하지 못해요. 봇이 메시지를 받아도 어느 토픽인지 모르고, 답장도 토픽 밖으로 나갈 수 있어요.

### 이걸 하면 뭐가 되나요?
- 봇이 어느 토픽에서 온 메시지인지 인식
- 답장이 올바른 토픽 안에 들어감
- 하나의 그룹에서 토픽별로 다른 주제를 나눠서 봇과 대화 가능

### 어떻게 하면 되나요?

```bash
bash templates/scripts/patch-telegram-forum.sh
```

그리고 CC에서 `/reload-plugins` 실행.

이 스크립트가 하는 일:
- 텔레그램 플러그인 server.ts에 `message_thread_id` 지원 추가
- 인바운드: 어느 토픽인지 meta에 포함
- 아웃바운드: 답장할 때 올바른 토픽으로 전송
- 멀티봇이면 다른 봇 캐시에도 자동 복사

### 주의사항
- 공식 플러그인 캐시를 직접 수정하는 거라, **플러그인 업데이트 시 초기화**됩니다
- 업데이트 후 이 스크립트를 다시 실행하면 돼요
- Forum 모드는 슈퍼그룹에서만 동작해요

---

# v1.1 (2026-04-08)

## 1. 권한 팝업 없애기

### 뭐가 불편했나요?
봇이 파일을 읽거나 텔레그램에 답장할 때마다 터미널에 "Allow / Deny" 팝업이 떠서 수동으로 눌러야 했어요. 무인 운영이 불가능했죠.

### 어떻게 하면 되나요?
각 봇의 `.claude/settings.json`에서 `permissions.allow` 부분을 아래처럼 바꿔주세요.

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "Write",
      "Bash(*)",
      "Glob",
      "Grep",
      "WebFetch",
      "WebSearch",
      "mcp__plugin_telegram_telegram__*",
      "mcp__plugin_slack_slack__*",
      "mcp__codex__*",
      "mcp__context7__*",
      "mcp__qmd__*",
      "mcp__pencil__*",
      "mcp__claude_ai_Slack__*",
      "mcp__claude_ai_Notion__*",
      "mcp__claude_ai_Supabase__*",
      "mcp__claude_ai_Vercel__*",
      "mcp__claude_ai_Figma__*",
      "mcp__claude_ai_Google_Calendar__*",
      "mcp__claude_ai_Gmail__*"
    ]
  }
}
```

**핵심**: `mcp__plugin_telegram_telegram__*`처럼 와일드카드(`*`)를 쓰면 그 플러그인의 모든 도구가 자동 허용돼요. 새 도구가 추가돼도 다시 설정할 필요 없어요.

### 글로벌 설정도 해두면 편해요
`~/.claude/settings.json`에도 같은 내용을 넣으면 모든 봇에 기본 적용돼요.
추가로 이 줄도 넣어주세요:

```json
{
  "skipDangerousModePermissionPrompt": true
}
```

이걸 넣으면 `--dangerously-skip-permissions`로 실행할 때 "정말요?" 확인도 건너뜁니다.

### 적용하려면?
설정 파일 수정 후 **봇 재시작** 필요 (settings.json 변경은 `/reload-plugins`으로 안 됨).

---

## 2. 봇 자동 복구 (죽으면 알아서 살아나기)

### 뭐가 불편했나요?
봇이 죽으면(CC 크래시, tmux 세션 종료 등) 직접 터미널 열어서 재시작해야 했어요. 새벽에 죽으면 아침까지 봇이 멈춰있었죠.

### 어떻게 하면 되나요?

#### 1단계: check-bots.sh 다운로드

`templates/scripts/check-bots.sh` 파일을 `~/agents/check-bots.sh`에 복사하세요.

```bash
cp templates/scripts/check-bots.sh ~/agents/check-bots.sh
chmod +x ~/agents/check-bots.sh
```

그리고 파일을 열어서 `BOTS=` 줄을 자기 봇에 맞게 수정하세요:

```bash
BOTS=("봇1이름:bot1-channels" "봇2이름:bot2-channels")
```

- 콜론(`:`) 앞: tmux 창 이름 (한글 OK)
- 콜론(`:`) 뒤: ~/agents/ 아래 봇 폴더 이름

#### 2단계: cron에 등록 (5분마다 자동 체크)

```bash
crontab -e
```

맨 아래에 이 줄 추가:
```
*/5 * * * * /bin/zsh /Users/YOUR_USERNAME/agents/check-bots.sh >> /tmp/check-bots.log 2>&1
```

#### 이게 뭘 하나요?
- 5분마다 tmux `cc-bots` 세션을 확인
- 봇 창이 없으면 → 새로 만들고 봇 실행
- 창은 있는데 Claude가 죽었으면 → 재시작
- tmux 세션 자체가 없으면 → 세션 생성부터 시작
- 락 파일(`/tmp/check-bots.lock`)로 중복 실행 방지

#### 로그 확인
```bash
tail -20 /tmp/check-bots.log
```

---

## 3. 텔레그램 플러그인 캐시 정리

### 뭐가 불편했나요?
텔레그램 플러그인이 업데이트되어도 구버전 캐시가 남아있으면 이전 버전으로 실행돼요. "작성 중..." 표시가 안 뜨거나, 새 기능이 적용 안 되는 원인이 됩니다.

### 어떻게 하면 되나요?

`start-bots.sh` 맨 위에 이 줄을 추가하세요 (봇 시작 전에 실행):

```bash
# 구버전 텔레그램 플러그인 캐시 정리
PLUGIN_CACHE="$HOME/.claude/plugins/cache/claude-plugins-official/telegram"
if [ -d "$PLUGIN_CACHE" ]; then
  LATEST=$(ls -v "$PLUGIN_CACHE" | tail -1)
  for dir in "$PLUGIN_CACHE"/*/; do
    VER=$(basename "$dir")
    if [ "$VER" != "$LATEST" ]; then
      echo "🗑 구버전 플러그인 삭제: telegram/$VER"
      rm -rf "$dir"
    fi
  done
fi
```

또는 수동으로:
```bash
# 캐시 폴더 확인
ls ~/.claude/plugins/cache/claude-plugins-official/telegram/

# 최신 버전만 남기고 삭제 (예: 0.0.4만 남기기)
rm -rf ~/.claude/plugins/cache/claude-plugins-official/telegram/0.0.1
rm -rf ~/.claude/plugins/cache/claude-plugins-official/telegram/0.0.2
rm -rf ~/.claude/plugins/cache/claude-plugins-official/telegram/0.0.3
```

삭제 후 봇 재시작하면 최신 버전으로 동작합니다.

---

## 4. 텔레그램 고스트 프로세스 정리

### 뭐가 불편했나요?
봇을 재시작해도 이전 텔레그램 폴링 프로세스가 남아있으면 `409 Conflict` 에러가 나요. 새 봇이 텔레그램 서버에 연결을 못 하는 상태.

### 어떻게 하면 되나요?

`templates/scripts/cleanup-telegram-ghosts.sh`를 `~/.claude/scripts/`에 복사하고, 글로벌 SessionStart hook에 등록하세요:

```bash
mkdir -p ~/.claude/scripts
cp templates/scripts/cleanup-telegram-ghosts.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/cleanup-telegram-ghosts.sh
```

`~/.claude/settings.json`에 hooks 추가:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/cleanup-telegram-ghosts.sh"
          }
        ]
      }
    ]
  }
}
```

이러면 봇이 시작할 때마다 이전 세션의 텔레그램 프로세스를 자동 정리해요.

---

## 5. Stop hook (memory 기록 누락 방지)

### 뭐가 불편했나요?
봇이 종료될 때 오늘 작업 내용을 memory에 기록하지 않고 그냥 꺼져버리는 경우가 있어요. 다음 세션에서 "어제 뭐 했더라?" 하고 빈 파일을 보게 됩니다.

### 어떻게 하면 되나요?

각 봇의 `.claude/settings.json`에 Stop hook을 추가하세요:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "세션 종료 전: 의미 있는 작업했으면 memory/YYYY-MM-DD.md 기록 확인. 미기록이면 {\"ok\": false, \"reason\": \"memory 미기록\"}, 기록됐으면 {\"ok\": true}.",
            "model": "claude-haiku-4-5"
          }
        ]
      }
    ]
  }
}
```

이러면 봇이 꺼지기 전에 haiku가 빠르게 체크해서, memory 기록이 안 됐으면 경고해줘요.

---

## 6. 멀티 어카운트 주의사항

### 뭐가 위험한가요?
봇 여러 개를 실행할 때 `CLAUDE_CONFIG_DIR`을 빼먹으면 모든 봇이 같은 `~/.claude` 폴더를 사용하게 돼요. 한 봇이 `/login`하면 다른 봇의 토큰도 덮어씌워집니다.

### 체크리스트

1. **실행 명령어에 `CLAUDE_CONFIG_DIR` 있나?**
   ```bash
   # 좋은 예
   CLAUDE_CONFIG_DIR=~/agents/bot1-channels/.claude claude ...
   
   # 나쁜 예 (다른 봇 토큰 덮어씌울 위험)
   claude ...
   ```

2. **`TELEGRAM_STATE_DIR`도 분리했나?**
   ```bash
   TELEGRAM_STATE_DIR=~/agents/bot1-channels/.claude/channels/telegram
   ```

3. **같은 계정으로 몇 개 봇 돌리고 있나?**
   - 2~3개가 안전. 4개 이상이면 Rate limit 걸릴 수 있음
   - 계정 2개 쓰는 게 안정적 (계정A: 봇1+봇2, 계정B: 봇3+봇4)

---

## 전부 한 번에 적용하기

위 항목들을 모두 적용하고 싶으면:

```bash
# 1. 최신 oc2cc 받기
cd ~/Projects/oc2cc && git pull

# 2. 스크립트 복사
cp templates/scripts/check-bots.sh ~/agents/
cp templates/scripts/cleanup-telegram-ghosts.sh ~/.claude/scripts/
chmod +x ~/agents/check-bots.sh ~/.claude/scripts/cleanup-telegram-ghosts.sh

# 3. Forum 토픽 패치 (선택)
bash templates/scripts/patch-telegram-forum.sh

# 4. check-bots.sh에서 BOTS= 줄 수정 (자기 봇에 맞게)
nano ~/agents/check-bots.sh

# 5. cron 등록
(crontab -l 2>/dev/null; echo '*/5 * * * * /bin/zsh ~/agents/check-bots.sh >> /tmp/check-bots.log 2>&1') | crontab -

# 6. 각 봇의 settings.json 업데이트 (위 1, 5번 참고)

# 7. 봇 재시작
bash ~/agents/start-bots.sh
```

---

_이 가이드에 문제가 있거나 추가 제안이 있으면 [이슈](https://github.com/hislegend/oc2cc/issues)를 남겨주세요._
