---
name: silent-harness
description: >
  Orchestrate multiple CLI AI agents (Claude Code, Codex) in coordinated tmux sessions
  as a silent harness for teamwork. Use when the user wants to: (1) launch multiple AI
  agents in parallel tmux panes, (2) set up multi-agent teams with roles like architect/builder/reviewer,
  (3) monitor agent status across sessions, (4) run Claude Code and Codex together in a coordinated
  workflow, (5) create a "silent harness" where agents run non-interactively and report back results.
  Triggers: "harness", "orchestrate agents", "multi-agent team", "tmux agents", "launch team",
  "agent orchestrator", "parallel agents", "silent harness".
---

# Silent Harness

Tmux-based orchestrator for running Claude Code and Codex CLI agents in coordinated, non-interactive teamwork sessions.

## Quick Start

### Launch a single agent

```bash
scripts/launch-agent.sh <session-name> <claude|codex> "<prompt>" [workdir]
```

Example:
```bash
scripts/launch-agent.sh refactor claude "Refactor src/api.ts to use async/await" ~/my-project
```

### Launch a team

1. Create a team config JSON (see [references/team-patterns.md](references/team-patterns.md) for presets):

```json
{
  "agents": [
    { "name": "architect", "provider": "claude", "role": "Plan the implementation" },
    { "name": "builder",   "provider": "codex",  "role": "Implement the plan" },
    { "name": "reviewer",  "provider": "claude", "role": "Review for quality" }
  ]
}
```

2. Launch:

```bash
scripts/launch-team.sh my-team team-config.json ~/my-project
```

3. Monitor:

```bash
scripts/status.sh              # One-shot dashboard
scripts/status.sh --watch      # Auto-refresh every 5s
scripts/status.sh --json       # Machine-readable output
```

4. Capture output from a specific agent:

```bash
scripts/capture-output.sh my-team-architect          # Full output
scripts/capture-output.sh my-team-architect --last 50  # Last 50 lines
scripts/capture-output.sh my-team-architect --follow   # Stream live
```

5. Tear down when done:

```bash
scripts/teardown.sh my-team           # Stop sessions, keep metadata
scripts/teardown.sh my-team --clean   # Stop sessions and clean up files
```

## Scripts

| Script | Purpose |
|---|---|
| `scripts/launch-agent.sh` | Launch a single agent in a detached tmux session |
| `scripts/launch-team.sh` | Launch a multi-agent team from a JSON config |
| `scripts/status.sh` | Dashboard showing all agent/team status |
| `scripts/capture-output.sh` | Capture or stream output from a running agent |
| `scripts/teardown.sh` | Stop sessions and optionally clean metadata |

## How It Works

1. **Launch**: Each agent gets its own detached tmux session running `claude --print` or `codex --quiet` in non-interactive mode
2. **Metadata**: Every session records `.meta` and `.prompt` files in `~/.silent-harness/` for traceability
3. **Teams**: Multi-agent teams are launched together with a shared tmux layout session linking all agents
4. **Monitoring**: The status dashboard reads metadata files and checks tmux session health
5. **Capture**: Output is captured via `tmux capture-pane` — no interactive attachment needed
6. **Teardown**: Sessions are killed cleanly; `--clean` removes all metadata artifacts

## Team Patterns

See [references/team-patterns.md](references/team-patterns.md) for preset team configurations:
- Architect + Builder + Reviewer (3-agent)
- Dual-Provider Debate (2-agent)
- Parallel Workers (N-agent)
- Research + Implement (2-agent)

## Requirements

- `tmux` >= 3.3
- `claude` CLI (Claude Code) installed and authenticated
- `codex` CLI installed and authenticated (optional, for multi-provider teams)
