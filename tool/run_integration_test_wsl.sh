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

if [[ ! -f "$define_file" ]]; then
  echo "ERROR: define file not found: $define_file" >&2
  exit 1
fi

if [[ "$#" -eq 0 ]]; then
  set -- integration_test
fi

prepare_device() {
  if ! command -v "$adb_bin" >/dev/null 2>&1; then
    echo "WARN: adb not found in PATH; skipping pre-clean."
    return
  fi

  "$adb_bin" connect "$device" >/dev/null 2>&1 || true
  "$adb_bin" -s "$device" wait-for-device >/dev/null 2>&1 || true

  if [[ -n "$app_id" ]]; then
    # Best-effort cleanup: prevents stale app state/uninstall glitches from
    # aborting long integration suites.
    "$adb_bin" -s "$device" shell pm clear "$app_id" >/dev/null 2>&1 || true
    "$adb_bin" -s "$device" uninstall "$app_id" >/dev/null 2>&1 || true
    "$adb_bin" -s "$device" shell pm uninstall --user 0 "$app_id" >/dev/null 2>&1 || true

    # Some devices return DELETE_FAILED_INTERNAL_ERROR when uninstalling an
    # app that is absent. Seeding an installed APK (when available) makes the
    # uninstall step deterministic for Flutter tooling.
    local seed_apk="build/app/outputs/flutter-apk/app-${flavor}-debug.apk"
    if [[ -f "$seed_apk" ]]; then
      "$adb_bin" -s "$device" install -r "$seed_apk" >/dev/null 2>&1 || true
    fi
  fi
}

prepare_gradle() {
  if [[ -x "./android/gradlew" ]]; then
    (cd android && ./gradlew --stop >/dev/null 2>&1) || true
  fi
}

ensure_device_visible() {
  if ! command -v "$adb_bin" >/dev/null 2>&1; then
    return 0
  fi

  local attempt=1
  while [[ "$attempt" -le 8 ]]; do
    "$adb_bin" connect "$device" >/dev/null 2>&1 || true
    "$adb_bin" -s "$device" shell input keyevent 224 >/dev/null 2>&1 || true
    "$adb_bin" -s "$device" shell wm dismiss-keyguard >/dev/null 2>&1 || true
    "$adb_bin" -s "$device" shell input keyevent 82 >/dev/null 2>&1 || true
    if [[ "$("$adb_bin" -s "$device" get-state 2>/dev/null || true)" == "device" ]]; then
      if fvm flutter devices --device-timeout "$flutter_device_timeout" 2>/dev/null | grep -Fq "$device"; then
        return 0
      fi

      # Some WSL + ADB-over-TCP sessions intermittently miss the serial in
      # `flutter devices` immediately after app cleanup. If ADB can execute
      # shell commands, continue and let Flutter test own the final validation.
      if "$adb_bin" -s "$device" shell true >/dev/null 2>&1; then
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
  -d "$device"
  --timeout="$test_timeout"
  --flavor "$flavor"
  --dart-define-from-file="$define_file"
)

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

prepare_gradle
prepare_device
ensure_device_visible
"${cmd[@]}"
