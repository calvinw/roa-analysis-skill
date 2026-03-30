#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"

cd "$WORKSPACE_DIR"

CONFIGS="$WORKSPACE_DIR/configs/mcp"

# ─── Create workspace tool dirs and symlink MCP configs into them ─────────────
# Source-of-truth configs live in configs/mcp/; these dirs are generated at
# setup time and are excluded from version control.

mkdir -p \
  "$WORKSPACE_DIR/.copilot" \
  "$WORKSPACE_DIR/.opencode" \
  "$WORKSPACE_DIR/.gemini" \
  "$WORKSPACE_DIR/.claude"

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
# is streamable HTTP only, so register them through Supergateway as stdio servers.
if command -v jq >/dev/null 2>&1 && command -v codex >/dev/null 2>&1 && command -v npx >/dev/null 2>&1; then
  SETTINGS="$CONFIGS/claude-settings.json"
  if [ -f "$SETTINGS" ]; then
    jq -r '.mcpServers | to_entries[] | "\(.key) \(.value.url)"' "$SETTINGS" | \
    while IFS=' ' read -r name url; do
      codex mcp add "$name" -- npx -y supergateway --sse "$url" --logLevel none 2>/dev/null || true
    done
  fi
fi
