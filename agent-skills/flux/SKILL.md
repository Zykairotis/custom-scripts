---
name: flux
description: "Use this skill for Mesh MCP work that needs one of four things: (1) discovering Mesh tools, resources, or prompts, (2) running recent social or web research through Mesh servers, (3) generating or adapting TypeScript Mesh MCP client/helper code, or (4) converting Mesh results into compact TOON-or-JSON output. Do not use it for generic TypeScript tasks, generic web research outside Mesh, or unrelated formatting requests that do not involve Mesh output."
---

# Flux

Use this skill to make Mesh MCP work smaller, more structured, and easier to reuse.

## Quick routing

1. Identify the request shape.
   - Recent or latest research -> use Mesh social or web tools first.
   - Mesh capability discovery -> inspect tools, resources, and prompts first.
   - TypeScript or client setup -> start from the bundled helper script.
   - Compact output shaping only -> skip inventory unless the result shape is unknown.

2. Keep discovery narrow.
   - Load only the inventory slice that changes the answer.
   - Summarize the relevant subset instead of dumping full catalogs.

3. Prefer machine-readable results.
   - Use `structuredContent` first.
   - Fall back to text content only when structured data is missing.

4. Validate query-driven calls.
   - When you use `call <tool> <args>` for research or batch collection, run it with `--validate`.
   - Treat stderr as the validation channel and stdout as the machine-readable payload channel.
   - Save stdout to a file when you plan to post-process results, then inspect the validation block on stderr to confirm the payload was parsed and round-tripped cleanly.

## Recent research workflow

Use the Mesh `social-media` server as the first stop when the user wants current signals, comparisons, or source-backed shortlists.

- Reddit: `search_reddit`, `list_posts`, `get_post_details`, or related tools for community discussion and implementation feedback.
- X: `search_tweets`, `get_timeline`, `get_trends`, or related tools for fast-moving sentiment and early references.
- YouTube: `search_videos`, `get_video_details`, `get_channel_videos`, or related tools for creator demos and product overviews.
- Web: `web_search_preview` and `web_fetch` for docs, release notes, blog posts, and broader confirmation.

When the user says `recent`, `latest`, `today`, `this week`, or an equivalent freshness constraint:

- Prefer the newest available timestamps first.
- State the observed timestamp or the cutoff used.
- If the server does not expose a built-in recency filter, say that the result was sorted by observed dates after retrieval.

If a source family is unavailable, continue with the remaining Mesh sources and say which source family was missing.

## Discovery workflow

When the user asks what Mesh exposes, what tools exist, or which prompt/resource matters:

- Inspect tools, resources, and prompts once.
- Filter to the subset relevant to the user goal.
- Return only the names, purpose, and the fields that explain why they matter.
- Do not dump raw catalogs unless the user explicitly asks for the full list.

Use `inspect-tool <name>` from the helper when the user needs one tool schema or details without the rest of the inventory.

## TypeScript workflow

Use `scripts/flux.ts` when the user needs a repeatable client setup or a small cross-platform Mesh example.

- The helper auto-discovers your Mesh organization if `MESH_ORG_ID`/`MESH_ORG_SLUG` is not set.
- On first run without org config, it calls `list_organizations` via Mesh, finds your org, and saves it to `.mesh-env` in the skill directory.
- Subsequent runs read from `.mesh-env` automatically — no env vars needed after the first successful run.
- If `MESH_API_KEY` is not set as an environment variable, the helper also checks `.mesh-env` as a fallback.
- When org info is set, it reads `MESH_ORG_ID` or `MESH_ORG_SLUG` when calling the self-management MCP.
- Uses plain JSON-RPC HTTP requests through `fetch`.
- Passes the client name as `x-mesh-client`.
- Uses bearer-token auth through the `Authorization` header.
- Treats a bare Mesh origin as `/mcp` by default.
- Caches inventory in process instead of rediscovering it repeatedly.
- Keeps the helper stateless when the Mesh endpoint does not require session reuse.
- `doctor` uses a lightweight connectivity probe (`prompts/list`, then `resources/list`, then `tools/list` as a fallback) so it does not stall on large tool catalogs.

Read [references/cli-examples.md](references/cli-examples.md) when you need shell-safe examples for PowerShell, Bash, or zsh.

## Output rules

Use these fixed answer shapes.

### Research response

1. Short verdict.
2. Observed freshness line with dates or cutoff.
3. Compact evidence block in TOON or JSON.
4. One-line gap or caveat if coverage was incomplete.

### Inventory summary

1. One-line overview of the relevant Mesh surface.
2. Compact list of the few tools, resources, or prompts that matter.
3. Optional recommendation for the next tool to call.

### Code or helper response

1. Short explanation of what the helper covers.
2. Code or command snippet.
3. Required env vars.
4. One concrete example invocation.

### Compact transformation response

1. Short statement of what was normalized.
2. TOON for repeated rows with shared shape.
3. JSON for nested, sparse, or mixed-shape results.

## Validation workflow

Use validation whenever you are going to batch queries, save outputs, or post-process them with Python, `jq`, or another parser.

Validation goals:

- confirm the exact query ran through the real Mesh tool
- confirm whether the actual rendered format is `toon`, `json`, or plain text
- confirm the fenced payload parses successfully
- confirm the parsed payload round-trips without losing fields
- confirm the top-level shape is what you expect before compiling many files

Recommended pattern:

```bash
cd /home/mewtwo/.agents/skills/flux
bun run scripts/flux.ts call search_tweets '{"query":"harness github MCP tool","count":20}' --validate > /tmp/harness_q15.out
```

What to expect:

- stdout: the normal payload, fenced as `toon` or `json`
- stderr: a JSON validation block with `actualFormat`, `parseable`, `lossless`, `source`, and shape metadata

Important shell detail:

- Use `> /tmp/file 2>/tmp/file.validate` if you want separate payload and validation files.
- Use `> /tmp/file` if you want the payload in the file and the validation block in the terminal.
- Do not use `2>&1 > /tmp/file` if you intend to merge stderr into the same file.

Interpretation:

- `actualFormat: "toon"` means the payload was a flat repeated row set and TOON was lossless.
- `actualFormat: "toon"` can also mean the original payload was a wrapper object that contained a compact row set somewhere inside it; the helper preserves the wrapper structure and compacts the repeated rows recursively.
- `actualFormat: "json"` means no compact row set was found anywhere in the parsed payload, so JSON was kept to avoid dropping information.
- `parseable: true` and `lossless: true` are the success conditions for post-processing.
- For `search_tweets` and similar tools, expect `toon` when the tool returns wrapper objects like `{ ok, data: { tweets: [...] } }`, because the helper now compacts nested row arrays without discarding the envelope.

## Fallback rules

- Missing `MESH_API_KEY`: check `.mesh-env` file first; if still missing, stop and say that Mesh auth is missing; do not invent offline output.
- Missing org info (`MESH_ORG_ID`/`MESH_ORG_SLUG`): auto-discover via `list_organizations` Mesh tool and persist to `.mesh-env`.
- Missing tool or prompt: continue with adjacent inventory or broader Mesh sources and say what was unavailable.
- Missing recency metadata: state that freshness could not be fully verified and show the best available time signal.
- Text-only tool result: use the text result, but keep narration minimal.
- Mixed structured payloads: prefer JSON over TOON.

## TOON rules

TOON means Token-Oriented Object Notation.

Use TOON when the result contains an array of similar row objects with mostly shared keys, whether that row set is the whole payload or nested under wrapper keys such as `data`, `results`, or `items`. Prefer this canonical row shape when it fits:

- `rank`
- `tool`
- `source`
- `title`
- `date`
- `url`
- `why_it_matters`

Use JSON instead when:

- rows have inconsistent keys
- the payload has no compact repeated row set anywhere in the parsed JSON
- important fields are sparse or optional enough that TOON becomes lossy

If the result is one scalar, one object, or one or two tiny fields, plain text or JSON is usually shorter than TOON.

## Helper commands

Use the helper for the repetitive parts:

```bash
bun run scripts/flux.ts doctor           # Diagnose config, auto-discover org, save .mesh-env
bun run scripts/flux.ts inventory        # List all tools, resources, prompts
bun run scripts/flux.ts tools --format auto
bun run scripts/flux.ts inspect-tool search_reddit
bun run scripts/flux.ts search-inventory reddit
bun run scripts/flux.ts call search_reddit '{"query":"frontend mcp servers","sort":"new"}'
bun run scripts/flux.ts call search_reddit @args.json
bun run scripts/flux.ts call search_tweets '{"query":"harness github MCP tool","count":20}' --validate > /tmp/harness_q15.out
```

After the first successful run (or `doctor`), config is saved to `.mesh-env` and all commands work with zero configuration.

If you need shell-specific quoting examples for JSON arguments, use the reference file instead of expanding this skill body.

## Guardrails

- Do not use this skill for generic TypeScript work that does not involve Mesh MCP.
- Do not use this skill for generic web research when Mesh is not part of the task.
- Do not dump full inventories unless the user asked for them.
- Do not claim freshness without showing an observed date, timestamp, or explicit cutoff.
- Do not force TOON onto nested or heterogeneous data.
