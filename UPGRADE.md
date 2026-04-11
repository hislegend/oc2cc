# oc2cc 업그레이드 가이드

> 이미 oc2cc로 봇을 세팅한 사람을 위한 추가 설정 가이드.  
> 각 항목은 독립적이라 필요한 것만 골라서 적용할 수 있어요.  
> 최신 패치가 위에 있어요.

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
