#!/usr/bin/env bash
# silent-harness: Stop and clean up agent sessions
# Usage: teardown.sh <session-name-or-team> [--clean]
#
# Stops the tmux session and optionally removes metadata files.
# If the target is a team, tears down all agents in the team.

set -euo pipefail

TARGET="${1:?Usage: teardown.sh <session-name-or-team> [--clean]}"
CLEAN=false
[[ "${2:-}" == "--clean" ]] && CLEAN=true

HARNESS_DIR="${HARNESS_DIR:-$HOME/.silent-harness}"

# Check if this is a team
TEAM_DIR="$HARNESS_DIR/teams/$TARGET"
if [[ -d "$TEAM_DIR" ]]; then
  echo "[harness] Tearing down team '$TARGET'..."

  # Stop each agent in the team
  for meta in "$HARNESS_DIR/${TARGET}"-*.meta; do
    [[ -f "$meta" ]] || continue
    AGENT_SESSION=$(grep '^session=' "$meta" | cut -d= -f2)
    if tmux has-session -t "$AGENT_SESSION" 2>/dev/null; then
      tmux kill-session -t "$AGENT_SESSION" 2>/dev/null || true
      echo "[harness] Stopped agent: $AGENT_SESSION"
    fi
    if [[ "$CLEAN" == "true" ]]; then
      AGENT_NAME=$(basename "$meta" .meta)
      rm -f "$meta" "$HARNESS_DIR/${AGENT_NAME}.prompt" 2>/dev/null || true
    fi
  done

  # Stop the team layout session
  LAYOUT="team-$TARGET"
  if tmux has-session -t "$LAYOUT" 2>/dev/null; then
    tmux kill-session -t "$LAYOUT" 2>/dev/null || true
    echo "[harness] Stopped team layout: $LAYOUT"
  fi

  # Clean team dir
  if [[ "$CLEAN" == "true" ]]; then
    rm -rf "$TEAM_DIR"
    echo "[harness] Cleaned team directory"
  fi

  echo "[harness] Team '$TARGET' torn down"
  exit 0
fi

# Single agent teardown
META_FILE="$HARNESS_DIR/${TARGET}.meta"
if [[ -f "$META_FILE" ]]; then
  SESSION=$(grep '^session=' "$META_FILE" | cut -d= -f2)
else
  SESSION="$TARGET"
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  echo "[harness] Stopped session: $SESSION"
else
  echo "[harness] Session '$SESSION' not found (may have already exited)"
fi

if [[ "$CLEAN" == "true" ]]; then
  rm -f "$HARNESS_DIR/${TARGET}.meta" "$HARNESS_DIR/${TARGET}.prompt" 2>/dev/null || true
  echo "[harness] Cleaned metadata files"
fi

echo "[harness] Done"
