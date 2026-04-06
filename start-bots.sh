#!/bin/zsh
# oc2cc — CC Channels multi-bot launcher
# Usage: bash start-bots.sh
# Edit the bot list below to match your setup.

SESSION="cc-bots"

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
