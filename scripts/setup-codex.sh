#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
CODEX_CONFIG_SRC="$WORKSPACE_DIR/configs/codex/config.toml"
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"
WORKSPACE_CODEX_DIR="$WORKSPACE_DIR/.codex"
CODEX_MCP_BRIDGE_DIR="$WORKSPACE_DIR/.codex-tools/supergateway"
CODEX_MCP_BRIDGE_BIN="$CODEX_MCP_BRIDGE_DIR/node_modules/.bin/supergateway"

run_apt() {
  if [ "$(id -u)" -eq 0 ]; then
    apt-get "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo apt-get "$@"
  else
    return 127
  fi
}

# Install Bubblewrap for Codex sandboxing in Debian/Ubuntu-based environments.
if ! command -v bwrap >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
  if run_apt update && run_apt install -y bubblewrap; then
    echo "Installed bubblewrap for Codex sandboxing."
  else
    echo "WARNING: Unable to install bubblewrap automatically. Continuing without it." >&2
  fi
fi

mkdir -p "$WORKSPACE_CODEX_DIR" ~/.codex

if [ -f "$CODEX_CONFIG_SRC" ]; then
  ln -sf "$CODEX_CONFIG_SRC" "$WORKSPACE_CODEX_DIR/config.toml"
  ln -sf "$CODEX_CONFIG_SRC" ~/.codex/config.toml
fi

if [ -f ~/.codex/config.toml ]; then
  echo "Codex config linked: ~/.codex/config.toml -> $(readlink -f ~/.codex/config.toml)"
  if grep -q 'profile = "codespace"' ~/.codex/config.toml && \
     grep -q 'sandbox_mode = "danger-full-access"' ~/.codex/config.toml && \
     grep -q 'ask_for_approval = "never"' ~/.codex/config.toml; then
    echo "Codex default profile verified: codespace (danger-full-access, ask_for_approval=never)"
  else
    echo "WARNING: Codex config found, but the expected codespace profile defaults were not detected."
  fi
else
  echo "WARNING: ~/.codex/config.toml was not created."
fi

if command -v codex >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
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

  while IFS='=' read -r name url; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue ;; esac
    codex mcp add "$name" -- "$CODEX_MCP_BRIDGE_BIN" --sse "$url" --logLevel none 2>/dev/null || true
  done < "$MCP_URLS_FILE"
fi
