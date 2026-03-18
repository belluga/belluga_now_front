#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-origin/dev}"
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

mapfile -t changed_files < <(
  git diff --name-only "${base_ref}"...HEAD -- '*.dart' |
    rg -v '^tool/belluga_custom_lint/test_fixtures/'
)

if [[ ${#changed_files[@]} -eq 0 ]]; then
  echo "[branch-delta] No changed Dart files against ${base_ref}."
  exit 0
fi

analysis_file="analysis_options.yaml"
backup_file="$(mktemp)"
output_file="$(mktemp)"
restore_analysis_options() {
  cp "$backup_file" "$analysis_file"
  rm -f "$backup_file" "$output_file"
}
trap restore_analysis_options EXIT

cp "$analysis_file" "$backup_file"

if rg -n "repository_raw_payload_map_forbidden:" "$analysis_file" >/dev/null; then
  sed -i \
    "s/repository_raw_payload_map_forbidden:[[:space:]]*false/repository_raw_payload_map_forbidden: true/g" \
    "$analysis_file"
else
  cat >> "$analysis_file" <<'PATCH'

custom_lint:
  rules:
    - repository_raw_payload_map_forbidden: true
PATCH
fi

set +e
fvm dart run custom_lint --no-fatal-infos --no-fatal-warnings >"$output_file" 2>&1
lint_status=$?
set -e

cat "$output_file"

hit=0
for file in "${changed_files[@]}"; do
  escaped_file="$(printf '%s' "$file" | sed -e 's/[.[\*^$()+?{|]/\\&/g')"
  if rg -n "${escaped_file}:[0-9]+:[0-9]+ .*repository_raw_payload_map_forbidden" "$output_file" >/dev/null; then
    hit=1
    break
  fi
done

if [[ $hit -eq 1 ]]; then
  echo
  echo "[branch-delta] repository_raw_payload_map_forbidden violations detected in changed files."
  exit 1
fi

if [[ $lint_status -ne 0 ]]; then
  echo
  echo "[branch-delta] custom_lint reported non-zero status; inspect output."
  exit "$lint_status"
fi

echo

echo "[branch-delta] No repository_raw_payload_map_forbidden findings in changed files."
