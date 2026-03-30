#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"
CLAUDE_SETTINGS="$WORKSPACE_DIR/.claude/settings.json"

mkdir -p "$WORKSPACE_DIR/.claude" ~/.claude

{
  echo "{"
  echo '  "mcpServers": {'
  first=1
  while IFS='=' read -r name url; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue ;; esac
    if [ $first -eq 0 ]; then
      echo ","
    fi
    printf '    "%s": {\n' "$name"
    printf '      "transport": "sse",\n'
    printf '      "url": "%s"\n' "$url"
    printf '    }'
    first=0
  done < "$MCP_URLS_FILE"
  echo
  echo "  }"
  echo "}"
} > "$CLAUDE_SETTINGS"

ln -sf "$CLAUDE_SETTINGS" ~/.claude/settings.json

if command -v claude >/dev/null 2>&1; then
  while IFS='=' read -r name url; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue ;; esac
    claude mcp add -s user "$name" --transport sse "$url" 2>/dev/null || true
  done < "$MCP_URLS_FILE"
fi
