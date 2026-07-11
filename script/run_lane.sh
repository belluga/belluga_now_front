#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./script/run_lane.sh [lane] [flutter run args...]

Args:
  lane      Optional. dev|stage|main. When omitted, resolves from current branch:
            - main  -> main
            - stage -> stage
            - any other branch -> dev

Examples:
  ./script/run_lane.sh --flavor <flavor>
  ./script/run_lane.sh stage --debug --flavor <flavor>
  ./script/run_lane.sh main --release --flavor <flavor> -d <device-id>

Notes:
  - config/defines/local.override.json is applied only when the resolved lane is dev.
  - The script validates the effective bootstrap origin before running.
  - Device selection is delegated to `flutter run`. If `-d/--device-id` is omitted,
    Flutter uses its normal CLI resolution behavior.
EOF
}

log_info() {
  echo "[run_lane] $*"
}

log_error() {
  echo "[run_lane] ERROR: $*" >&2
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

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

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

RUN_CMD=(
  fvm flutter run
  "$@"
  --dart-define-from-file="$LANE_FILE"
)

if [[ "$LANE" == "dev" && -f "$LOCAL_OVERRIDE_FILE" ]]; then
  RUN_CMD+=(--dart-define-from-file="$LOCAL_OVERRIDE_FILE")
fi

log_info "resolved lane: ${LANE}"
log_info "current branch: ${CURRENT_BRANCH:-<detached-or-unavailable>}"
log_info "effective bootstrap origin: ${ORIGIN_VALUE} (${ORIGIN_KEY} from ${ORIGIN_FILE})"
log_info "running: ${RUN_CMD[*]}"

"${RUN_CMD[@]}"
