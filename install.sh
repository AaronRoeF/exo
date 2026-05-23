#!/usr/bin/env bash
# Exo Installer
# ─────────────
# Installs the Exo skill bundle into ~/.claude/ and scaffolds ~/Exo/.
#
# Usage:
#   bash install.sh                  # Standard install (idempotent)
#   bash install.sh --dry-run        # Show what would happen, change nothing
#   bash install.sh --uninstall      # Remove Exo skills/hooks/commands (leaves ~/Exo/ data intact)
#   bash install.sh --skip-mcp       # Skip the optional exo-mcp install prompt
#
# Safe to re-run. Existing user data in ~/Exo/ is never overwritten.

set -euo pipefail

# ── Resolve repo root ──────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
EXO_DIR="${EXO_DIR:-$HOME/Exo}"

DRY_RUN=0
UNINSTALL=0
SKIP_MCP=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        --uninstall) UNINSTALL=1 ;;
        --skip-mcp)  SKIP_MCP=1 ;;
        --help|-h)
            sed -n '2,12p' "${BASH_SOURCE[0]}"
            exit 0
            ;;
        *) echo "Unknown arg: $arg (use --help)"; exit 2 ;;
    esac
done

# ── Helpers ────────────────────────────────────────────────────────────────
say()  { printf '%s\n' "$*"; }
step() { printf '\n──── %s ────\n' "$*"; }
ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] %s\n' "$*"
    else
        eval "$@"
    fi
}

copy_if_different() {
    local src="$1" dst="$2"
    [ -f "$src" ] || { warn "missing source: $src"; return; }
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
        return  # identical, skip silently
    fi
    if [ -f "$dst" ]; then
        # Existing differs — back up before overwriting
        run "cp '$dst' '$dst.exo-install-bak'"
        ok "$(basename "$dst") (backed up existing)"
    else
        ok "$(basename "$dst")"
    fi
    run "cp '$src' '$dst'"
}

# ── Uninstall path ─────────────────────────────────────────────────────────
if [ "$UNINSTALL" -eq 1 ]; then
    step "Uninstalling Exo skills, hooks, commands"
    say "User data at $EXO_DIR is NOT removed."
    run "rm -rf '$CLAUDE_HOME/skills/exo'"
    for h in exo-session-start.sh exo-focus-gate.sh exo-stop-dream.sh exo-til-flow.sh; do
        run "rm -f '$CLAUDE_HOME/hooks/$h'"
    done
    for c in daily prep wrap weekly enrich; do
        run "rm -f '$CLAUDE_HOME/commands/$c.md'"
    done
    say ""
    say "Exo removed from ~/.claude/. To remove user data: rm -rf $EXO_DIR (irreversible)."
    exit 0
fi

# ── Banner ─────────────────────────────────────────────────────────────────
cat <<'BANNER'

   _____
  | ____|_  _____
  |  _| \ \/ / _ \
  | |___ >  < (_) |
  |_____/_/\_\___/

  Exo installer

BANNER

[ "$DRY_RUN" -eq 1 ] && say "DRY RUN — no files will be modified."
say "Repo:        $REPO_ROOT"
say "Claude home: $CLAUDE_HOME"
say "Exo data:    $EXO_DIR"

# ── Pre-flight checks ──────────────────────────────────────────────────────
step "Pre-flight"

if [ ! -d "$CLAUDE_HOME" ]; then
    warn "No $CLAUDE_HOME found."
    say "  Claude Code likely isn't installed yet. Install Claude Code first,"
    say "  open it once so it creates ~/.claude/, then re-run this installer."
    exit 1
fi
ok "Claude Code present at $CLAUDE_HOME"

if ! command -v python3 >/dev/null 2>&1; then
    warn "python3 not in PATH. Settings.json validation will be skipped."
fi

# ── Install skills ─────────────────────────────────────────────────────────
step "Install skills → $CLAUDE_HOME/skills/exo/"

run "mkdir -p '$CLAUDE_HOME/skills/exo'"
SKILL_DIR_SRC="$REPO_ROOT/skills"
SKILL_DIR_DST="$CLAUDE_HOME/skills/exo"

# Copy the meta-skill + wizard (skills/exo/exo.md + skills/exo/wizard.md)
copy_if_different "$SKILL_DIR_SRC/exo/exo.md" "$SKILL_DIR_DST/exo.md"
copy_if_different "$SKILL_DIR_SRC/exo/wizard.md" "$SKILL_DIR_DST/wizard.md"

# Copy each peer skill as <name>.md (flatten the per-skill subdir into the bundle)
for s in apple capture dream email health lint pkg pulse runbook things vault verify; do
    if [ -f "$SKILL_DIR_SRC/$s/$s.md" ]; then
        copy_if_different "$SKILL_DIR_SRC/$s/$s.md" "$SKILL_DIR_DST/$s.md"
    fi
done

# ── Install hooks ──────────────────────────────────────────────────────────
step "Install hooks → $CLAUDE_HOME/hooks/"

run "mkdir -p '$CLAUDE_HOME/hooks'"
for h in exo-session-start.sh exo-focus-gate.sh exo-stop-dream.sh exo-til-flow.sh; do
    copy_if_different "$REPO_ROOT/hooks/$h" "$CLAUDE_HOME/hooks/$h"
    run "chmod +x '$CLAUDE_HOME/hooks/$h'"
done

# ── Install slash commands ─────────────────────────────────────────────────
step "Install slash commands → $CLAUDE_HOME/commands/"

run "mkdir -p '$CLAUDE_HOME/commands'"
for c in daily.md prep.md wrap.md weekly.md enrich.md; do
    copy_if_different "$REPO_ROOT/commands/$c" "$CLAUDE_HOME/commands/$c"
done

# ── Wire hooks into settings.json ──────────────────────────────────────────
step "Wire hooks into $CLAUDE_HOME/settings.json"

SETTINGS="$CLAUDE_HOME/settings.json"
if [ ! -f "$SETTINGS" ]; then
    warn "settings.json does not exist yet — creating a minimal one."
    run "cat > '$SETTINGS' <<'EOF'
{
  \"hooks\": {
    \"SessionStart\": [],
    \"PreToolUse\": [],
    \"Stop\": []
  }
}
EOF"
fi

# Use python3 to safely merge the hook entries (avoids parsing JSON in bash).
if command -v python3 >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  [dry-run] would patch settings.json to wire 3 hook entries:"
        say "            SessionStart → $CLAUDE_HOME/hooks/exo-session-start.sh"
        say "            PreToolUse (Edit|Write) → $CLAUDE_HOME/hooks/exo-focus-gate.sh"
        say "            Stop → $CLAUDE_HOME/hooks/exo-stop-dream.sh"
    else
        python3 - "$SETTINGS" "$CLAUDE_HOME" <<'PY'
import json, sys, os, shutil
settings_path = sys.argv[1]
claude_home = sys.argv[2]

# Backup once
bak = settings_path + ".exo-install-bak"
if not os.path.exists(bak):
    shutil.copy2(settings_path, bak)

with open(settings_path) as f:
    cfg = json.load(f)

cfg.setdefault("hooks", {})

def ensure_hook_event(event, entry, matcher=None):
    cfg["hooks"].setdefault(event, [])
    # Each event entry is a dict; collapse to a unique command identifier
    cmd = entry["hooks"][0]["command"]
    for e in cfg["hooks"][event]:
        for h in e.get("hooks", []):
            if h.get("command") == cmd:
                return  # already wired
    cfg["hooks"][event].append(entry)

ensure_hook_event("SessionStart", {
    "matcher": "",
    "hooks": [{"type": "command", "command": f"{claude_home}/hooks/exo-session-start.sh"}],
})
ensure_hook_event("PreToolUse", {
    "matcher": "Edit|Write",
    "hooks": [{"type": "command", "command": f"{claude_home}/hooks/exo-focus-gate.sh"}],
})
ensure_hook_event("Stop", {
    "matcher": "",
    "hooks": [{"type": "command", "command": f"{claude_home}/hooks/exo-stop-dream.sh"}],
})

with open(settings_path, "w") as f:
    json.dump(cfg, f, indent=2)

print("  ✓ settings.json patched (backed up at .exo-install-bak)")
PY
    fi
else
    warn "python3 unavailable — skipping settings.json patch."
    warn "Manually add hooks. See docs/install.md for the JSON to paste."
fi

# ── Scaffold ~/Exo/ data directory ─────────────────────────────────────────
step "Scaffold $EXO_DIR/"

run "mkdir -p '$EXO_DIR'"
for sub in people accounts decisions observations projects intel tmp .exo; do
    if [ -d "$EXO_DIR/$sub" ]; then
        ok "$sub/ (exists)"
    else
        run "mkdir -p '$EXO_DIR/$sub'"
        ok "$sub/ (created)"
    fi
done

# Install templates (do not overwrite if user has customized)
TEMPLATES_DIR="$EXO_DIR/templates"
if [ ! -d "$TEMPLATES_DIR" ]; then
    run "mkdir -p '$TEMPLATES_DIR'"
fi
for t in people.md accounts.md decisions.md pulse.md; do
    if [ -f "$TEMPLATES_DIR/$t" ]; then
        ok "templates/$t (exists, preserved)"
    else
        copy_if_different "$REPO_ROOT/templates/$t" "$TEMPLATES_DIR/$t"
    fi
done

# Initialize REVIEW-LOG.md if absent
if [ ! -f "$EXO_DIR/observations/REVIEW-LOG.md" ]; then
    run "touch '$EXO_DIR/observations/REVIEW-LOG.md'"
    ok "observations/REVIEW-LOG.md (initialized)"
fi

# ── Offer optional exo-mcp install ─────────────────────────────────────────
if [ "$SKIP_MCP" -eq 0 ]; then
    step "Optional: exo-mcp (Claude Desktop lite mode)"
    say ""
    say "exo-mcp is a separate MCP server that exposes the same Exo tools to"
    say "Claude Desktop. It's optional. You only need it if you want to use Exo"
    say "from Claude Desktop in addition to (or instead of) Claude Code."
    say ""
    say "To install later:"
    say "  npm install -g exo-mcp"
    say "  Then add to your Claude Desktop config (see mcp/exo/README.md)."
    say ""
fi

# ── Final: run the wizard ──────────────────────────────────────────────────
step "Setup wizard"

WIZARD_SENTINEL="$EXO_DIR/.exo/setup-complete"
if [ -f "$WIZARD_SENTINEL" ]; then
    ok "Wizard already completed (sentinel at $WIZARD_SENTINEL)"
    say ""
    say "Re-run anytime in Claude Code with:  /exo wizard"
else
    say ""
    say "Installer done. Open Claude Code in any directory and type:"
    say ""
    say "    /exo"
    say ""
    say "The 13-step wizard will scaffold your identity, top people, top accounts,"
    say "priorities, and connection preferences. ~5 minutes."
fi

step "Installer complete"
say ""
say "Skills:      installed to $CLAUDE_HOME/skills/exo/"
say "Hooks:       installed to $CLAUDE_HOME/hooks/ (and wired in settings.json)"
say "Commands:    installed to $CLAUDE_HOME/commands/"
say "Templates:   installed to $EXO_DIR/templates/"
say "Data dir:    $EXO_DIR/ (subdirs scaffolded)"
say ""
say "To uninstall the bundle (keeps your data):  bash install.sh --uninstall"
say "To verify install:                          bash tests/exo/run-all.sh"
say ""
