#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$WORKSPACE_DIR"

if ! command -v skillshare >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh
fi

skillshare sync

echo "Skills synced via skillshare."
