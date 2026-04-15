#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

if [[ "${SKIP_LOCAL_BUILD:-0}" == "1" ]]; then
  echo "Skipping local pre-push build because SKIP_LOCAL_BUILD=1"
  cat >/dev/null
  exit 0
fi

# Drain stdin so git push can continue after the hook exits.
cat >/dev/null

echo "Running local pre-push build gate..."
"$ROOT_DIR/scripts/ci/xcode-build.sh"
