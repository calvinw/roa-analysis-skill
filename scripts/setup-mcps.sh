#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"

cd "$WORKSPACE_DIR"

CONFIGS="$WORKSPACE_DIR/configs/mcp"
CODEX_MCP_BRIDGE_DIR="$WORKSPACE_DIR/.codex-tools/supergateway"
CODEX_MCP_BRIDGE_BIN="$CODEX_MCP_BRIDGE_DIR/node_modules/.bin/supergateway"
CODEX_CONFIG_SRC="$WORKSPACE_DIR/.codex/config.toml"

# ─── Create workspace tool dirs and symlink MCP configs into them ─────────────
# Source-of-truth configs live in configs/mcp/; these dirs are generated at
# setup time and are excluded from version control.

mkdir -p \
  "$WORKSPACE_DIR/.copilot" \
  "$WORKSPACE_DIR/.opencode" \
  "$WORKSPACE_DIR/.gemini" \
  "$WORKSPACE_DIR/.claude" \
  "$WORKSPACE_DIR/.codex"

ln -sf "$CONFIGS/copilot-mcp-config.json" "$WORKSPACE_DIR/.copilot/mcp-config.json"
ln -sf "$CONFIGS/opencode.json"           "$WORKSPACE_DIR/.opencode/opencode.json"
ln -sf "$CONFIGS/gemini-settings.json"    "$WORKSPACE_DIR/.gemini/settings.json"
ln -sf "$CONFIGS/claude-settings.json"    "$WORKSPACE_DIR/.claude/settings.json"

# ─── MCP Servers ──────────────────────────────────────────────────────────────
# Symlinks below make configs available globally (e.g. when running a tool
# outside the project directory).
mkdir -p ~/.copilot ~/.config/opencode ~/.gemini ~/.config/crush
ln -sf "$WORKSPACE_DIR/.copilot/mcp-config.json"   ~/.copilot/mcp-config.json
ln -sf "$WORKSPACE_DIR/.opencode/opencode.json"     ~/.config/opencode/opencode.json
ln -sf "$WORKSPACE_DIR/.gemini/settings.json"       ~/.gemini/settings.json
ln -sf "$WORKSPACE_DIR/.crush.json"                 ~/.config/crush/crush.json

# Keep Codex settings in the repo so Codespaces can bootstrap a consistent
# teaching environment before MCP servers are registered.
mkdir -p ~/.codex
if [ -f "$CODEX_CONFIG_SRC" ]; then
  ln -sf "$CODEX_CONFIG_SRC" ~/.codex/config.toml
fi

# Register Claude Code MCP servers from configs/mcp/claude-settings.json into ~/.claude.json
if command -v jq >/dev/null 2>&1 && command -v claude >/dev/null 2>&1; then
  SETTINGS="$CONFIGS/claude-settings.json"
  if [ -f "$SETTINGS" ]; then
    jq -r '.mcpServers | to_entries[] | "\(.key) \(.value.url)"' "$SETTINGS" | \
    while IFS=' ' read -r name url; do
      claude mcp add -s user "$name" --transport sse "$url" 2>/dev/null || true
    done
  fi
fi

# Register Codex MCP servers from configs/mcp/claude-settings.json into ~/.codex/config.toml.
# These MCP servers expose legacy SSE endpoints; current Codex CLI `--url` support
# is streamable HTTP only, so register them through a pinned local Supergateway
# install as stdio servers rather than relying on transient `npx` caches.
if command -v jq >/dev/null 2>&1 && command -v codex >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  if [ ! -x "$CODEX_MCP_BRIDGE_BIN" ]; then
    mkdir -p "$CODEX_MCP_BRIDGE_DIR"
    if [ ! -f "$CODEX_MCP_BRIDGE_DIR/package.json" ]; then
      cat > "$CODEX_MCP_BRIDGE_DIR/package.json" <<'EOF'
{
  "name": "codex-mcp-bridge",
  "private": true,
  "version": "1.0.0",
  "dependencies": {
    "supergateway": "3.4.3"
  }
}
EOF
    fi
    npm install --prefix "$CODEX_MCP_BRIDGE_DIR" >/dev/null 2>&1
  fi

  SETTINGS="$CONFIGS/claude-settings.json"
  if [ -f "$SETTINGS" ]; then
    jq -r '.mcpServers | to_entries[] | "\(.key) \(.value.url)"' "$SETTINGS" | \
    while IFS=' ' read -r name url; do
      codex mcp add "$name" -- "$CODEX_MCP_BRIDGE_BIN" --sse "$url" --logLevel none 2>/dev/null || true
    done
  fi
fi
