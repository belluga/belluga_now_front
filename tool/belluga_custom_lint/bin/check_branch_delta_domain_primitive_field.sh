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

if rg -n "domain_primitive_field_forbidden:" "$analysis_file" >/dev/null; then
  sed -i \
    "s/domain_primitive_field_forbidden:[[:space:]]*false/domain_primitive_field_forbidden: true/g" \
    "$analysis_file"
else
  cat >> "$analysis_file" <<'PATCH'

custom_lint:
  rules:
    - domain_primitive_field_forbidden: true
PATCH
fi

set +e
fvm dart run custom_lint --no-fatal-infos --no-fatal-warnings >"$output_file" 2>&1
lint_status=$?
set -e

cat "$output_file"

hit=0
declare -a hit_files=()
for file in "${changed_files[@]}"; do
  escaped_file="$(printf '%s' "$file" | sed -e 's/[.[\*^$()+?{|]/\\&/g')"
  if rg -n "${escaped_file}:[0-9]+:[0-9]+ .*domain_primitive_field_forbidden" "$output_file" >/dev/null; then
    hit=1
    hit_files+=("$file")
  fi
done

if [[ $hit -eq 1 ]]; then
  echo
  printf '[branch-delta] domain_primitive_field_forbidden files:\n'
  printf ' - %s\n' "${hit_files[@]}"
  echo "[branch-delta] domain_primitive_field_forbidden violations detected in changed files."
  exit 1
fi

mapfile -t changed_domain_files < <(
  printf '%s\n' "${changed_files[@]}" |
    rg '^lib/domain/.*\.dart$' || true
)

if [[ ${#changed_domain_files[@]} -gt 0 ]]; then
  typedef_pattern='^\s*typedef\s+\w*(?:Raw|Prim)\w*\s*=|^\s*typedef\s+\w+\s*=\s*[^;]*\b(?:String|int|double|bool|num|DateTime|Duration|Uri|dynamic)\b'
  typedef_hits="$(
    rg -n --pcre2 "$typedef_pattern" "${changed_domain_files[@]}" || true
  )"
  if [[ -n "$typedef_hits" ]]; then
    echo
    echo "$typedef_hits"
    echo
    echo "[branch-delta] primitive typedef alias workaround detected in changed domain files."
    echo "[branch-delta] Replace alias-based primitives with ValueObjects/domain-owned types."
    exit 1
  fi
fi

if [[ $lint_status -ne 0 ]]; then
  echo
  echo "[branch-delta] custom_lint reported non-zero status; inspect output."
  exit "$lint_status"
fi

echo
echo "[branch-delta] No domain_primitive_field_forbidden findings in changed files."
