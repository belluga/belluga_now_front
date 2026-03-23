#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

define_file="${INTEGRATION_DEFINE_FILE:-config/defines/integration.tenant.json}"
device="${ADB_DEVICE:-192.168.15.5:5555}"
flavor="${FLUTTER_INTEGRATION_FLAVOR:-belluga}"
adb_bin="${ADB_BIN:-adb}"
app_id="${ADB_APP_ID:-com.boora.app}"
test_timeout="${FLUTTER_INTEGRATION_TIMEOUT:-25m}"
ignore_timeouts="${FLUTTER_INTEGRATION_IGNORE_TIMEOUTS:-false}"
flutter_device_timeout="${FLUTTER_DEVICE_DISCOVERY_TIMEOUT:-20}"
adb_cmd_timeout_seconds="${ADB_COMMAND_TIMEOUT_SECONDS:-8}"
runner_timeout_seconds="${FLUTTER_INTEGRATION_RUN_TIMEOUT_SECONDS:-0}"
use_dds="${FLUTTER_INTEGRATION_USE_DDS:-false}"
disable_push="${FLUTTER_INTEGRATION_DISABLE_PUSH:-true}"
reporter="${FLUTTER_INTEGRATION_REPORTER:-expanded}"
skip_app_reset="${FLUTTER_INTEGRATION_SKIP_APP_RESET:-false}"
purge_flutter_build_cache_enabled="${FLUTTER_INTEGRATION_PURGE_FLUTTER_BUILD_CACHE:-true}"

if [[ ! -f "$define_file" ]]; then
  echo "ERROR: define file not found: $define_file" >&2
  exit 1
fi

if [[ "$#" -eq 0 ]]; then
  set -- integration_test
fi

run_adb() {
  if ! command -v "$adb_bin" >/dev/null 2>&1; then
    return 127
  fi

  if command -v timeout >/dev/null 2>&1; then
    timeout "${adb_cmd_timeout_seconds}s" "$adb_bin" "$@"
    return $?
  fi

  "$adb_bin" "$@"
}

prepare_device() {
  if ! command -v "$adb_bin" >/dev/null 2>&1; then
    echo "WARN: adb not found in PATH; skipping pre-clean."
    return
  fi

  run_adb connect "$device" >/dev/null 2>&1 || true
  run_adb -s "$device" wait-for-device >/dev/null 2>&1 || true

  if [[ -n "$app_id" ]] && [[ "$skip_app_reset" != "true" ]]; then
    # Best-effort cleanup: prevents stale app state/uninstall glitches from
    # aborting long integration suites.
    run_adb -s "$device" shell pm clear "$app_id" >/dev/null 2>&1 || true
    run_adb -s "$device" uninstall "$app_id" >/dev/null 2>&1 || true
    run_adb -s "$device" shell pm uninstall --user 0 "$app_id" >/dev/null 2>&1 || true

    # Some devices return DELETE_FAILED_INTERNAL_ERROR when uninstalling an
    # app that is absent. Seeding an installed APK (when available) makes the
    # uninstall step deterministic for Flutter tooling.
    local seed_apk="build/app/outputs/flutter-apk/app-${flavor}-debug.apk"
    if [[ -f "$seed_apk" ]]; then
      run_adb -s "$device" install -r "$seed_apk" >/dev/null 2>&1 || true
    fi
  elif [[ -n "$app_id" ]]; then
    echo "INFO: skipping app reset cleanup before integration run (FLUTTER_INTEGRATION_SKIP_APP_RESET=true)."
  fi
}

prepare_gradle() {
  if [[ -x "./android/gradlew" ]]; then
    (cd android && ./gradlew --stop >/dev/null 2>&1) || true
  fi
}

purge_flutter_build_cache_dirs() {
  if [[ "$purge_flutter_build_cache_enabled" != "true" ]]; then
    return
  fi

  local flutter_build_cache_dir=".dart_tool/flutter_build"
  local flutter_build_output_dir="build"

  if [[ -d "$flutter_build_cache_dir" ]]; then
    echo "INFO: purging Flutter build cache directory: $flutter_build_cache_dir"
    rm -rf "$flutter_build_cache_dir"
  fi

  if [[ -d "$flutter_build_output_dir" ]]; then
    echo "INFO: purging Flutter build output directory: $flutter_build_output_dir"
    rm -rf "$flutter_build_output_dir"
  fi
}

rotate_artifact() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return 0
  fi

  local ts
  ts="$(date +%s)"
  mv "$path" "${path}.bak.${ts}" >/dev/null 2>&1 || true
}

apk_paths() {
  printf '%s\n' \
    "build/app/outputs/apk/${flavor}/debug/app-${flavor}-debug.apk" \
    "build/app/outputs/flutter-apk/app-${flavor}-debug.apk"
}

sanitize_apk_outputs() {
  if ! command -v zipinfo >/dev/null 2>&1; then
    return 0
  fi

  while IFS= read -r apk; do
    if [[ ! -f "$apk" ]]; then
      continue
    fi

    if ! zipinfo -t "$apk" >/dev/null 2>&1; then
      echo "WARN: Detected corrupt APK artifact; rotating before run: $apk"
      rotate_artifact "$apk"
    fi
  done < <(apk_paths)
}

has_corrupt_apk_output() {
  if ! command -v zipinfo >/dev/null 2>&1; then
    return 1
  fi

  while IFS= read -r apk; do
    if [[ -f "$apk" ]] && ! zipinfo -t "$apk" >/dev/null 2>&1; then
      echo "WARN: APK integrity check failed after run: $apk"
      return 0
    fi
  done < <(apk_paths)

  return 1
}

run_flutter_tests() {
  if [[ "$runner_timeout_seconds" =~ ^[0-9]+$ ]] && [[ "$runner_timeout_seconds" -gt 0 ]]; then
    timeout "${runner_timeout_seconds}s" "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
}

ensure_device_visible() {
  if ! command -v "$adb_bin" >/dev/null 2>&1; then
    return 0
  fi

  local attempt=1
  while [[ "$attempt" -le 8 ]]; do
    run_adb connect "$device" >/dev/null 2>&1 || true
    run_adb -s "$device" shell input keyevent 224 >/dev/null 2>&1 || true
    run_adb -s "$device" shell wm dismiss-keyguard >/dev/null 2>&1 || true
    run_adb -s "$device" shell input keyevent 82 >/dev/null 2>&1 || true
    if [[ "$(run_adb -s "$device" get-state 2>/dev/null || true)" == "device" ]]; then
      if fvm flutter devices --device-timeout "$flutter_device_timeout" 2>/dev/null | grep -Fq "$device"; then
        return 0
      fi

      # Some WSL + ADB-over-TCP sessions intermittently miss the serial in
      # `flutter devices` immediately after app cleanup. If ADB can execute
      # shell commands, continue and let Flutter test own the final validation.
      if run_adb -s "$device" shell true >/dev/null 2>&1; then
        echo "WARN: Flutter device discovery did not list '$device' yet; proceeding with ADB-healthy device."
        return 0
      fi
    fi
    sleep 3
    attempt=$((attempt + 1))
  done

  echo "ERROR: target device '$device' is not reachable via ADB." >&2
  return 1
}

cmd=(
  fvm flutter test
  "$@"
  -r "$reporter"
  -d "$device"
  --timeout="$test_timeout"
  --flavor "$flavor"
  --dart-define-from-file="$define_file"
)

if [[ "$use_dds" == "true" ]]; then
  cmd+=(--dds)
else
  cmd+=(--no-dds)
fi

if [[ "$disable_push" == "true" ]]; then
  cmd+=(--dart-define=DISABLE_PUSH=true)
fi

if [[ "$ignore_timeouts" == "true" ]]; then
  cmd+=(--ignore-timeouts)
fi

echo "Running integration tests in WSL-aware mode"
echo "  Device: $device"
echo "  Flavor: $flavor"
echo "  Defines: $define_file"
echo "  App ID cleanup: $app_id"
echo "  Test timeout: $test_timeout"
echo "  Ignore timeouts: $ignore_timeouts"
echo "  Use DDS: $use_dds"
echo "  Disable push during tests: $disable_push"
echo "  Reporter: $reporter"
echo "  Skip app reset: $skip_app_reset"
echo "  Purge Flutter build cache: $purge_flutter_build_cache_enabled"
echo "  ADB command timeout (s): $adb_cmd_timeout_seconds"
echo "  Runner timeout (s, 0=disabled): $runner_timeout_seconds"

prepare_gradle
purge_flutter_build_cache_dirs
prepare_device
ensure_device_visible
sanitize_apk_outputs

set +e
run_flutter_tests
run_status=$?
set -e

if [[ "$run_status" -ne 0 ]] && has_corrupt_apk_output; then
  echo "WARN: Integration run failed with corrupted APK artifact. Retrying once after artifact reset."
  prepare_gradle
  sanitize_apk_outputs

  set +e
  run_flutter_tests
  run_status=$?
  set -e
fi

exit "$run_status"
