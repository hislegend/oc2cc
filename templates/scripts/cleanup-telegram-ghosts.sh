#!/bin/zsh
# oc2cc — 텔레그램 고스트 프로세스 정리
# SessionStart hook으로 등록하면 봇 시작 시 자동 실행됩니다.
#
# 뭘 하나요?
#   이전 세션의 텔레그램 폴링 프로세스가 남아있으면
#   새 봇이 409 Conflict 에러를 만납니다.
#   이 스크립트는 현재 세션이 아닌 고스트 프로세스를 찾아서 종료합니다.

KILLED=0

# 현재 CC 세션의 PID (부모)
MY_PPID=$$

# bun으로 돌고 있는 텔레그램 플러그인 서버 찾기
for pid in $(pgrep -f "telegram.*server" 2>/dev/null); do
  # 현재 세션의 자식이면 건너뛰기
  PARENT=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  if [ "$PARENT" = "$MY_PPID" ]; then
    continue
  fi

  # 프로세스 정보 확인
  CMD=$(ps -o command= -p "$pid" 2>/dev/null)
  if echo "$CMD" | grep -q "telegram"; then
    kill "$pid" 2>/dev/null
    KILLED=$((KILLED + 1))
  fi
done

if [ $KILLED -gt 0 ]; then
  echo "telegram ghost cleanup: killed $KILLED stale process(es)"
fi
