#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$WORKSPACE_DIR"

if ! command -v skillshare >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh
fi

skillshare sync

mkdir -p "$HOME/.codex/skills"

for skill_dir in "$WORKSPACE_DIR"/.skillshare/skills/*; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"
  ln -sfn "$skill_dir" "$HOME/.codex/skills/$skill_name"
done

echo "Synced repo skills into $HOME/.codex/skills"
echo "Restart the Codex session if the skill list was already loaded before this sync."
