#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"
COPILOT_CONFIG="$WORKSPACE_DIR/.copilot/mcp-config.json"

mkdir -p "$WORKSPACE_DIR/.copilot" ~/.copilot

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
} > "$COPILOT_CONFIG"

ln -sf "$COPILOT_CONFIG" ~/.copilot/mcp-config.json
