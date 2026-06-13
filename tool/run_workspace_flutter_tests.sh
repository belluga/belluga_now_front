#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFINES_FILE="${1:-}"

cd "$ROOT_DIR"

root_test_args=(--no-pub --exclude-tags=stage-compatibility)
if [[ -n "$DEFINES_FILE" ]]; then
  root_test_args+=(--dart-define-from-file="$DEFINES_FILE")
fi

echo "INFO: Running root Flutter test suite"
fvm flutter test "${root_test_args[@]}"

while IFS= read -r package_dir; do
  [[ -d "$package_dir/test" ]] || continue

  echo "INFO: Running package Flutter test suite -> ${package_dir#"$ROOT_DIR/"}"
  (
    cd "$package_dir"
    fvm flutter pub get
    fvm flutter test --no-pub
  )
done < <(find "$ROOT_DIR/packages" -mindepth 1 -maxdepth 1 -type d | sort)
