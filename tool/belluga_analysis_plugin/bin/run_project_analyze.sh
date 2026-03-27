#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

analysis_options_file="${ANALYSIS_OPTIONS_FILE:-analysis_options.yaml}"
batch_size="${BATCH_SIZE:-120}"
timeout_seconds="${TIMEOUT_SECONDS:-900}"

if [[ ! -f "$analysis_options_file" ]]; then
  echo "[run_project_analyze] analysis options file not found: $analysis_options_file"
  exit 1
fi

if ! rg -q '^plugins:\s*$' "$analysis_options_file"; then
  echo "[run_project_analyze] missing top-level 'plugins:' section in $analysis_options_file"
  exit 1
fi

if ! awk '
  BEGIN{in_plugins=0; found=0}
  /^plugins:[[:space:]]*$/ {in_plugins=1; next}
  in_plugins && /^[^[:space:]]/ {in_plugins=0}
  in_plugins && /^[[:space:]]*belluga_analysis_plugin:[[:space:]]*$/ {found=1}
  END{exit(found?0:1)}
' "$analysis_options_file"; then
  echo "[run_project_analyze] missing 'belluga_analysis_plugin' under top-level plugins in $analysis_options_file"
  exit 1
fi

if ! [[ "$batch_size" =~ ^[0-9]+$ ]] || [[ "$batch_size" -le 0 ]]; then
  echo "[run_project_analyze] invalid BATCH_SIZE: $batch_size"
  exit 1
fi

if ! [[ "$timeout_seconds" =~ ^[0-9]+$ ]] || [[ "$timeout_seconds" -le 0 ]]; then
  echo "[run_project_analyze] invalid TIMEOUT_SECONDS: $timeout_seconds"
  exit 1
fi

all_files_file="$(mktemp)"
exclude_patterns_file="$(mktemp)"
selected_files_file="$(mktemp)"
all_diagnostics_file="$(mktemp)"
dedup_diagnostics_file="$(mktemp)"
summary_json_file="$(mktemp)"

cleanup() {
  rm -f "$all_files_file" "$exclude_patterns_file" "$selected_files_file" \
    "$all_diagnostics_file" "$dedup_diagnostics_file" "$summary_json_file"
}
trap cleanup EXIT

git ls-files '*.dart' | sort > "$all_files_file"

python3 - "$analysis_options_file" "$exclude_patterns_file" <<'PY'
import sys

analysis_path, output_path = sys.argv[1], sys.argv[2]
lines = open(analysis_path, encoding='utf-8').read().splitlines()

patterns = []
in_analyzer = False
in_exclude = False
analyzer_indent = 0
exclude_indent = 0

for raw in lines:
    stripped = raw.strip()
    if not stripped or stripped.startswith('#'):
        continue

    indent = len(raw) - len(raw.lstrip(' '))

    if not in_analyzer:
        if indent == 0 and stripped == 'analyzer:':
            in_analyzer = True
            analyzer_indent = indent
        continue

    if in_exclude:
        if stripped.startswith('- '):
            value = stripped[2:].strip().strip('"\'')
            if value:
                patterns.append(value)
            continue
        if indent <= exclude_indent:
            in_exclude = False
        else:
            continue

    if in_analyzer:
        if indent <= analyzer_indent and stripped.endswith(':') and stripped != 'analyzer:':
            in_analyzer = False
            continue
        if stripped == 'exclude:':
            in_exclude = True
            exclude_indent = indent

with open(output_path, 'w', encoding='utf-8') as fh:
    for pattern in patterns:
        fh.write(pattern)
        fh.write('\n')
PY

python3 - "$all_files_file" "$exclude_patterns_file" "$selected_files_file" <<'PY'
import fnmatch
import sys

all_files_path, patterns_path, selected_path = sys.argv[1], sys.argv[2], sys.argv[3]

files = [line.strip() for line in open(all_files_path, encoding='utf-8') if line.strip()]
patterns = [line.strip() for line in open(patterns_path, encoding='utf-8') if line.strip()]

selected = []
for rel in files:
    excluded = False
    for pattern in patterns:
        if fnmatch.fnmatch(rel, pattern) or fnmatch.fnmatch('./' + rel, pattern):
            excluded = True
            break
    if not excluded:
        selected.append(rel)

with open(selected_path, 'w', encoding='utf-8') as fh:
    for rel in selected:
        fh.write(rel)
        fh.write('\n')
PY

all_count="$(wc -l < "$all_files_file" | tr -d ' ')"
selected_count="$(wc -l < "$selected_files_file" | tr -d ' ')"

echo "[run_project_analyze] analysis options: $analysis_options_file"
echo "[run_project_analyze] discovered Dart files: $all_count"
echo "[run_project_analyze] selected Dart files: $selected_count"

echo "[run_project_analyze] exclude patterns ($(wc -l < "$exclude_patterns_file" | tr -d ' ')):"
while IFS= read -r pattern; do
  [[ -n "$pattern" ]] && echo "  - $pattern"
done < "$exclude_patterns_file"

if [[ "$selected_count" -eq 0 ]]; then
  echo "[run_project_analyze] no Dart files selected after exclude filtering"
  exit 0
fi

mapfile -t selected_files < "$selected_files_file"
total_batches=$(( (selected_count + batch_size - 1) / batch_size ))

for ((batch_index=0; batch_index<total_batches; batch_index++)); do
  start=$(( batch_index * batch_size ))
  end=$(( start + batch_size ))
  if (( end > selected_count )); then
    end=$selected_count
  fi

  chunk=("${selected_files[@]:start:end-start}")
  echo "[run_project_analyze] batch $((batch_index + 1))/$total_batches (${#chunk[@]} files)"

  batch_output_file="$(mktemp)"
  set +e
  timeout "$timeout_seconds" fvm dart analyze --format machine "${chunk[@]}" > "$batch_output_file" 2>&1
  status=$?
  set -e

  if [[ "$status" -eq 124 ]]; then
    echo "[run_project_analyze] batch $((batch_index + 1)) timed out after ${timeout_seconds}s"
    sed -n '1,80p' "$batch_output_file"
    rm -f "$batch_output_file"
    exit 1
  fi

  if [[ "$status" -ne 0 && "$status" -ne 2 && "$status" -ne 3 ]]; then
    echo "[run_project_analyze] unexpected analyzer exit code in batch $((batch_index + 1)): $status"
    sed -n '1,120p' "$batch_output_file"
    rm -f "$batch_output_file"
    exit "$status"
  fi

  if rg -q "plugin.*crash|Failed to start plugin|Unhandled exception.*plugin" "$batch_output_file"; then
    echo "[run_project_analyze] analyzer plugin runtime error detected in batch $((batch_index + 1))"
    sed -n '1,120p' "$batch_output_file"
    rm -f "$batch_output_file"
    exit 1
  fi

  rg '^(INFO|WARNING|ERROR)\|' "$batch_output_file" >> "$all_diagnostics_file" || true
  rm -f "$batch_output_file"
done

python3 - "$all_diagnostics_file" "$dedup_diagnostics_file" "$summary_json_file" <<'PY'
import json
import sys
from collections import Counter

all_path, dedup_path, summary_path = sys.argv[1], sys.argv[2], sys.argv[3]

seen = {}
severity_counts = Counter()
code_counts = Counter()

for raw in open(all_path, encoding='utf-8'):
    line = raw.strip()
    if not line:
        continue
    parts = line.split('|', 7)
    if len(parts) < 8:
        continue
    severity, _, code, file_path, line_no = parts[0], parts[1], parts[2], parts[3], parts[4]
    key = (code, file_path, line_no)
    if key in seen:
        continue
    seen[key] = line
    severity_counts[severity] += 1
    code_counts[code] += 1

with open(dedup_path, 'w', encoding='utf-8') as fh:
    for line in seen.values():
        fh.write(line)
        fh.write('\n')

summary = {
    'unique_total': len(seen),
    'severity_counts': dict(severity_counts),
    'code_counts': dict(code_counts),
}
open(summary_path, 'w', encoding='utf-8').write(json.dumps(summary))
PY

unique_total="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["unique_total"])' "$summary_json_file")"

if [[ "$unique_total" -eq 0 ]]; then
  echo "[run_project_analyze] no issues found (unique diagnostics: 0)"
  exit 0
fi

echo "[run_project_analyze] unique diagnostics: $unique_total"
echo "[run_project_analyze] severity counts:"
python3 - "$summary_json_file" <<'PY'
import json
import sys
summary = json.load(open(sys.argv[1]))
for severity, count in sorted(summary['severity_counts'].items()):
    print(f"  - {severity}: {count}")
PY

echo "[run_project_analyze] top diagnostic codes:"
python3 - "$summary_json_file" <<'PY'
import json
import sys
summary = json.load(open(sys.argv[1]))
codes = sorted(summary['code_counts'].items(), key=lambda it: (-it[1], it[0]))
for code, count in codes[:20]:
    print(f"  - {code}: {count}")
PY

echo "[run_project_analyze] first diagnostics sample:"
sed -n '1,25p' "$dedup_diagnostics_file"

exit 2
