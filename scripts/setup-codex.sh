#!/bin/bash
set -e

# Resolve paths relative to this script's location, regardless of where it's called from.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
CODEX_CONFIG_SRC="$WORKSPACE_DIR/configs/codex/config.toml"        # Checked-in source of truth
MCP_URLS_FILE="$WORKSPACE_DIR/configs/mcp-urls.conf"               # One name=url per line
WORKSPACE_CODEX_DIR="$WORKSPACE_DIR/.codex"
CODEX_MCP_BRIDGE_DIR="$WORKSPACE_DIR/.codex-tools/supergateway"    # Local npm install of supergateway
CODEX_MCP_BRIDGE_BIN="$CODEX_MCP_BRIDGE_DIR/node_modules/.bin/supergateway"

# Helper: run apt-get with sudo if available, directly if already root, or fail gracefully.
run_apt() {
  if [ "$(id -u)" -eq 0 ]; then
    apt-get "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo apt-get "$@"
  else
    return 127
  fi
}

# Codex uses Bubblewrap (bwrap) to sandbox its tool execution on Linux.
# Install it if missing and apt-get is available (Debian/Ubuntu-based Codespaces).
if ! command -v bwrap >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
  if run_apt update && run_apt install -y bubblewrap; then
    echo "Installed bubblewrap for Codex sandboxing."
  else
    echo "WARNING: Unable to install bubblewrap automatically. Continuing without it." >&2
  fi
fi

mkdir -p "$WORKSPACE_CODEX_DIR" ~/.codex

# Link the checked-in config.toml into both the workspace .codex dir and the user home dir.
# Using symlinks means edits to configs/codex/config.toml take effect without re-running setup.
if [ -f "$CODEX_CONFIG_SRC" ]; then
  ln -sf "$CODEX_CONFIG_SRC" "$WORKSPACE_CODEX_DIR/config.toml"
  ln -sf "$CODEX_CONFIG_SRC" ~/.codex/config.toml
fi

# Verify the config was linked and that the expected codespace profile is active.
# The codespace profile sets sandbox_mode=danger-full-access and ask_for_approval=never,
# which lets Codex run autonomously inside the Codespace without prompting for every action.
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

# Codex does not natively support SSE-based MCP servers, so we use supergateway as a bridge.
# supergateway wraps an SSE endpoint and exposes it as a stdio subprocess that Codex can spawn.
# We install it locally under .codex-tools/supergateway rather than globally to keep the
# workspace self-contained and reproducible.
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

  # Register each MCP server with Codex via `codex mcp add`, passing the supergateway binary
  # as the command. Codex will spawn supergateway as a subprocess; supergateway connects
  # to the SSE URL and translates the protocol. Errors are suppressed — duplicate registrations
  # are harmless and the command may not exist in all environments.
  while IFS='=' read -r name url; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue ;; esac
    codex mcp add "$name" -- "$CODEX_MCP_BRIDGE_BIN" --sse "$url" --logLevel none 2>/dev/null || true
  done < "$MCP_URLS_FILE"
fi
