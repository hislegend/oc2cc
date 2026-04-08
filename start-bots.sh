#!/bin/zsh
# oc2cc — CC Channels multi-bot launcher
# Usage: bash start-bots.sh
# Edit the bot list below to match your setup.

SESSION="cc-bots"

# ── 구버전 텔레그램 플러그인 캐시 정리 ────────────────────────────
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
  echo "✅ 텔레그램 플러그인: $LATEST (최신)"
fi

# ── 텔레그램 고스트 프로세스 정리 ─────────────────────────────────
GHOST_KILLED=0
for pid in $(pgrep -f "telegram.*server" 2>/dev/null); do
  kill "$pid" 2>/dev/null && GHOST_KILLED=$((GHOST_KILLED + 1))
done
[ $GHOST_KILLED -gt 0 ] && echo "🗑 고스트 프로세스 ${GHOST_KILLED}개 정리"

# ── 봇 시작 ──────────────────────────────────────────────────────
tmux kill-session -t $SESSION 2>/dev/null
tmux new-session -d -s $SESSION -n "bot1"

# ── Bot 1 ──────────────────────────────────────────────────────────
tmux send-keys -t $SESSION:bot1 \
  "cd ~/agents/bot1-channels && \
CLAUDE_CONFIG_DIR=~/agents/bot1-channels/.claude \
TELEGRAM_STATE_DIR=~/agents/bot1-channels/.claude/channels/telegram \
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official" \
  Enter

# ── Bot 2 ──────────────────────────────────────────────────────────
tmux new-window -t $SESSION -n "bot2"
tmux send-keys -t $SESSION:bot2 \
  "cd ~/agents/bot2-channels && \
CLAUDE_CONFIG_DIR=~/agents/bot2-channels/.claude \
TELEGRAM_STATE_DIR=~/agents/bot2-channels/.claude/channels/telegram \
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official" \
  Enter

# Add more bots by duplicating the block above.

echo "✅ cc-bots tmux session started."
echo "   Attach:  tmux attach -t cc-bots"
echo "   Windows: Ctrl+B, number key"
