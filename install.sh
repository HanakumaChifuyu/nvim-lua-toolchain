#!/usr/bin/env bash
# install.sh — Install the nvim-lua-toolchain skill into ~/.claude/skills/
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
#   # or clone the repo and run:
#   bash path/to/nvim-lua-toolchain/install.sh

set -euo pipefail

SKILL_NAME="nvim-lua-toolchain"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
INSTALL_DIR="$SKILLS_DIR/$SKILL_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── helpers ────────────────────────────────────────────────────────────────────
log()  { printf '\033[0;34mℹ\033[0m  %s\n' "$*"; }
ok()   { printf '\033[0;32m✓\033[0m  %s\n' "$*"; }
warn() { printf '\033[1;33m⚠\033[0m  %s\n' "$*"; }
die()  { printf '\033[0;31m✗\033[0m  %s\n' "$*" >&2; exit 1; }

# ── checks ─────────────────────────────────────────────────────────────────────
if [ ! -f "$SCRIPT_DIR/SKILL.md" ]; then
    die "SKILL.md not found. Run this script from the nvim-lua-toolchain directory."
fi

# ── install ────────────────────────────────────────────────────────────────────
log "Installing $SKILL_NAME → $INSTALL_DIR"

if [ -d "$INSTALL_DIR" ]; then
    warn "Skill already exists at $INSTALL_DIR — updating in place."
fi

mkdir -p "$SKILLS_DIR"

# Copy the entire skill directory (exclude dev-only artifacts)
rsync -a --delete \
    --exclude='.git' \
    --exclude='.aider*' \
    --exclude='template_plugin/tests/.rocks' \
    --exclude='template_plugin/vendor' \
    --exclude='template_plugin/tests/.luacov.stats.out' \
    --exclude='template_plugin/tests/luacov.report.out' \
    "$SCRIPT_DIR/" "$INSTALL_DIR/" 2>/dev/null \
|| {
    # rsync not available — fall back to cp
    warn "rsync not found, falling back to cp (no incremental update)"
    rm -rf "$INSTALL_DIR"
    cp -r "$SCRIPT_DIR" "$INSTALL_DIR"
    # Remove dev artifacts manually
    rm -rf \
        "$INSTALL_DIR/.git" \
        "$INSTALL_DIR/.aider"* \
        "$INSTALL_DIR/template_plugin/tests/.rocks" \
        "$INSTALL_DIR/template_plugin/vendor" \
        "$INSTALL_DIR/template_plugin/tests/.luacov.stats.out" \
        "$INSTALL_DIR/template_plugin/tests/luacov.report.out" 2>/dev/null || true
}

chmod +x "$INSTALL_DIR/scripts/install-tools.sh" 2>/dev/null || true
chmod +x "$INSTALL_DIR/template_plugin/scripts/code-review.sh" 2>/dev/null || true

ok "Skill installed: $INSTALL_DIR"
echo ""
echo "Usage in your plugin repo:"
echo "  bash $INSTALL_DIR/scripts/install-tools.sh"
