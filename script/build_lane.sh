#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./script/build_lane.sh [lane] <target> [flutter build args...]

Args:
  lane      Optional. dev|stage|main. When omitted, resolves from current branch:
            - main  -> main
            - stage -> stage
            - any other branch -> dev
  target    Build target supported by this helper:
            - apk
            - appbundle
            - web

Examples:
  ./script/build_lane.sh apk --debug --flavor <flavor> --dart-define=FLAVOR=<flavor>
  ./script/build_lane.sh stage apk --release --flavor <flavor>
  ./script/build_lane.sh main appbundle --release --flavor <flavor>

Notes:
  - config/defines/local.override.json is applied only when the resolved lane is dev.
  - The script validates the effective bootstrap origin before building.
  - Android flavor builds validate the committed public flavor file before building.
  - Android release/appbundle builds validate either the local signing file + keystore
    or the official Codemagic Android signing environment variables.
  - The script validates the expected build artifact after the build completes.
EOF
}

log_info() {
  echo "[build_lane] $*"
}

log_error() {
  echo "[build_lane] ERROR: $*" >&2
}

is_lane_name() {
  case "${1:-}" in
    dev|stage|main) return 0 ;;
    *) return 1 ;;
  esac
}

resolve_lane_from_branch() {
  local branch_name="${1:-}"
  case "$branch_name" in
    main)
      printf 'main'
      ;;
    stage)
      printf 'stage'
      ;;
    *)
      printf 'dev'
      ;;
  esac
}

find_flutter_app_dir() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "${dir}/pubspec.yaml" && -d "${dir}/lib" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

read_json_key() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PY'
import json
import sys
path, key = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as handle:
    payload = json.load(handle)
value = payload.get(key, '')
if value is None:
    value = ''
print(value)
PY
}

resolve_effective_origin() {
  local lane_file="$1"
  local local_override_file="$2"
  local lane="$3"

  local source_file="$lane_file"
  local source_key=""
  local source_value=""

  if [[ "$lane" == "dev" && -f "$local_override_file" ]]; then
    local override_bootstrap override_landlord
    override_bootstrap="$(read_json_key "$local_override_file" "BOOTSTRAP_BASE_URL")"
    override_landlord="$(read_json_key "$local_override_file" "LANDLORD_DOMAIN")"
    if [[ -n "$override_bootstrap" ]]; then
      source_file="$local_override_file"
      source_key="BOOTSTRAP_BASE_URL"
      source_value="$override_bootstrap"
    elif [[ -n "$override_landlord" ]]; then
      source_file="$local_override_file"
      source_key="LANDLORD_DOMAIN"
      source_value="$override_landlord"
    fi
  fi

  if [[ -z "$source_key" ]]; then
    local lane_bootstrap lane_landlord
    lane_bootstrap="$(read_json_key "$lane_file" "BOOTSTRAP_BASE_URL")"
    lane_landlord="$(read_json_key "$lane_file" "LANDLORD_DOMAIN")"
    if [[ -n "$lane_bootstrap" ]]; then
      source_key="BOOTSTRAP_BASE_URL"
      source_value="$lane_bootstrap"
    elif [[ -n "$lane_landlord" ]]; then
      source_key="LANDLORD_DOMAIN"
      source_value="$lane_landlord"
    fi
  fi

  if [[ -z "$source_key" || -z "$source_value" ]]; then
    local scope_message="${lane_file}"
    if [[ "$lane" == "dev" && -f "$local_override_file" ]]; then
      scope_message="${scope_message} or ${local_override_file}"
    fi
    log_error "missing BOOTSTRAP_BASE_URL/LANDLORD_DOMAIN in ${scope_message}"
    exit 1
  fi

  printf '%s|%s|%s\n' "$source_file" "$source_key" "$source_value"
}

validate_origin_shape() {
  local raw="$1"
  python3 - "$raw" <<'PY'
import sys
from urllib.parse import urlparse

raw = sys.argv[1]
parsed = urlparse(raw)
if parsed.scheme not in ('http', 'https'):
    raise SystemExit(1)
if not parsed.netloc:
    raise SystemExit(1)
if parsed.path not in ('', '/'):
    raise SystemExit(1)
if parsed.params or parsed.query or parsed.fragment:
    raise SystemExit(1)
PY
}

validate_target_supported() {
  case "${1:-}" in
    apk|appbundle|web) return 0 ;;
    *)
      log_error "unsupported build target '${1:-}'. Supported targets: apk, appbundle, web."
      exit 1
      ;;
  esac
}

extract_flutter_flavor() {
  local args=("$@")
  local idx=0
  while [[ $idx -lt ${#args[@]} ]]; do
    case "${args[$idx]}" in
      --flavor)
        idx=$((idx + 1))
        if [[ $idx -ge ${#args[@]} ]]; then
          log_error "missing value for --flavor"
          exit 1
        fi
        printf '%s\n' "${args[$idx]}"
        return 0
        ;;
      --flavor=*)
        printf '%s\n' "${args[$idx]#*=}"
        return 0
        ;;
    esac
    idx=$((idx + 1))
  done

  return 1
}

resolve_android_build_mode() {
  local target="$1"
  shift
  local args=("$@")

  for arg in "${args[@]}"; do
    case "$arg" in
      --debug) printf 'debug\n'; return 0 ;;
      --profile) printf 'profile\n'; return 0 ;;
      --release) printf 'release\n'; return 0 ;;
    esac
  done

  case "$target" in
    apk|appbundle) printf 'release\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

validate_android_flavor_contract() {
  local flutter_app_dir="$1"
  local flavor="$2"
  local build_mode="$3"

  local public_file="${flutter_app_dir}/android/flavors/${flavor}.public.properties"
  local signing_file="${flutter_app_dir}/android/keystores/${flavor}.signing.properties"
  local keystore_file="${flutter_app_dir}/android/keystores/${flavor}.jks"

  if [[ ! -f "$public_file" ]]; then
    log_error "missing committed public flavor properties: ${public_file}"
    exit 1
  fi

  grep -q '^applicationId=' "$public_file" || {
    log_error "${public_file} must declare applicationId"
    exit 1
  }
  grep -q '^appLinkHosts=' "$public_file" || {
    log_error "${public_file} must declare appLinkHosts"
    exit 1
  }

  log_info "validated Android public flavor contract: ${public_file}"

  if [[ "$build_mode" != "release" ]]; then
    return 0
  fi

  if [[ -f "$signing_file" ]]; then
    if [[ ! -f "$keystore_file" ]]; then
      log_error "missing Android keystore for release flavor ${flavor}: ${keystore_file}"
      exit 1
    fi

    log_info "validated Android release signing inputs: ${signing_file} and ${keystore_file}"
    return 0
  fi

  local cm_keystore_path="${CM_KEYSTORE_PATH:-}"
  local cm_keystore_password="${CM_KEYSTORE_PASSWORD:-}"
  local cm_key_alias="${CM_KEY_ALIAS:-}"
  local cm_key_password="${CM_KEY_PASSWORD:-}"

  if [[ -n "$cm_keystore_path" || -n "$cm_keystore_password" || -n "$cm_key_alias" || -n "$cm_key_password" ]]; then
    local missing_envs=()
    [[ -n "$cm_keystore_path" ]] || missing_envs+=("CM_KEYSTORE_PATH")
    [[ -n "$cm_keystore_password" ]] || missing_envs+=("CM_KEYSTORE_PASSWORD")
    [[ -n "$cm_key_alias" ]] || missing_envs+=("CM_KEY_ALIAS")
    [[ -n "$cm_key_password" ]] || missing_envs+=("CM_KEY_PASSWORD")

    if [[ ${#missing_envs[@]} -gt 0 ]]; then
      log_error "incomplete Codemagic Android signing environment for release flavor ${flavor}: missing ${missing_envs[*]}"
      exit 1
    fi

    if [[ ! -f "$cm_keystore_path" ]]; then
      log_error "missing Codemagic Android keystore for release flavor ${flavor}: ${cm_keystore_path}"
      exit 1
    fi

    log_info "validated Codemagic Android release signing inputs: ${cm_keystore_path} via CM_KEYSTORE_PATH"
    return 0
  fi

  log_error "missing Android signing properties for release flavor ${flavor}: ${signing_file}. Alternatively, provide Codemagic signing environment variables CM_KEYSTORE_PATH, CM_KEYSTORE_PASSWORD, CM_KEY_ALIAS, and CM_KEY_PASSWORD."
  exit 1
}

extract_web_output_dir() {
  local flutter_app_dir="$1"
  shift

  local args=("$@")
  local output_dir="${flutter_app_dir}/build/web"
  local idx=0
  while [[ $idx -lt ${#args[@]} ]]; do
    case "${args[$idx]}" in
      -o|--output)
        idx=$((idx + 1))
        if [[ $idx -ge ${#args[@]} ]]; then
          log_error "missing value for ${args[$((idx - 1))]}"
          exit 1
        fi
        output_dir="${args[$idx]}"
        ;;
      --output=*)
        output_dir="${args[$idx]#*=}"
        ;;
    esac
    idx=$((idx + 1))
  done

  if [[ "$output_dir" != /* ]]; then
    output_dir="${flutter_app_dir}/${output_dir}"
  fi

  printf '%s\n' "$output_dir"
}

find_newest_artifact_after() {
  local search_root="$1"
  local pattern="$2"
  local start_epoch="$3"

  python3 - "$search_root" "$pattern" "$start_epoch" <<'PY'
import fnmatch
import os
import sys

root, pattern, start_epoch = sys.argv[1], sys.argv[2], float(sys.argv[3])
matches = []
for current_root, _, files in os.walk(root):
    for name in files:
        if fnmatch.fnmatch(name, pattern):
            path = os.path.join(current_root, name)
            try:
                mtime = os.path.getmtime(path)
            except FileNotFoundError:
                continue
            if mtime >= start_epoch:
                matches.append((mtime, path))

if not matches:
    raise SystemExit(1)

matches.sort(reverse=True)
print(matches[0][1])
PY
}

validate_built_artifact() {
  local flutter_app_dir="$1"
  local target="$2"
  local start_epoch="$3"
  shift 3
  local extra_args=("$@")

  case "$target" in
    apk)
      local artifact
      artifact="$(find_newest_artifact_after "${flutter_app_dir}/build/app/outputs/flutter-apk" "*.apk" "$start_epoch")" || {
        log_error "apk build completed but no new APK artifact was found under build/app/outputs/flutter-apk."
        exit 1
      }
      log_info "validated APK artifact: ${artifact}"
      ;;
    appbundle)
      local artifact
      artifact="$(find_newest_artifact_after "${flutter_app_dir}/build/app/outputs/bundle" "*.aab" "$start_epoch")" || {
        log_error "appbundle build completed but no new AAB artifact was found under build/app/outputs/bundle."
        exit 1
      }
      log_info "validated app bundle artifact: ${artifact}"
      ;;
    web)
      local output_dir index_path
      output_dir="$(extract_web_output_dir "$flutter_app_dir" "${extra_args[@]}")"
      index_path="${output_dir}/index.html"
      if [[ ! -f "$index_path" ]]; then
        log_error "web build completed but ${index_path} is missing."
        exit 1
      fi
      local modified_epoch
      modified_epoch="$(python3 - "$index_path" <<'PY'
import os
import sys
print(os.path.getmtime(sys.argv[1]))
PY
)"
      if ! python3 - "$modified_epoch" "$start_epoch" <<'PY'
import sys
modified = float(sys.argv[1])
started = float(sys.argv[2])
raise SystemExit(0 if modified >= started else 1)
PY
      then
        log_error "web build completed but ${index_path} was not updated by this run."
        exit 1
      fi
      log_info "validated web artifact: ${index_path}"
      ;;
  esac
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

FLUTTER_APP_DIR="$(find_flutter_app_dir "$(pwd)" || true)"
if [[ -z "${FLUTTER_APP_DIR}" ]]; then
  log_error "run this script from the flutter-app workspace or one of its subdirectories."
  exit 1
fi

cd "$FLUTTER_APP_DIR"

CURRENT_BRANCH="$(git branch --show-current 2>/dev/null || true)"
LANE=""

if is_lane_name "${1:-}"; then
  LANE="$1"
  shift
else
  LANE="$(resolve_lane_from_branch "$CURRENT_BRANCH")"
fi

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  usage >&2
  exit 1
fi
shift

validate_target_supported "$TARGET"

LANE_FILE="${FLUTTER_APP_DIR}/config/defines/${LANE}.json"
LOCAL_OVERRIDE_FILE="${FLUTTER_APP_DIR}/config/defines/local.override.json"

if [[ ! -f "$LANE_FILE" ]]; then
  log_error "lane define file not found: ${LANE_FILE}"
  exit 1
fi

IFS='|' read -r ORIGIN_FILE ORIGIN_KEY ORIGIN_VALUE < <(
  resolve_effective_origin "$LANE_FILE" "$LOCAL_OVERRIDE_FILE" "$LANE"
)

if ! validate_origin_shape "$ORIGIN_VALUE"; then
  log_error "invalid ${ORIGIN_KEY} origin: ${ORIGIN_VALUE}"
  exit 1
fi

BUILD_CMD=(
  fvm flutter build
  "$TARGET"
  "$@"
  --dart-define-from-file="$LANE_FILE"
)

if [[ "$TARGET" == "apk" || "$TARGET" == "appbundle" ]]; then
  if FLAVOR="$(extract_flutter_flavor "$@")"; then
    BUILD_MODE="$(resolve_android_build_mode "$TARGET" "$@")"
    validate_android_flavor_contract "$FLUTTER_APP_DIR" "$FLAVOR" "$BUILD_MODE"
  fi
fi

if [[ "$LANE" == "dev" && -f "$LOCAL_OVERRIDE_FILE" ]]; then
  BUILD_CMD+=(--dart-define-from-file="$LOCAL_OVERRIDE_FILE")
fi

START_EPOCH="$(python3 - <<'PY'
import time
print(time.time())
PY
)"

log_info "resolved lane: ${LANE}"
log_info "current branch: ${CURRENT_BRANCH:-<detached-or-unavailable>}"
log_info "effective bootstrap origin: ${ORIGIN_VALUE} (${ORIGIN_KEY} from ${ORIGIN_FILE})"
log_info "running: ${BUILD_CMD[*]}"

"${BUILD_CMD[@]}"

validate_built_artifact "$FLUTTER_APP_DIR" "$TARGET" "$START_EPOCH" "$@"
