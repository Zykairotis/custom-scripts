#!/usr/bin/env bash
# silent-harness: Pipe output from a running agent session
# Usage: capture-output.sh <session-name> [--follow] [--last N]
#
# Captures the visible terminal output from a tmux session.
# --follow: Stream output continuously (like tail -f)
# --last N: Show last N lines only

set -euo pipefail

SESSION="${1:?Usage: capture-output.sh <session-name> [--follow] [--last N]}"
FOLLOW=false
LAST_LINES=0

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --follow) FOLLOW=true ;;
    --last) LAST_LINES="${2:?--last requires a number}"; shift ;;
  esac
  shift || true
done

HARNESS_DIR="${HARNESS_DIR:-$HOME/.silent-harness}"

# Resolve session name from meta if needed
META_FILE="$HARNESS_DIR/${SESSION}.meta"
if [[ -f "$META_FILE" ]]; then
  RESOLVED=$(grep '^session=' "$META_FILE" | cut -d= -f2)
else
  RESOLVED="$SESSION"
fi

if ! tmux has-session -t "$RESOLVED" 2>/dev/null; then
  echo "[harness] ERROR: Session '$RESOLVED' not found" >&2
  exit 1
fi

capture_pane() {
  tmux capture-pane -t "$RESOLVED" -p -S -${LAST_LINES:-32768}
}

if [[ "$FOLLOW" == "true" ]]; then
  # Stream mode: capture every 2 seconds
  PREV_HASH=""
  while true; do
    OUTPUT=$(capture_pane)
    HASH=$(echo "$OUTPUT" | md5sum | cut -d' ' -f1)
    if [[ "$HASH" != "$PREV_HASH" ]]; then
      echo "$OUTPUT"
      echo "--- $(date '+%H:%M:%S') ---"
      PREV_HASH="$HASH"
    fi
    sleep 2
  done
else
  if [[ "$LAST_LINES" -gt 0 ]]; then
    tmux capture-pane -t "$RESOLVED" -p -S -"$LAST_LINES"
  else
    capture_pane
  fi
fi
