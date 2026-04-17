#!/usr/bin/env bash
# silent-harness: Launch a multi-agent teamwork session
# Usage: launch-team.sh <team-name> <team-config.json> [workdir]
#
# Team config format:
# {
#   "agents": [
#     { "name": "architect", "provider": "claude", "role": "Plan the architecture" },
#     { "name": "builder",   "provider": "codex",  "role": "Implement the code" },
#     { "name": "reviewer",  "provider": "claude", "role": "Review for quality" }
#   ],
#   "shared_context": "Optional shared context file path"
# }

set -euo pipefail

TEAM_NAME="${1:?Usage: launch-team.sh <team-name> <team-config.json> [workdir]}"
CONFIG_FILE="${2:?Team config JSON file required}"
WORKDIR="${3:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HARNESS_DIR="${HARNESS_DIR:-$HOME/.silent-harness}"

# Validate config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[harness] ERROR: Config file not found: $CONFIG_FILE" >&2
  exit 1
fi

# Count agents
AGENT_COUNT=$(grep -c '"name"' "$CONFIG_FILE" 2>/dev/null || echo 0)
if [[ "$AGENT_COUNT" -eq 0 ]]; then
  echo "[harness] ERROR: No agents found in config" >&2
  exit 1
fi

echo "[harness] === Launching team '$TEAM_NAME' with $AGENT_COUNT agents ==="

# Create a shared context directory for this team
TEAM_DIR="$HARNESS_DIR/teams/$TEAM_NAME"
mkdir -p "$TEAM_DIR"

# Copy config as the team manifest
cp "$CONFIG_FILE" "$TEAM_DIR/manifest.json"
echo "launched_at=$(date -Iseconds)" > "$TEAM_DIR/launch.meta"

# Parse agents and launch each one
# Using simple grep/sed parsing to avoid jq dependency
AGENT_NAMES=$(grep '"name"' "$CONFIG_FILE" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
AGENT_PROVIDERS=$(grep '"provider"' "$CONFIG_FILE" | sed 's/.*"provider"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
AGENT_ROLES=$(grep '"role"' "$CONFIG_FILE" | sed 's/.*"role"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

# Convert to arrays
NAMES=($AGENT_NAMES)
PROVIDERS=($AGENT_PROVIDERS)
ROLES=($AGENT_ROLES)

LAUNCHED=0
for i in "${!NAMES[@]}"; do
  AGENT_NAME="${TEAM_NAME}-${NAMES[$i]}"
  PROVIDER="${PROVIDERS[$i]}"
  ROLE="${ROLES[$i]}"

  # Build the prompt with team context
  PROMPT="[Team: $TEAM_NAME | Role: ${NAMES[$i]}] $ROLE"

  echo "[harness] Launching agent ${NAMES[$i]} ($PROVIDER)..."
  "$SCRIPT_DIR/launch-agent.sh" "$AGENT_NAME" "$PROVIDER" "$PROMPT" "$WORKDIR"
  ((LAUNCHED++))
done

# Create a tmux window layout linking all sessions
LAYOUT_SESSION="team-$TEAM_NAME"
if ! tmux has-session -t "$LAYOUT_SESSION" 2>/dev/null; then
  tmux new-session -d -s "$LAYOUT_SESSION" -c "$WORKDIR"
fi

# Link each agent as a window in the team session
for i in "${!NAMES[@]}"; do
  AGENT_SESSION="${TEAM_NAME}-${NAMES[$i]}"
  if tmux has-session -t "$AGENT_SESSION" 2>/dev/null; then
    tmux new-window -t "$LAYOUT_SESSION" -n "${NAMES[$i]}" -c "$WORKDIR"
    tmux send-keys -t "$LAYOUT_SESSION:${NAMES[$i]}" "tmux attach -t $AGENT_SESSION" Enter
  fi
done

# Kill the default first window (blank)
tmux kill-window -t "$LAYOUT_SESSION:0" 2>/dev/null || true

echo ""
echo "[harness] === Team '$TEAM_NAME' launched: $LAUNCHED agents ==="
echo "[harness] Team layout session: $LAYOUT_SESSION"
echo "[harness] Team directory: $TEAM_DIR"
echo "[harness] Attach to team: tmux attach -t $LAYOUT_SESSION"
