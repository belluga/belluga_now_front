#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

log_dir="foundation_documentation/artifacts/tmp"
mkdir -p "$log_dir"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
log_file="${log_dir}/custom_lint_${timestamp}.log"

existing_runs="$(
  pgrep -af "dart run custom_lint" |
    rg -v "run_custom_lint_with_heartbeat\\.sh|$$" || true
)"
if [[ -n "$existing_runs" ]]; then
  echo "[custom-lint] Warning: detected other custom_lint process(es):"
  echo "$existing_runs"
fi

echo "[custom-lint] Command: fvm dart run custom_lint $*"
echo "[custom-lint] Log file: $log_file"

cleanup() {
  if [[ -n "${lint_pid:-}" ]]; then
    kill "${lint_pid}" 2>/dev/null || true
  fi
  if [[ -n "${tail_pid:-}" ]]; then
    kill "${tail_pid}" 2>/dev/null || true
  fi
}

trap cleanup INT TERM EXIT

fvm dart run custom_lint "$@" >"$log_file" 2>&1 &
lint_pid=$!
start_epoch="$(date +%s)"

tail -n +1 -f "$log_file" &
tail_pid=$!

while kill -0 "$lint_pid" 2>/dev/null; do
  elapsed="$(( $(date +%s) - start_epoch ))"
  echo "[custom-lint] Running... ${elapsed}s elapsed (waiting for analyzer output)"
  sleep 15
done

wait "$lint_pid"
lint_status=$?

kill "$tail_pid" 2>/dev/null || true
wait "$tail_pid" 2>/dev/null || true

trap - INT TERM EXIT

echo "[custom-lint] Exit status: $lint_status"
echo "[custom-lint] Full log saved at: $log_file"
exit "$lint_status"
