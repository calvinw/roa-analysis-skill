#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"
OPENCODE_CONFIG="$WORKSPACE_DIR/.opencode/opencode.json"

mkdir -p "$WORKSPACE_DIR/.opencode" ~/.config/opencode

{
  echo "{"
  echo '  "$schema": "https://opencode.ai/config.json",'
  echo '  "mcp": {'
  first=1
  while IFS='=' read -r name url; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue ;; esac
    if [ $first -eq 0 ]; then
      echo ","
    fi
    printf '    "%s": {\n' "$name"
    printf '      "type": "remote",\n'
    printf '      "url": "%s",\n' "$url"
    printf '      "enabled": true\n'
    printf '    }'
    first=0
  done < "$MCP_URLS_FILE"
  echo
  echo "  }"
  echo "}"
} > "$OPENCODE_CONFIG"

ln -sf "$OPENCODE_CONFIG" ~/.config/opencode/opencode.json
