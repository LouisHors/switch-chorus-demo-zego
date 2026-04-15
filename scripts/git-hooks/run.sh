#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <hook-name> [args...]" >&2
  exit 1
fi

HOOK_NAME="$1"
shift || true
ROOT_DIR="$(git rev-parse --show-toplevel)"
BEADS_HOOK="$ROOT_DIR/.beads/hooks/$HOOK_NAME"

if [[ -x "$BEADS_HOOK" ]]; then
  "$BEADS_HOOK" "$@"
fi

case "$HOOK_NAME" in
  pre-commit)
    exec "$ROOT_DIR/scripts/ci/pre-commit.sh" "$@"
    ;;
  pre-push)
    exec "$ROOT_DIR/scripts/ci/pre-push.sh" "$@"
    ;;
  *)
    exit 0
    ;;
esac
