#!/usr/bin/env bash
# silent-harness: Show status of all harness sessions
# Usage: status.sh [--watch] [--json]
#
# Displays a dashboard of all running agent sessions with:
#   - Session name, provider, age, and status
#   --watch: Auto-refresh every 5 seconds
#   --json:  Machine-readable JSON output

set -euo pipefail

HARNESS_DIR="${HARNESS_DIR:-$HOME/.silent-harness}"
WATCH_MODE=false
JSON_MODE=false

for arg in "$@"; do
  case "$arg" in
    --watch) WATCH_MODE=true ;;
    --json)  JSON_MODE=true ;;
  esac
done

render_status() {
  local sessions=()
  local now=$(date +%s)

  # Collect all meta files
  if [[ -d "$HARNESS_DIR" ]]; then
    for meta in "$HARNESS_DIR"/*.meta; do
      [[ -f "$meta" ]] || continue

      SESSION=$(grep '^session=' "$meta" | cut -d= -f2)
      PROVIDER=$(grep '^provider=' "$meta" | cut -d= -f2)
      LAUNCHED=$(grep '^launched_at=' "$meta" | cut -d= -f2-)

      # Check if tmux session is alive
      if tmux has-session -t "$SESSION" 2>/dev/null; then
        STATUS="running"
        PID=$(tmux list-panes -t "$SESSION" -F '#{pane_pid}' 2>/dev/null | head -1)
        # Check if the process is still active or has completed
        if [[ -n "$PID" ]] && ! ps -p "$PID" > /dev/null 2>&1; then
          STATUS="idle"
        fi
      else
        STATUS="stopped"
      fi

      # Calculate age
      if [[ -n "$LAUNCHED" ]]; then
        LAUNCHED_EPOCH=$(date -d "$LAUNCHED" +%s 2>/dev/null || echo "$now")
        AGE_SEC=$(( now - LAUNCHED_EPOCH ))
        AGE_MIN=$(( AGE_SEC / 60 ))
        AGE="${AGE_MIN}m"
      else
        AGE="unknown"
      fi

      sessions+=("$SESSION|$PROVIDER|$STATUS|$AGE")
    done
  fi

  # Also check team sessions
  local teams=()
  if [[ -d "$HARNESS_DIR/teams" ]]; then
    for team_dir in "$HARNESS_DIR/teams"/*/; do
      [[ -d "$team_dir" ]] || continue
      TEAM=$(basename "$team_dir")
      AGENT_COUNT=$(find "$HARNESS_DIR" -name "${TEAM}-*.meta" 2>/dev/null | wc -l)
      LAYOUT="team-$TEAM"
      if tmux has-session -t "$LAYOUT" 2>/dev/null; then
        teams+=("$TEAM|$AGENT_COUNT|active")
      else
        teams+=("$TEAM|$AGENT_COUNT|inactive")
      fi
    done
  fi

  if [[ "$JSON_MODE" == "true" ]]; then
    echo "{"
    echo "  \"agents\": ["
    FIRST=true
    for entry in "${sessions[@]}"; do
      IFS='|' read -r NAME PROV STAT AGE <<< "$entry"
      [[ "$FIRST" == "true" ]] && FIRST=false || echo ","
      printf '    {"name":"%s","provider":"%s","status":"%s","age":"%s"}' "$NAME" "$PROV" "$STAT" "$AGE"
    done
    echo ""
    echo "  ],"
    echo "  \"teams\": ["
    FIRST=true
    for entry in "${teams[@]}"; do
      IFS='|' read -r TEAM COUNT STAT <<< "$entry"
      [[ "$FIRST" == "true" ]] && FIRST=false || echo ","
      printf '    {"name":"%s","agents":%s,"status":"%s"}' "$TEAM" "$COUNT" "$STAT"
    done
    echo ""
    echo "  ]"
    echo "}"
    return
  fi

  # Human-readable dashboard
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║                  SILENT HARNESS STATUS                      ║"
  echo "╠══════════════════════════════════════════════════════════════╣"

  if [[ ${#sessions[@]} -eq 0 ]]; then
    echo "║  No agent sessions found                                    ║"
  else
    printf "║  %-20s %-8s %-10s %-8s ║\n" "SESSION" "PROVIDER" "STATUS" "AGE"
    printf "║  %-20s %-8s %-10s %-8s ║\n" "--------------------" "--------" "----------" "--------"
    for entry in "${sessions[@]}"; do
      IFS='|' read -r NAME PROV STAT AGE <<< "$entry"
      printf "║  %-20s %-8s %-10s %-8s ║\n" "$NAME" "$PROV" "$STAT" "$AGE"
    done
  fi

  echo "╠══════════════════════════════════════════════════════════════╣"

  if [[ ${#teams[@]} -eq 0 ]]; then
    echo "║  No teams found                                             ║"
  else
    printf "║  %-20s %-8s %-10s               ║\n" "TEAM" "AGENTS" "STATUS"
    printf "║  %-20s %-8s %-10s               ║\n" "--------------------" "--------" "----------"
    for entry in "${teams[@]}"; do
      IFS='|' read -r TEAM COUNT STAT <<< "$entry"
      printf "║  %-20s %-8s %-10s               ║\n" "$TEAM" "$COUNT" "$STAT"
    done
  fi

  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "  Refreshed: $(date '+%H:%M:%S')"
}

if [[ "$WATCH_MODE" == "true" ]]; then
  while true; do
    clear
    render_status
    sleep 5
  done
else
  render_status
fi
