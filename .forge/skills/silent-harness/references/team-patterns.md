# Team Configuration Reference

## Team Config JSON Schema

```json
{
  "agents": [
    {
      "name": "string (required) - short identifier, no spaces",
      "provider": "claude | codex (required)",
      "role": "string (required) - the task/prompt for this agent"
    }
  ],
  "shared_context": "string (optional) - path to shared context file"
}
```

## Preset Team Patterns

### Pattern 1: Architect + Builder + Reviewer (3-agent)

```json
{
  "agents": [
    { "name": "architect", "provider": "claude", "role": "Analyze the codebase and produce a detailed implementation plan with file-by-file changes" },
    { "name": "builder",   "provider": "codex",  "role": "Implement the architecture plan. Write production code with error handling and tests" },
    { "name": "reviewer",  "provider": "claude", "role": "Review the implementation for bugs, security issues, and adherence to the architecture plan" }
  ]
}
```

### Pattern 2: Dual-Provider Debate (2-agent)

```json
{
  "agents": [
    { "name": "claude-dev", "provider": "claude", "role": "Implement the feature" },
    { "name": "codex-review", "provider": "codex", "role": "Review and find issues in the implementation" }
  ]
}
```

### Pattern 3: Parallel Workers (N-agent)

```json
{
  "agents": [
    { "name": "worker-1", "provider": "claude", "role": "Handle files in src/api/" },
    { "name": "worker-2", "provider": "claude", "role": "Handle files in src/ui/" },
    { "name": "worker-3", "provider": "codex",  "role": "Handle files in src/tests/" }
  ]
}
```

### Pattern 4: Research + Implement (2-agent)

```json
{
  "agents": [
    { "name": "researcher", "provider": "claude", "role": "Research the best approach for implementing X, produce a technical spec" },
    { "name": "implementer", "provider": "codex", "role": "Implement the technical spec produced by the researcher" }
  ]
}
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `HARNESS_DIR` | `~/.silent-harness` | Base directory for metadata, prompts, team configs |

## File Layout

```
~/.silent-harness/
├── <session>.meta          # Agent metadata (session, provider, workdir, launched_at)
├── <session>.prompt        # Saved prompt for the agent
└── teams/
    └── <team-name>/
        ├── manifest.json   # Copy of the team config
        └── launch.meta     # Launch timestamp
```
