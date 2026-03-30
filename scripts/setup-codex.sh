#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
CODEX_CONFIG_SRC="$WORKSPACE_DIR/configs/codex/config.toml"
WORKSPACE_CODEX_DIR="$WORKSPACE_DIR/.codex"

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
