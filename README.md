# Dev Tools & Scripts

Custom tools and scripts for development workflows and AI agent setup.

## 📁 Categories

### [bash-scripts/custom-conversion](./bash-scripts/custom-conversion/README.md)
Bash scripts for converting and combining text-based files.
- `cvt-txt.sh` — Converts files to UTF-8 plain text with parallel processing
- `cvt-comb.sh` — Combines files from a directory into folder-wise summary files

### [agent-skills](./agent-skills/)
176 unique agent skill definitions for AI coding assistants (Kiro, Codex, Claude, Codex, etc.).
Covers browser automation, web research, trading, frontend design, C# testing, Vercel, GCP, AWS, and more.

**Install:**
```bash
bash agent-skills/install.sh              # full interactive install
bash agent-skills/install.sh --check      # check what's missing
bash agent-skills/install.sh --env-only   # only configure env vars
bash agent-skills/install.sh --tools-only # only install tools
```

Key files:
- [`install.sh`](./agent-skills/install.sh) — cross-platform installer (Linux/macOS/Windows)
- [`config.yaml`](./agent-skills/config.yaml) — all tools, packages, env vars, auth steps
- [`REQUIREMENTS.md`](./agent-skills/REQUIREMENTS.md) — full requirements reference

---

> Add new tools/scripts under a relevant subfolder and link them here.
