#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DERIVED_DATA_PATH="$(mktemp -d "${TMPDIR:-/tmp}/switch-chorus-build.XXXXXX")"
trap 'rm -rf "$DERIVED_DATA_PATH"' EXIT

PROJECT_PATH="${PROJECT_PATH:-$ROOT_DIR/switch-chorus-demo.xcodeproj}"
SCHEME_NAME="${SCHEME_NAME:-switch-chorus-demo}"
CONFIGURATION_NAME="${CONFIGURATION_NAME:-Debug}"
DESTINATION_NAME="${DESTINATION_NAME:-generic/platform=iOS Simulator}"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild is not available in PATH" >&2
  exit 1
fi

set -x
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -configuration "$CONFIGURATION_NAME" \
  -destination "$DESTINATION_NAME" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build
