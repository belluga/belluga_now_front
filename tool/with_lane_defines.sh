#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

lane="${1:-dev}"
shift || true

if [[ -z "${lane}" ]]; then
  echo "ERROR: missing lane (dev|stage|main)." >&2
  exit 1
fi

if [[ "$#" -eq 0 ]]; then
  echo "ERROR: missing flutter command. Example:" >&2
  echo "  ./tool/with_lane_defines.sh dev run --flavor guarappari" >&2
  exit 1
fi

lane_file="config/defines/${lane}.json"
if [[ ! -f "$lane_file" ]]; then
  echo "ERROR: lane define file not found: $lane_file" >&2
  exit 1
fi

local_override_file="config/defines/local.override.json"

cmd=(
  fvm flutter
  "$@"
  --dart-define-from-file="$lane_file"
)

if [[ -f "$local_override_file" ]]; then
  cmd+=(--dart-define-from-file="$local_override_file")
fi

echo "Running with lane defines: $lane_file"
if [[ -f "$local_override_file" ]]; then
  echo "Applying local overrides: $local_override_file"
fi

"${cmd[@]}"
