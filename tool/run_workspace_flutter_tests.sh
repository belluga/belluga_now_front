#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFINES_FILE="${1:-}"

cd "$ROOT_DIR"

root_test_args=(--no-pub --exclude-tags=stage-compatibility --exclude-tags=golden)
if [[ -n "$DEFINES_FILE" ]]; then
  root_test_args+=(--dart-define-from-file="$DEFINES_FILE")
fi

echo "INFO: Running root Flutter functional test suite with Impeller"
# The host's SkSL test backend cannot load the Vulkan-only Material ink shader.
# Functional widget tests therefore run on Impeller, while visual golden tests
# keep their SkSL baseline in the dedicated lane below. Neither surface is
# skipped: every root test is included in exactly one renderer lane.
fvm flutter test --enable-impeller "${root_test_args[@]}"

echo "INFO: Running root Flutter golden test suite with SkSL baselines"
fvm flutter test --no-pub \
  test/presentation/tenant_admin/shared/tenant_admin_visual_regression_golden_test.dart

while IFS= read -r package_dir; do
  [[ -d "$package_dir/test" ]] || continue

  echo "INFO: Running package Flutter test suite -> ${package_dir#"$ROOT_DIR/"}"
  (
    cd "$package_dir"
    fvm flutter pub get
    fvm flutter test --no-pub
  )
done < <(find "$ROOT_DIR/packages" -mindepth 1 -maxdepth 1 -type d | sort)
