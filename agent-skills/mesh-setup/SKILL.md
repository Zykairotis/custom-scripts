---
name: mesh-setup
description: Add MCP servers into a Mesh workspace through the browser by reading MCP definitions from `mcp.json`, JSON, JSONC, YAML, Markdown code fences, or pasted config snippets, normalizing them into Mesh connection fields, and creating each connection in `/$workspace/settings/connections`. Use when Codex needs to open Mesh, click `Custom Connection`, and import one or more connections of type HTTP, SSE, Websocket, NPX Package, or Custom Command.
---

# Mesh Setup

Use this skill to turn MCP config files into Mesh connections with a deterministic browser workflow.

## Required Inputs

- Workspace slug or name used in the URL path
- IP address or hostname. Default to `localhost` when the user does not specify one.
- Port
- One or more MCP definition sources: files, pasted text, or Markdown docs

## Workflow

1. Collect the runtime target.
   - Build the URL as `http://<ip>:<port>/<workspace>/settings/connections`.
   - Do not guess the workspace slug if the user gave only a display name.

2. Normalize the MCP sources before touching the browser.
   - Run `python3 "$CODEX_HOME/skills/mesh-setup/scripts/normalize_mesh_connections.py" <paths...>`.
   - Use `-` as an input path to read pasted content from stdin.
   - Read [references/source-shapes.md](references/source-shapes.md) only when the source format is ambiguous or the parser needs a supported shape example.

3. Load the browser driver instructions.
   - Read [agent-browser](</home/mewtwo/.agents/skills/agent-browser/SKILL.md>) and use that CLI as the Vercel-style browser agent for all web steps.
   - If Mesh requires login, reuse an existing browser profile or session instead of automating credentials from scratch.

4. Open Mesh.
   - Navigate to the URL from step 1.
   - Wait for page load, then snapshot the page before every interaction sequence.

5. Loop over the normalized connections until all are handled.
   - Click `Custom Connection`.
   - Set `Type *` to the exact Mesh label:
     - `HTTP`
     - `SSE`
     - `Websocket`
     - `NPX Package`
     - `Custom Command`
   - Fill the dialog from the normalized record:
     - HTTP/SSE/Websocket: `URL`, optional `Token`, `Name`, optional `Description`
     - NPX Package: `NPM Package`, environment variables, `Name`, optional `Description`
     - Custom Command: `Command`, `Arguments`, optional `Working Directory`, environment variables, `Name`, optional `Description`
   - Submit `Create Connection`.
   - Re-snapshot and confirm the dialog closed. If practical, also confirm the new connection appears in the list.

6. Summarize the result.
   - Report created connections, skipped connections, and any configs that still need tokens or env vars.

## Guardrails

- Do not guess tokens, env var values, working directories, or workspace slugs.
- Do not overwrite or edit an existing connection unless the user explicitly asks.
- Stop and report if `NPX Package` or `Custom Command` is missing from the type menu. In Mesh that usually means STDIO is disabled in this environment.
- Re-snapshot whenever the dialog rerenders or element refs become stale.
- Preserve provided secrets and env vars exactly; do not rewrite them unless the source contains an OS-specific variant and the current OS requires selecting one branch.
- If normalization returns no connections, stop before opening the browser and explain which source failed.

## Normalizer Output

The normalizer emits JSON with:

- `target_os`
- `connections[]`
- `errors[]`

Each connection includes the Mesh-facing fields needed for the dialog, including a normalized type, name, optional description, and transport-specific values.
