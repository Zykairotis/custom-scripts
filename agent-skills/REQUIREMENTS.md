# Agent Skills — Requirements Reference

All 176 skills audited. Only skills with actual requirements are listed.

---

## 🔑 Environment Variables

| Variable | Skills |
|---|---|
| `PARALLEL_API_KEY` | parallel-web-search, parallel-web-extract, parallel-deep-research, parallel-data-enrichment, result, status, setup |
| `MESH_API_KEY` | flux |
| `MESH_ORG_ID` / `MESH_ORG_SLUG` | flux (auto-discovered on first run) |
| `AGENT_BROWSER_ENCRYPTION_KEY` | agent-browser (optional, for auth state encryption) |
| `AGENT_BROWSER_ALLOWED_DOMAINS` | agent-browser (optional, security allowlist) |
| `AGENT_BROWSER_DEFAULT_TIMEOUT` | agent-browser (optional, ms) |
| `AGENT_BROWSER_HEADED` | agent-browser (optional) |
| `AGENT_BROWSER_CONTENT_BOUNDARIES` | agent-browser (optional) |
| `AGENT_BROWSER_MAX_OUTPUT` | agent-browser (optional) |
| `AGENT_BROWSER_IDLE_TIMEOUT_MS` | agent-browser (optional) |
| `AGENT_BROWSER_PROVIDER` | agent-browser (optional, cloud provider) |
| `AGENT_BROWSER_ENGINE` | agent-browser (optional, lightpanda etc.) |
| `AGENTCORE_PROFILE_ID` / `AGENTCORE_REGION` | agent-browser (AWS Bedrock cloud mode) |
| `AWS_PROFILE` / `AWS_DEFAULT_REGION` | agent-browser (AWS), aws |
| `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` | aws |
| `VERCEL_TOKEN` | vercel-cli, vercel-api, vercel-firewall, deployments-cicd, marketplace, observability |
| `VERCEL_ORG_ID` + `VERCEL_PROJECT_ID` | vercel-cli, deployments-cicd |
| `VERCEL_OIDC_TOKEN` | ai-gateway, ai-sdk, env-vars, workflow (auto via `vercel env pull`) |
| `V0_API_KEY` | v0-dev |
| `FLAGS` + `FLAGS_SECRET` | vercel-flags |
| `CRON_SECRET` | cron-jobs, vercel-functions |
| `VERCEL_CLIENT_ID` + `VERCEL_CLIENT_SECRET` | sign-in-with-vercel |
| `VERCEL_QUEUE_API_TOKEN` | vercel-queues (only outside Vercel) |
| `DRAIN_SECRET` | observability |
| `RESEND_API_KEY` | email |
| `STRIPE_SECRET_KEY` + `STRIPE_PUBLISHABLE_KEY` + `STRIPE_WEBHOOK_SECRET` | payments |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` + `NEXT_PUBLIC_APP_URL` | payments |
| `DATABASE_URL` / `POSTGRES_URL` | ai-generation-persistence, bootstrap, next-forge |
| `BLOB_READ_WRITE_TOKEN` | ai-generation-persistence, vercel-storage |
| `UPSTASH_REDIS_REST_URL` + `UPSTASH_REDIS_REST_TOKEN` | ai-generation-persistence, vercel-storage |
| `AI_GATEWAY_API_KEY` | ai-gateway, ai-sdk, geistdocs |
| `OPENAI_API_KEY` | ai-sdk (if bypassing gateway), workflow |
| `ANTHROPIC_API_KEY` | ai-sdk (if bypassing gateway), workflow |
| `CLERK_SECRET_KEY` + `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | auth, next-forge |
| `AUTH0_SECRET` + `AUTH0_CLIENT_ID` + `AUTH0_CLIENT_SECRET` + `AUTH0_ISSUER_BASE_URL` | auth |
| `AUTH_SECRET` | auth (Auth.js/NextAuth) |
| `SANITY_PROJECT_ID` + `SANITY_DATASET` + `SANITY_API_TOKEN` | cms |
| `CONTENTFUL_SPACE_ID` + `CONTENTFUL_ACCESS_TOKEN` | cms |
| `DATOCMS_API_TOKEN` | cms |
| `SLACK_BOT_TOKEN` + `SLACK_SIGNING_SECRET` | chat-sdk, slack-tools |
| `SLACK_WEBHOOK_URL` | slack-tools |
| `TELEGRAM_BOT_TOKEN` + `TELEGRAM_WEBHOOK_SECRET` | chat-sdk |
| `TEAMS_APP_ID` + `TEAMS_APP_PASSWORD` + `TEAMS_APP_TENANT_ID` | chat-sdk |
| `DISCORD_BOT_TOKEN` + `DISCORD_PUBLIC_KEY` + `DISCORD_APPLICATION_ID` | chat-sdk |
| `GITHUB_TOKEN` (or `GITHUB_APP_ID` + `GITHUB_PRIVATE_KEY`) | chat-sdk |
| `LINEAR_CLIENT_ID` + `LINEAR_CLIENT_SECRET` + `LINEAR_ACCESS_TOKEN` | chat-sdk |
| `REDIS_URL` | chat-sdk (optional state) |
| `SENTRY_DSN` + `SENTRY_AUTH_TOKEN` | sentry |
| `TURBO_TOKEN` + `TURBO_TEAM` | turborepo (remote caching, CI) |
| `GEMINI_API_KEY` | visual-design |
| `CLAUDE_PLUGIN_ROOT` | planning-with-files |
| `CODEX_HOME` | playwright (defaults to ~/.codex) |
| `REGISTRY_TOKEN` | shadcn (only for private registries) |

---

## 🛠️ CLI Tools to Install

| Tool | Skills | Install |
|---|---|---|
| `parallel-cli` | parallel-*, result, status, setup | `curl -fsSL https://parallel.ai/install.sh \| bash` or `pipx install "parallel-web-tools[cli]"` |
| `gh` (GitHub CLI) | yeet, finishing-a-development-branch, commit-security-scan, receiving-code-review, github | `gh auth login` after install |
| `vercel` | vercel-cli, deployments-cicd, env-vars, bootstrap, and many more | `npm i -g vercel` |
| `agent-browser` | agent-browser, browser-navigation, mesh-setup | `npm i -g agent-browser` then `agent-browser install` |
| `bun` | flux | https://bun.sh |
| `aws` (AWS CLI v2) | aws | https://aws.amazon.com/cli/ |
| `az` (Azure CLI) | azure | https://learn.microsoft.com/cli/azure/install-azure-cli |
| `gcloud` | gcp | https://cloud.google.com/sdk/docs/install |
| `terraform` / `tofu` | terraform | https://developer.hashicorp.com/terraform/install |
| `kubectl` + `helm` | kubernetes, helm | package manager |
| `ansible` | ansible | `pip install ansible` |
| `docker` + `docker compose` | docker | https://docs.docker.com/get-docker/ |
| `sentry-cli` | sentry | `npm i -g @sentry/cli` |
| `turbo` | turborepo | `npm i -g turbo` |
| `npx` (Node.js) | playwright, find-skills, agent-browser-verify, many vercel skills | install Node.js |
| `python3` | backtesting-trading-strategies, doc, planning-with-files, pdf-reader | system package |
| `curl` + `jq` | context7, termdock-ast, google-slides-*, many others | system package |
| `git` | yeet, brainstorming, writing-plans, many others | system package |
| `scrot` / `gnome-screenshot` | screenshot (Linux) | `sudo pacman -S scrot` |
| `tesseract` | pdf-reader | `sudo pacman -S tesseract` |
| `wasm-pack` + `wasm-opt` | wasm-expert | `cargo install wasm-pack` |
| `semgrep` / `bandit` / `snyk` | security-audit | per-tool install |
| `rg` (ripgrep) | termdock-ast, session-navigation, skill-creation | `sudo pacman -S ripgrep` |

---

## 📦 System / Python Packages

| Package | Skills |
|---|---|
| `pandas numpy yfinance matplotlib` | backtesting-trading-strategies |
| `python-docx pdf2image` | doc |
| `libreoffice poppler` | doc |
| `tesseract-ocr poppler-utils` | pdf-reader |
| `ta-lib scipy scikit-learn` | backtesting-trading-strategies (optional) |
| `torch transformers peft datasets bitsandbytes accelerate` | llm-finetuning |
| `mlflow` or `wandb` | llm-finetuning, ml-engineer |
| `graphviz` | writing-skills |
| Rust toolchain + `wasm32-wasi` target | wasm-expert |

---

## 🔐 Login / Auth Steps

| Step | Skills |
|---|---|
| `parallel-cli login` | parallel-*, result, status, setup |
| `gh auth login` | yeet, finishing-a-development-branch, commit-security-scan, github |
| `vercel login` + `vercel link` | all vercel-* skills |
| `aws configure` or `aws sso login` | aws |
| `az login` | azure |
| `gcloud auth login` | gcp |
| `huggingface-cli login` | llm-finetuning |
| `sentry-cli login` or set `SENTRY_AUTH_TOKEN` | sentry |
| `turbo login` + `turbo link` | turborepo |
| Google OAuth connector | google-docs, google-drive, google-sheets, google-slides |
| Jira integration connector | jira |
| Slack app creation at api.slack.com | chat-sdk, slack-tools |
| macOS Screen Recording permission | screenshot (macOS) |
| Mesh workspace login | mesh-setup |

---

## ⚙️ Special Runtime Requirements

| Requirement | Skills |
|---|---|
| Termdock running on port 3033 | termdock-ast |
| SearXNG instance URL | searxng |
| `js_repl` enabled + `--sandbox danger-full-access` | playwright-interactive |
| Kubernetes cluster + kubeconfig | kubernetes, helm |
| PostgreSQL instance | postgres-expert |
| MongoDB Atlas or local instance | mongodb |
| Redis instance | redis-expert |
| Elasticsearch cluster | elasticsearch |
| Prometheus + Grafana running | prometheus |
| Factory/droid CLI authenticated | wiki |
| Notion integration token | notion |
| Confluence instance URL + credentials | confluence |
