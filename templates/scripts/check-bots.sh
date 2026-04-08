#!/bin/zsh
# oc2cc — CC 봇 상태 체크 + 자동 복구 스크립트
# cron 등록: */5 * * * * /bin/zsh ~/agents/check-bots.sh >> /tmp/check-bots.log 2>&1
#
# 사용법:
#   1. 이 파일을 ~/agents/check-bots.sh로 복사
#   2. BOTS= 줄을 자기 봇에 맞게 수정
#   3. cron에 등록

# 락 파일로 중복 실행 방지
LOCKFILE="/tmp/check-bots.lock"
if [ -f "$LOCKFILE" ]; then
  LOCK_PID=$(cat "$LOCKFILE" 2>/dev/null)
  if kill -0 "$LOCK_PID" 2>/dev/null; then
    exit 0
  fi
fi
echo $$ > "$LOCKFILE"
trap "rm -f $LOCKFILE" EXIT

SESSION="cc-bots"

# ── 봇 목록 설정 (수정 필요!) ──
# 형식: "tmux창이름:봇폴더이름"
# 예시: "mybot:mybot-channels"
BOTS=("bot1:bot1-channels" "bot2:bot2-channels")

# tmux 세션 존재 여부 확인
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "$(date '+%H:%M') ⚠️ $SESSION 세션 없음. 새로 생성합니다."
  tmux new-session -d -s "$SESSION" -n "placeholder"
  CREATED_SESSION=true
fi

REVIVED=()
ALL_OK=true

for entry in "${BOTS[@]}"; do
  WIN="${entry%%:*}"
  DIR="${entry##*:}"

  # 창 존재 여부 확인
  if ! tmux list-windows -t "$SESSION" -F '#{window_name}' 2>/dev/null | grep -q "^${WIN}$"; then
    echo "$(date '+%H:%M') ⚠️ ${WIN} 창 없음. 새로 생성합니다."
    tmux new-window -t "$SESSION" -n "$WIN"
    sleep 1
    tmux send-keys -t "$SESSION:${WIN}" \
      "cd ~/agents/${DIR} && CLAUDE_CONFIG_DIR=~/agents/${DIR}/.claude TELEGRAM_STATE_DIR=~/agents/${DIR}/.claude/channels/telegram claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official" Enter
    REVIVED+=("$WIN")
    ALL_OK=false
    continue
  fi

  # 창은 있지만 Claude가 죽었는지 확인 (프롬프트가 shell이면 Claude가 죽은 것)
  PANE_OUTPUT=$(tmux capture-pane -t "$SESSION:${WIN}" -p | tail -5)
  if echo "$PANE_OUTPUT" | grep -q "^.*%$"; then
    echo "$(date '+%H:%M') ⚠️ ${WIN} Claude 프로세스 죽음. 재시작합니다."
    tmux send-keys -t "$SESSION:${WIN}" \
      "cd ~/agents/${DIR} && CLAUDE_CONFIG_DIR=~/agents/${DIR}/.claude TELEGRAM_STATE_DIR=~/agents/${DIR}/.claude/channels/telegram claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official" Enter
    REVIVED+=("$WIN")
    ALL_OK=false
    continue
  fi

  echo "$(date '+%H:%M') ✅ ${WIN} 정상"
done

# placeholder 창 제거
if [[ "$CREATED_SESSION" == "true" ]]; then
  tmux kill-window -t "$SESSION:placeholder" 2>/dev/null
fi

if $ALL_OK; then
  echo "$(date '+%H:%M') ✅ 전체 봇 정상"
else
  echo "$(date '+%H:%M') 🔧 복구: ${REVIVED[*]}"
fi
