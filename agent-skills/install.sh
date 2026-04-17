#!/usr/bin/env bash
# install.sh — Agent Skills installer
# Reads config.yaml, detects OS + package manager, checks/installs tools,
# prompts for env vars, copies skills to ~/.agents/skills
#
# Usage:
#   bash install.sh              # full interactive install
#   bash install.sh --check      # only check what's missing, no install
#   bash install.sh --env-only   # only prompt for env vars
#   bash install.sh --tools-only # only install tools

set -euo pipefail

# Require bash 4+ (macOS ships 3.2 which lacks declare -A)
if (( BASH_VERSINFO[0] < 4 )); then
  echo "ERROR: bash 4.0+ required. macOS users: brew install bash && sudo bash install.sh"
  exit 1
fi

# Verify config.yaml exists
SCRIPT_DIR_EARLY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR_EARLY/config.yaml" ]; then
  echo "ERROR: config.yaml not found in $SCRIPT_DIR_EARLY"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.agents/skills"
ENV_FILE="$HOME/.agents/skills.env"
CONFIG="$SCRIPT_DIR/config.yaml"
MODE="${1:-}"

# ── Colors ────────────────────────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' B='\033[1m' N='\033[0m'
ok()   { echo -e "${G}  ✓${N} $*"; }
warn() { echo -e "${Y}  !${N} $*"; }
err()  { echo -e "${R}  ✗${N} $*"; }
info() { echo -e "${C}  →${N} $*"; }
hdr()  { echo -e "\n${B}==> $*${N}"; }

# ── OS detection ──────────────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      # Check if running under WSL
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "linux_wsl"
      else
        echo "linux"
      fi ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

OS=$(detect_os)
[[ "$OS" == "linux_wsl" ]] && OS_DISPLAY="Linux (WSL2 / Arch)" || OS_DISPLAY="$OS"

# ── Package manager detection ─────────────────────────────────────────────────
# Try each in preference order; use the first one found.
detect_pkg_manager() {
  local os="${1:-linux}"
  local candidates=()

  case "$os" in
    linux*) candidates=(pacman apt brew) ;;
    macos)  candidates=(brew) ;;
    windows) candidates=(choco winget scoop) ;;
  esac

  for pm in "${candidates[@]}"; do
    if command -v "$pm" &>/dev/null; then
      echo "$pm"; return
    fi
  done
  echo "none"
}

PM=$(detect_pkg_manager "$OS")

# ── yaml parser (minimal — only what we need) ─────────────────────────────────
# Extracts: yaml_get <file> <dotted.key>
# Only handles simple scalar values and the install sub-keys we care about.
yaml_get_install() {
  # yaml_get_install <tool> <pm>  → prints install command or empty
  local tool="$1" pm="$2"
  # Extract the block under tools.<tool>.install, then find the pm key
  python3 - "$CONFIG" "$tool" "$pm" << 'PY'
import sys, re

config_file, tool, pm = sys.argv[1], sys.argv[2], sys.argv[3]
with open(config_file) as f:
    lines = f.readlines()

# Find tools: block, then tool block, then install: block, then pm key
in_tools = False
in_tool = False
in_install = False
tool_indent = None
install_indent = None

for line in lines:
    stripped = line.rstrip()
    indent = len(line) - len(line.lstrip())

    if stripped == 'tools:':
        in_tools = True
        continue

    if in_tools and not in_tool:
        m = re.match(r'^(\s+)' + re.escape(tool) + r':\s*$', line)
        if m:
            in_tool = True
            tool_indent = len(m.group(1))
        continue

    if in_tool and not in_install:
        if indent <= tool_indent and stripped and not stripped.startswith('#'):
            break  # left tool block
        m = re.match(r'^(\s+)install:\s*$', line)
        if m:
            in_install = True
            install_indent = len(m.group(1))
        continue

    if in_install:
        if indent <= install_indent and stripped and not stripped.startswith('#'):
            break  # left install block
        # Match pm: "command" or pm: command
        m = re.match(r'^\s+' + re.escape(pm) + r':\s*["\']?(.+?)["\']?\s*$', line)
        if m:
            val = m.group(1).strip().strip('"\'')
            if val and val != 'null':
                print(val)
            sys.exit(0)

sys.exit(0)
PY
}

yaml_get_check() {
  local tool="$1"
  python3 - "$CONFIG" "$tool" << 'PY'
import sys, re
config_file, tool = sys.argv[1], sys.argv[2]
with open(config_file) as f:
    lines = f.readlines()
in_tools = in_tool = False
tool_indent = None
for line in lines:
    stripped = line.rstrip()
    indent = len(line) - len(line.lstrip())
    if stripped == 'tools:':
        in_tools = True; continue
    if in_tools and not in_tool:
        m = re.match(r'^(\s+)' + re.escape(tool) + r':\s*$', line)
        if m:
            in_tool = True; tool_indent = len(m.group(1))
        continue
    if in_tool:
        if indent <= tool_indent and stripped and not stripped.startswith('#'):
            break
        m = re.match(r'^\s+check:\s*["\']?(.+?)["\']?\s*$', line)
        if m:
            print(m.group(1).strip().strip('"\''))
            sys.exit(0)
sys.exit(0)
PY
}

# Get all tool names from config
get_tools() {
  python3 - "$CONFIG" << 'PY'
import sys, re
with open(sys.argv[1]) as f:
    lines = f.readlines()
in_tools = False
for line in lines:
    stripped = line.rstrip()
    if stripped == 'tools:':
        in_tools = True; continue
    if in_tools:
        m = re.match(r'^  ([a-z][a-z0-9_-]+):\s*$', line)
        if m:
            print(m.group(1))
        elif stripped and not stripped.startswith(' ') and not stripped.startswith('#'):
            break
PY
}

# Get env var names from config
get_env_vars() {
  python3 - "$CONFIG" << 'PY'
import sys, re
with open(sys.argv[1]) as f:
    lines = f.readlines()
in_env = False
for line in lines:
    stripped = line.rstrip()
    if stripped == 'env_vars:':
        in_env = True; continue
    if in_env:
        m = re.match(r'^  ([A-Z][A-Z0-9_]+):\s*$', line)
        if m:
            print(m.group(1))
        elif stripped and not stripped.startswith(' ') and not stripped.startswith('#'):
            break
PY
}

# Get a scalar field for an env var
get_env_field() {
  local var="$1" field="$2"
  python3 - "$CONFIG" "$var" "$field" << 'PY'
import sys, re
config_file, var, field = sys.argv[1], sys.argv[2], sys.argv[3]
with open(config_file) as f:
    lines = f.readlines()
in_env = in_var = False
var_indent = None
for line in lines:
    stripped = line.rstrip()
    indent = len(line) - len(line.lstrip())
    if stripped == 'env_vars:':
        in_env = True; continue
    if in_env and not in_var:
        m = re.match(r'^  (' + re.escape(var) + r'):\s*$', line)
        if m:
            in_var = True; var_indent = 2
        continue
    if in_var:
        if indent <= var_indent and stripped and not stripped.startswith('#'):
            break
        m = re.match(r'^\s+' + re.escape(field) + r':\s*["\']?(.+?)["\']?\s*$', line)
        if m:
            print(m.group(1).strip().strip('"\''))
            sys.exit(0)
sys.exit(0)
PY
}

# ── Tool checker ──────────────────────────────────────────────────────────────
check_tool() {
  local tool="$1"
  local check_cmd
  check_cmd=$(yaml_get_check "$tool")
  [ -z "$check_cmd" ] && return 1

  # Method 1: command -v (fastest)
  local bin="${check_cmd%% *}"
  if command -v "$bin" &>/dev/null; then
    return 0
  fi

  # Method 2: which
  if which "$bin" &>/dev/null 2>&1; then
    return 0
  fi

  # Method 3: ask the package manager if it's installed
  case "$PM" in
    pacman)
      # pacman -Q <pkg> exits 0 if installed
      if pacman -Q "$tool" &>/dev/null 2>&1; then return 0; fi
      # try common package name variants
      if pacman -Q "${tool%-cli}" &>/dev/null 2>&1; then return 0; fi
      ;;
    apt)
      if dpkg -l "$tool" 2>/dev/null | grep -q '^ii'; then return 0; fi
      ;;
    brew)
      if brew list "$tool" &>/dev/null 2>&1; then return 0; fi
      ;;
    choco)
      if choco list --local-only "$tool" 2>/dev/null | grep -qi "$tool"; then return 0; fi
      ;;
    winget)
      if winget list --id "$tool" 2>/dev/null | grep -qi "$tool"; then return 0; fi
      ;;
  esac

  # Method 4: try running the check command directly
  if eval "$check_cmd" &>/dev/null 2>&1; then
    return 0
  fi

  return 1
}

install_tool() {
  local tool="$1"
  local cmd=""

  # Try package-manager-specific command first
  cmd=$(yaml_get_install "$tool" "$PM")

  # Fall back to 'any' (universal install script)
  if [ -z "$cmd" ]; then
    cmd=$(yaml_get_install "$tool" "any")
  fi

  # For npm-installable tools, try npm if node is available
  if [ -z "$cmd" ] && command -v npm &>/dev/null; then
    cmd=$(yaml_get_install "$tool" "npm")
  fi

  # For cargo-installable tools
  if [ -z "$cmd" ] && command -v cargo &>/dev/null; then
    cmd=$(yaml_get_install "$tool" "cargo")
  fi

  if [ -z "$cmd" ]; then
    warn "No install method found for '$tool' on $PM — skipping"
    return 1
  fi

  info "Installing $tool: $cmd"
  if [ "$MODE" != "--check" ]; then
    eval "$cmd"
  fi
}

# ── Env var prompter ──────────────────────────────────────────────────────────
prompt_env_var() {
  local var="$1"
  local current="${!var:-}"
  local required secret note default auto_gen get_from

  required=$(get_env_field "$var" "required")
  secret=$(get_env_field "$var" "secret")
  note=$(get_env_field "$var" "note")
  default=$(get_env_field "$var" "default")
  auto_gen=$(get_env_field "$var" "auto_generate")
  get_from=$(get_env_field "$var" "get_from")

  # Skip if already set in environment
  if [ -n "$current" ]; then
    ok "$var already set — skipping"
    return
  fi

  # Check if already in env file
  if [ -f "$ENV_FILE" ] && grep -q "^export $var=" "$ENV_FILE" 2>/dev/null; then
    ok "$var already in $ENV_FILE — skipping"
    return
  fi

  # Auto-generate if possible
  if [ -n "$auto_gen" ] && [ "$MODE" != "--check" ]; then
    local generated
    generated=$(eval "$auto_gen" 2>/dev/null || true)
    if [ -n "$generated" ]; then
      echo "export $var=\"$generated\"" >> "$ENV_FILE"
      ok "$var auto-generated"
      return
    fi
  fi

  # Build prompt string
  local prompt="$var"
  [ -n "$note" ] && prompt="$prompt ($note)"
  [ -n "$get_from" ] && prompt="$prompt\n     Get from: $get_from"
  [ -n "$default" ] && prompt="$prompt\n     Default: $default"
  [ "$required" = "true" ] && prompt="$prompt [REQUIRED]"

  echo -e "  ${C}$prompt${N}"

  local val=""
  if [ "$secret" = "true" ]; then
    read -rsp "  Value (hidden): " val; echo
  else
    read -rp "  Value: " val
  fi

  if [ -z "$val" ] && [ -n "$default" ]; then
    val="$default"
  fi

  if [ -n "$val" ]; then
    echo "export $var=\"$val\"" >> "$ENV_FILE"
    ok "Saved $var"
  elif [ "$required" = "true" ]; then
    warn "$var is required but was skipped — some skills won't work"
  else
    info "Skipped $var"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${B}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║          Agent Skills Installer                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${N}"
echo "  OS:              $OS_DISPLAY"
echo "  Package manager: $PM"
echo "  Skills dest:     $DEST"
echo "  Env file:        $ENV_FILE"
echo "  Mode:            ${MODE:-full}"
echo ""

# ── Step 1: Copy skills ───────────────────────────────────────────────────────
if [[ "$MODE" != "--env-only" && "$MODE" != "--tools-only" && "$MODE" != "--check" ]]; then
  hdr "Copying skills to $DEST"
  mkdir -p "$DEST"
  copied=0; skipped=0
  for skill_dir in "$SCRIPT_DIR"/*/; do
    skill_name="$(basename "$skill_dir")"
    # Skip non-directories and the install script itself
    [ -f "$skill_dir" ] && continue
    [[ "$skill_name" == "install.sh" ]] && continue
    if [ ! -d "$DEST/$skill_name" ]; then
      cp -r "$skill_dir" "$DEST/$skill_name"
      copied=$((copied+1))
    else
      skipped=$((skipped+1))
    fi
  done
  ok "Copied $copied skills  (skipped $skipped already present)"
fi

# ── Step 2: Check / install tools ─────────────────────────────────────────────
if [[ "$MODE" != "--env-only" ]]; then
  hdr "Checking CLI tools"

  missing_required=()
  missing_optional=()

  while IFS= read -r tool; do
    if check_tool "$tool"; then
      ok "$tool"
    else
      req=$(python3 - "$CONFIG" "$tool" << 'PY'
import sys, re
config_file, tool = sys.argv[1], sys.argv[2]
with open(config_file) as f:
    content = f.read()
# Find required field for this tool
m = re.search(r'  ' + re.escape(tool) + r':\n(?:.*\n)*?.*required:\s*(true|false)', content)
print(m.group(1) if m else 'false')
PY
)
      if [ "$req" = "true" ]; then
        err "$tool — MISSING (required)"
        missing_required+=("$tool")
      else
        warn "$tool — missing (optional)"
        missing_optional+=("$tool")
      fi
    fi
  done < <(get_tools)

  # Offer to install missing tools
  if [ ${#missing_required[@]} -gt 0 ] || [ ${#missing_optional[@]} -gt 0 ]; then
    echo ""
    if [ ${#missing_required[@]} -gt 0 ]; then
      echo -e "  ${R}Required tools missing:${N} ${missing_required[*]}"
    fi
    if [ ${#missing_optional[@]} -gt 0 ]; then
      echo -e "  ${Y}Optional tools missing:${N} ${missing_optional[*]}"
    fi
    echo ""

    if [ "$MODE" != "--check" ]; then
      read -rp "  Install missing tools now? [Y/n]: " yn
      yn="${yn:-Y}"
      if [[ "$yn" =~ ^[Yy] ]]; then
        for tool in "${missing_required[@]}" "${missing_optional[@]}"; do
          # Skip OS-specific tools that don't apply here
          [[ "$tool" == "scrot" && "$OS" != "linux"* ]] && continue
          [[ "$tool" == "nmap" && "$OS" == "windows" ]] && continue
          install_tool "$tool" || true
          # Run post_install if defined
          post=$(python3 - "$CONFIG" "$tool" << 'PY'
import sys, re
config_file, tool = sys.argv[1], sys.argv[2]
with open(config_file) as f:
    lines = f.readlines()
in_tools = in_tool = False
tool_indent = None
for line in lines:
    stripped = line.rstrip()
    indent = len(line) - len(line.lstrip())
    if stripped == 'tools:':
        in_tools = True; continue
    if in_tools and not in_tool:
        m = re.match(r'^  (' + re.escape(tool) + r'):\s*$', line)
        if m:
            in_tool = True; tool_indent = 2
        continue
    if in_tool:
        if indent <= tool_indent and stripped and not stripped.startswith('#'):
            break
        m = re.match(r'^\s+post_install:\s*["\']?(.+?)["\']?\s*$', line)
        if m:
            print(m.group(1).strip().strip('"\''))
            sys.exit(0)
sys.exit(0)
PY
)
          if [ -n "$post" ]; then
            info "Post-install: $post"
            read -rp "  Run '$post' now? [y/N]: " run_post
            [[ "$run_post" =~ ^[Yy] ]] && eval "$post" || true
          fi
        done
      fi
    fi
  fi
fi

# ── Step 3: Python packages ───────────────────────────────────────────────────
if [[ "$MODE" != "--env-only" && "$MODE" != "--check" ]]; then
  hdr "Python packages"

  PIP_CMD="pip3"
  command -v uv &>/dev/null && PIP_CMD="uv pip"

  check_py_pkg() {
    python3 -c "import $1" &>/dev/null 2>&1
  }

  declare -A PY_GROUPS=(
    ["backtesting"]="pandas numpy yfinance matplotlib"
    ["doc"]="docx pdf2image"
    ["llm_finetuning"]="torch transformers peft datasets"
  )
  declare -A PY_INSTALL=(
    ["backtesting"]="$PIP_CMD install pandas numpy yfinance matplotlib"
    ["doc"]="$PIP_CMD install python-docx pdf2image"
    ["llm_finetuning"]="$PIP_CMD install torch transformers peft datasets bitsandbytes accelerate"
  )

  for group in "${!PY_GROUPS[@]}"; do
    missing_py=()
    for pkg in ${PY_GROUPS[$group]}; do
      check_py_pkg "$pkg" || missing_py+=("$pkg")
    done
    if [ ${#missing_py[@]} -eq 0 ]; then
      ok "Python/$group — all present"
    else
      warn "Python/$group — missing: ${missing_py[*]}"
      read -rp "  Install? [y/N]: " yn
      [[ "$yn" =~ ^[Yy] ]] && eval "${PY_INSTALL[$group]}" || true
    fi
  done
fi

# ── Step 4: Environment variables ─────────────────────────────────────────────
if [[ "$MODE" != "--tools-only" && "$MODE" != "--check" ]]; then
  hdr "Environment variables → $ENV_FILE"
  [ -f "$ENV_FILE" ] || touch "$ENV_FILE"

  echo "  Skipping vars already set in your environment or env file."
  echo "  Press Enter to skip any optional var."
  echo ""

  while IFS= read -r var; do
    prompt_env_var "$var"
  done < <(get_env_vars)

  echo ""
  ok "Env vars saved to $ENV_FILE"
  echo ""
  echo -e "  Add to your shell profile (${C}~/.zshrc${N} or ${C}~/.bashrc${N}):"
  echo -e "    ${B}source $ENV_FILE${N}"
fi

# ── Step 5: Auth reminders ────────────────────────────────────────────────────
if [[ "$MODE" != "--check" ]]; then
  hdr "Auth steps (run these manually)"
  python3 - "$CONFIG" << 'PY'
import sys, re, yaml as _yaml
# fallback: parse manually if pyyaml not available
config_file = sys.argv[1]
with open(config_file) as f:
    content = f.read()
# Extract auth_steps block
m = re.search(r'^auth_steps:\n((?:  -.+\n(?:    .+\n)*)*)', content, re.MULTILINE)
if not m:
    sys.exit(0)
block = m.group(1)
for entry in re.finditer(r'  - cmd: ["\']?(.+?)["\']?\n(?:    skills:.*\n)?(?:    note: ["\']?(.+?)["\']?\n)?', block):
    cmd, note = entry.group(1), entry.group(2) or ''
    note_str = f'  # {note}' if note else ''
    print(f'  {cmd}{note_str}')
PY
fi

# ── Step 6: Runtime reminders ─────────────────────────────────────────────────
hdr "Runtime requirements (external services)"
python3 - "$CONFIG" << 'PY'
import sys, re
config_file = sys.argv[1]
with open(config_file) as f:
    content = f.read()
m = re.search(r'^runtime_requirements:\n((?:  -.+\n(?:    .+\n)*)*)', content, re.MULTILINE)
if not m:
    sys.exit(0)
block = m.group(1)
for entry in re.finditer(r'  - name: ["\']?(.+?)["\']?\n(?:    skills:.*\n)?(?:    note: ["\']?(.+?)["\']?\n)?', block):
    name, note = entry.group(1), entry.group(2) or ''
    note_str = f' — {note}' if note else ''
    print(f'  {name}{note_str}')
PY

echo ""
echo -e "${G}${B}Done!${N}"
echo "  Skills: $DEST"
echo "  Env:    $ENV_FILE"
echo ""

# ── Step 7: Run sync-skills.sh to symlink to all agent harnesses ──────────────
SYNC_SCRIPT="$HOME/.agents/sync-skills.sh"
if [ -x "$SYNC_SCRIPT" ] && [ "$MODE" != "--check" ] && [ "$MODE" != "--env-only" ]; then
  hdr "Syncing skills to all agent harnesses"
  read -rp "  Run sync-skills.sh to symlink skills to all agents (kiro, claude, codex, etc.)? [Y/n]: " yn
  yn="${yn:-Y}"
  if [[ "$yn" =~ ^[Yy] ]]; then
    bash "$SYNC_SCRIPT"
  fi
fi

# ── Step 8: Offer to source env file in shell profile ─────────────────────────
if [ "$MODE" != "--check" ] && [ "$MODE" != "--tools-only" ] && [ -f "$ENV_FILE" ]; then
  PROFILE=""
  [ -f "$HOME/.zshrc" ] && PROFILE="$HOME/.zshrc"
  [ -z "$PROFILE" ] && [ -f "$HOME/.bashrc" ] && PROFILE="$HOME/.bashrc"

  if [ -n "$PROFILE" ] && ! grep -q "skills.env" "$PROFILE" 2>/dev/null; then
    echo ""
    read -rp "  Add 'source $ENV_FILE' to $PROFILE? [Y/n]: " yn
    yn="${yn:-Y}"
    if [[ "$yn" =~ ^[Yy] ]]; then
      echo "" >> "$PROFILE"
      echo "# Agent Skills env vars" >> "$PROFILE"
      echo "[ -f \"$ENV_FILE\" ] && source \"$ENV_FILE\"" >> "$PROFILE"
      ok "Added to $PROFILE — restart your shell or run: source $PROFILE"
    fi
  fi
fi

echo ""
echo -e "${G}${B}All done!${N}"
echo "  Skills: $DEST"
echo "  Env:    $ENV_FILE"
echo ""
