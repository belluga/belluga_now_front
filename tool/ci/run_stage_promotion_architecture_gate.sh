#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROMOTION_LANE="${1:-}"

if [[ -z "${PROMOTION_LANE}" ]]; then
  echo "Usage: bash tool/ci/run_stage_promotion_architecture_gate.sh <stage|main>" >&2
  exit 2
fi

case "${PROMOTION_LANE}" in
  stage|main) ;;
  *)
    echo "ERROR: unsupported promotion lane '${PROMOTION_LANE}'. Expected stage|main." >&2
    exit 2
    ;;
esac

cd "$ROOT_DIR"

ANALYZE_PATHS=(
  assets
  integration_test
  lib
  packages
  test
  test_driver
  tool
)

echo "INFO: Running architecture gate for promotion lane ${PROMOTION_LANE}"
fvm dart pub get --directory tool/belluga_analysis_plugin/test_fixtures/lint_matrix
bash tool/belluga_analysis_plugin/bin/validate_rule_matrix.sh
fvm dart analyze "${ANALYZE_PATHS[@]}" --format machine
