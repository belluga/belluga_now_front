#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

define_file="${INTEGRATION_DEFINE_FILE:-config/defines/integration.tenant.json}"
device="${ADB_DEVICE:-192.168.15.5:5555}"
flavor="${FLUTTER_INTEGRATION_FLAVOR:-belluga}"

if [[ ! -f "$define_file" ]]; then
  echo "ERROR: define file not found: $define_file" >&2
  exit 1
fi

if [[ "$#" -eq 0 ]]; then
  set -- integration_test
fi

cmd=(
  fvm flutter test
  "$@"
  -d "$device"
  --flavor "$flavor"
  --dart-define-from-file="$define_file"
)

echo "Running integration tests in WSL-aware mode"
echo "  Device: $device"
echo "  Flavor: $flavor"
echo "  Defines: $define_file"

"${cmd[@]}"
