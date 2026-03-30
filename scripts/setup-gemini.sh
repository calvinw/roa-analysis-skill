#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"
GEMINI_SETTINGS="$WORKSPACE_DIR/.gemini/settings.json"

mkdir -p "$WORKSPACE_DIR/.gemini" ~/.gemini

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
    printf '      "type": "sse",\n'
    printf '      "url": "%s"\n' "$url"
    printf '    }'
    first=0
  done < "$MCP_URLS_FILE"
  echo
  echo "  }"
  echo "}"
} > "$GEMINI_SETTINGS"

ln -sf "$GEMINI_SETTINGS" ~/.gemini/settings.json
