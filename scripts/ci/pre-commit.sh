#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

if [[ "${SKIP_LOCAL_CHECKS:-0}" == "1" ]]; then
  echo "Skipping local pre-commit checks because SKIP_LOCAL_CHECKS=1"
  exit 0
fi

echo "Running staged diff sanity checks..."
git diff --cached --check

staged_swift_files="$(git diff --cached --name-only --diff-filter=ACMR | rg '\.swift$|\.pbxproj$|\.storyboard$|\.plist$' || true)"
if [[ -n "$staged_swift_files" ]]; then
  echo "Detected app changes in the index:"
  echo "$staged_swift_files"
  echo "Full project build will run during pre-push and in GitHub Actions."
fi
