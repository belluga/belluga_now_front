#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFINES_FILE="${1:-}"

if [[ -z "${DEFINES_FILE}" ]]; then
  echo "Usage: bash tool/ci/run_workspace_test_contract.sh <defines-file>" >&2
  exit 2
fi

cd "$ROOT_DIR"

if [[ ! -f "${DEFINES_FILE}" ]]; then
  echo "ERROR: define file not found: ${DEFINES_FILE}" >&2
  exit 2
fi

echo "INFO: Running workspace Flutter tests with ${DEFINES_FILE}"
bash tool/run_workspace_flutter_tests.sh "${DEFINES_FILE}"
