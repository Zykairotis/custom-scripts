#!/usr/bin/env bash
# silent-harness: Launch a named agent session inside tmux
# Usage: launch-agent.sh <session-name> <provider> <prompt> [workdir]
#
# Providers: claude | codex
# Creates a detached tmux session, sends the prompt, and returns the session name.

set -euo pipefail

SESSION_NAME="${1:?Usage: launch-agent.sh <session-name> <provider> <prompt> [workdir]}"
PROVIDER="${2:?Provider must be 'claude' or 'codex'}"
PROMPT="${3:?Prompt is required}"
WORKDIR="${4:-$(pwd)}"
HARNESS_DIR="${HARNESS_DIR:-$HOME/.silent-harness}"

mkdir -p "$HARNESS_DIR"

# Sanitize session name for tmux (no dots, no colons)
SESSION_NAME=$(echo "$SESSION_NAME" | sed 's/[:.]/_/g')

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "[harness] Session '$SESSION_NAME' already exists. Attaching to it."
  exit 0
fi

# Validate provider
if [[ "$PROVIDER" != "claude" && "$PROVIDER" != "codex" ]]; then
  echo "[harness] ERROR: Provider must be 'claude' or 'codex', got '$PROVIDER'" >&2
  exit 1
fi

# Write the prompt to a file for traceability
PROMPT_FILE="$HARNESS_DIR/${SESSION_NAME}.prompt"
echo "$PROMPT" > "$PROMPT_FILE"

# Create a new detached tmux session
tmux new-session -d -s "$SESSION_NAME" -c "$WORKDIR"

# Send the provider command with the prompt
if [[ "$PROVIDER" == "claude" ]]; then
  # Claude Code: use --print for non-interactive / silent mode
  tmux send-keys -t "$SESSION_NAME" "claude --print $(printf '%q' "$PROMPT")" Enter
else
  # Codex: use --quiet for non-interactive mode
  tmux send-keys -t "$SESSION_NAME" "codex --quiet $(printf '%q' "$PROMPT")" Enter
fi

# Record metadata
META_FILE="$HARNESS_DIR/${SESSION_NAME}.meta"
cat > "$META_FILE" << META
session=$SESSION_NAME
provider=$PROVIDER
workdir=$WORKDIR
prompt_file=$PROMPT_FILE
launched_at=$(date -Iseconds)
pid=$(tmux list-panes -t "$SESSION_NAME" -F '#{pane_pid}' | head -1)
META

echo "[harness] Launched '$SESSION_NAME' ($PROVIDER) in tmux"
echo "[harness] Workdir: $WORKDIR"
echo "[harness] Prompt saved: $PROMPT_FILE"
echo "[harness] Meta saved: $META_FILE"
