#!/bin/bash
# oc2cc — CC 텔레그램 플러그인에 Forum 토픽 지원 패치
#
# 뭘 하나요?
#   CC 텔레그램 플러그인(server.ts)에 message_thread_id 지원을 추가합니다.
#   이 패치를 적용하면 forum 그룹에서 토픽별로 대화할 수 있어요.
#
# 사용법:
#   bash patch-telegram-forum.sh
#
# 주의:
#   - 공식 플러그인 캐시를 직접 수정합니다
#   - 플러그인 업데이트 시 덮어써지므로 다시 실행해야 합니다
#   - 적용 후 CC에서 /reload-plugins 필요

set -euo pipefail

# 플러그인 캐시 위치 찾기
PLUGIN_DIR="$HOME/.claude/plugins/cache/claude-plugins-official/telegram"
if [ ! -d "$PLUGIN_DIR" ]; then
  echo "❌ 텔레그램 플러그인 캐시를 찾을 수 없습니다."
  echo "   먼저 CC에서 텔레그램 플러그인을 설치하세요."
  exit 1
fi

# 최신 버전 찾기
VERSION=$(ls -v "$PLUGIN_DIR" | tail -1)
SERVER="$PLUGIN_DIR/$VERSION/server.ts"

if [ ! -f "$SERVER" ]; then
  echo "❌ server.ts를 찾을 수 없습니다: $SERVER"
  exit 1
fi

echo "📦 패치 대상: $SERVER"

# 이미 패치됐는지 확인
if grep -q "message_thread_id.*Forum topic thread ID" "$SERVER" 2>/dev/null; then
  echo "✅ 이미 패치되어 있습니다."
  exit 0
fi

# 백업
cp "$SERVER" "$SERVER.bak"
echo "💾 백업: $SERVER.bak"

# 패치 1: 인바운드 — meta에 message_thread_id 추가
sed -i '' 's/        chat_id,/        chat_id,\n        ...(threadId != null ? { message_thread_id: String(threadId) } : {}),/' "$SERVER"

# 패치 2: 아웃바운드 — reply 도구 스키마에 message_thread_id 파라미터 추가
sed -i '' "/reply_to: {/{
N
N
a\\
          message_thread_id: {\\
            type: 'string',\\
            description: 'Forum topic thread ID. Pass message_thread_id from the inbound <channel> block to reply in the correct topic.',\\
          },
}" "$SERVER"

# 패치 3: reply 핸들러에서 thread_id 추출
sed -i '' 's/const reply_to = args.reply_to != null ? Number(args.reply_to) : undefined/const reply_to = args.reply_to != null ? Number(args.reply_to) : undefined\n        const thread_id = args.message_thread_id != null ? Number(args.message_thread_id) : undefined/' "$SERVER"

# 패치 4: sendMessage에 message_thread_id 전달
sed -i '' 's/\.\.\.(shouldReplyTo ? { reply_parameters: { message_id: reply_to } } : {}),/...(shouldReplyTo ? { reply_parameters: { message_id: reply_to } } : {}),\n              ...(thread_id != null ? { message_thread_id: thread_id } : {}),/' "$SERVER"

# 검증
if grep -q "message_thread_id.*Forum topic thread ID" "$SERVER" 2>/dev/null; then
  echo "✅ 패치 성공!"
  echo ""
  echo "다음 단계:"
  echo "  1. CC에서 /reload-plugins 실행"
  echo "  2. forum 그룹에서 토픽 대화 테스트"
  echo ""
  echo "⚠️ 플러그인 업데이트 후 이 스크립트를 다시 실행하세요."
else
  echo "❌ 패치 실패. 백업에서 복원합니다."
  cp "$SERVER.bak" "$SERVER"
  exit 1
fi

# 멀티봇 환경: 다른 봇들의 캐시에도 복사
for bot_dir in ~/agents/*/; do
  bot_cache="$bot_dir.claude/plugins/cache/claude-plugins-official/telegram/$VERSION/server.ts"
  if [ -f "$bot_cache" ] && [ "$bot_cache" != "$SERVER" ]; then
    cp "$SERVER" "$bot_cache"
    bot_name=$(basename "$bot_dir")
    echo "📋 복사: $bot_name"
  fi
done
