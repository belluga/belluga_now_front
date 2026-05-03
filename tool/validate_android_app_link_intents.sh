#!/usr/bin/env bash
set -euo pipefail

PACKAGE_NAME="${ANDROID_PACKAGE_NAME:-com.guarappari.app}"
ACTIVITY_NAME="${ANDROID_ACTIVITY_NAME:-com.belluga_now.MainActivity}"
MERGED_MANIFEST="${ANDROID_MERGED_MANIFEST:-build/app/intermediates/merged_manifests/guarappariDebug/processGuarappariDebugManifest/AndroidManifest.xml}"
NEGATIVE_HOST="${ANDROID_APP_LINK_NEGATIVE_HOST:-tenant.example.com}"
PATHS_RAW="${ANDROID_APP_LINK_PATHS:-/invite,/convites,/agenda,/agenda/evento,/mapa,/parceiro,/profile,/home,/}"
OPEN_APP_BASE_URL="${ANDROID_OPEN_APP_BASE_URL:-}"

if ! command -v adb >/dev/null 2>&1; then
  echo "ERROR: adb command not found." >&2
  exit 1
fi

resolve_device_serial() {
  if [[ -n "${ANDROID_SERIAL:-}" ]]; then
    printf '%s' "${ANDROID_SERIAL}"
    return 0
  fi

  mapfile -t devices < <(adb devices | awk 'NR > 1 && $2 == "device" {print $1}')
  if [[ "${#devices[@]}" -eq 1 ]]; then
    printf '%s' "${devices[0]}"
    return 0
  fi

  echo "ERROR: set ANDROID_SERIAL when zero or multiple adb devices are connected." >&2
  adb devices -l >&2
  exit 1
}

parse_manifest_hosts() {
  local manifest="$1"
  if [[ ! -f "${manifest}" ]]; then
    return 0
  fi

  if grep -q 'android:host="\*"' "${manifest}"; then
    echo "ERROR: merged manifest contains android:host=\"*\"." >&2
    exit 1
  fi

  sed -n 's/.*android:host="\([^"]*\)".*/\1/p' "${manifest}" \
    | grep -v '^\*$' \
    | sort -u
}

split_csv() {
  local raw="$1"
  tr ',;' '\n' <<< "${raw}" | awk '{$1=$1; print}' | sed '/^$/d'
}

query_activity() {
  local serial="$1"
  local url="$2"

  adb -s "${serial}" shell cmd package query-activities \
    --brief \
    -a android.intent.action.VIEW \
    -c android.intent.category.BROWSABLE \
    -d "${url}" \
    "${PACKAGE_NAME}" \
    < /dev/null \
    | tr -d '\r'
}

assert_resolves_to_app() {
  local serial="$1"
  local url="$2"
  local output

  output="$(query_activity "${serial}" "${url}")"
  if ! grep -Fq "${PACKAGE_NAME}/${ACTIVITY_NAME}" <<< "${output}"; then
    echo "ERROR: ${url} did not resolve to ${PACKAGE_NAME}/${ACTIVITY_NAME}." >&2
    echo "${output}" >&2
    exit 1
  fi

  echo "OK ${url} -> ${PACKAGE_NAME}/${ACTIVITY_NAME}"
}

assert_negative_host_is_absent() {
  local serial="$1"
  local output

  output="$(query_activity "${serial}" "https://${NEGATIVE_HOST}/parceiro/teste")"
  if grep -Fq "${PACKAGE_NAME}/${ACTIVITY_NAME}" <<< "${output}"; then
    echo "ERROR: absent host ${NEGATIVE_HOST} unexpectedly resolves to ${PACKAGE_NAME}/${ACTIVITY_NAME}." >&2
    echo "${output}" >&2
    exit 1
  fi

  echo "OK absent host ${NEGATIVE_HOST} has no app-link activity"
}

origin_from_url() {
  local url="$1"
  sed -E 's#^(https?://[^/]+).*$#\1#' <<< "${url}"
}

fetch_open_app_location() {
  local base_url="$1"
  local path="$2"
  local code="${3:-}"
  local endpoint="${base_url%/}/open-app"
  local response
  local curl_args=(
    -k
    -sS
    -D -
    -o /dev/null
    -G "${endpoint}"
    --data-urlencode "store_channel=web"
    --data-urlencode "platform_target=android"
    --data-urlencode "fallback=promotion"
    --data-urlencode "path=${path}"
  )

  if [[ -n "${code}" ]]; then
    curl_args+=(--data-urlencode "code=${code}")
  fi

  response="$(curl "${curl_args[@]}" < /dev/null)"
  if ! grep -Eq '^HTTP/[^ ]+[[:space:]]+30[1278]([[:space:]]|$)' <<< "${response}"; then
    echo "ERROR: ${endpoint} did not return an Android intent redirect." >&2
    echo "${response}" >&2
    exit 1
  fi

  awk '
    tolower($0) ~ /^location:/ {
      sub(/\r$/, "")
      sub(/^[^:]+:[[:space:]]*/, "")
      print
      exit
    }
  ' <<< "${response}"
}

intent_location_to_url() {
  local location="$1"
  local target="${location#intent://}"
  target="${target%%#Intent*}"

  local scheme="https"
  if [[ "${location}" =~ \;scheme=([^;]+)\; ]]; then
    scheme="${BASH_REMATCH[1]}"
  fi

  printf '%s://%s' "${scheme}" "${target}"
}

assert_android_intent_location() {
  local location="$1"
  if [[ "${location}" != intent://* ]]; then
    echo "ERROR: /open-app Location is not an Android intent:// URL." >&2
    echo "${location}" >&2
    exit 1
  fi

  if [[ "${location}" != *";scheme=https;"* ]]; then
    echo "ERROR: Android intent is missing scheme=https." >&2
    echo "${location}" >&2
    exit 1
  fi

  if [[ "${location}" != *";package=${PACKAGE_NAME};"* ]]; then
    echo "ERROR: Android intent is missing package=${PACKAGE_NAME}." >&2
    echo "${location}" >&2
    exit 1
  fi

  if [[ "${location}" != *";S.browser_fallback_url="* ]]; then
    echo "ERROR: Android intent is missing browser fallback URL." >&2
    echo "${location}" >&2
    exit 1
  fi
}

assert_open_app_case() {
  local serial="$1"
  local base_url="$2"
  local label="$3"
  local path="$4"
  local code="$5"
  local expected_path="$6"
  local origin
  local location
  local target_url
  local expected_url

  origin="$(origin_from_url "${base_url}")"
  location="$(fetch_open_app_location "${base_url}" "${path}" "${code}")"
  assert_android_intent_location "${location}"

  target_url="$(intent_location_to_url "${location}")"
  expected_url="${origin}${expected_path}"
  if [[ "${target_url}" != "${expected_url}" ]]; then
    echo "ERROR: /open-app ${label} target mismatch." >&2
    echo "Expected: ${expected_url}" >&2
    echo "Actual:   ${target_url}" >&2
    echo "${location}" >&2
    exit 1
  fi

  assert_resolves_to_app "${serial}" "${target_url}"
  echo "OK /open-app ${label} -> ${target_url}"
}

validate_open_app_redirects() {
  local serial="$1"
  local base_url="$2"

  if [[ -z "${base_url}" ]]; then
    echo "SKIP /open-app Android intent redirect validation; set ANDROID_OPEN_APP_BASE_URL to enable."
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl command not found; required when ANDROID_OPEN_APP_BASE_URL is set." >&2
    exit 1
  fi

  while IFS='|' read -r label path code expected_path; do
    [[ -z "${label}" ]] && continue
    assert_open_app_case \
      "${serial}" \
      "${base_url}" \
      "${label}" \
      "${path}" \
      "${code}" \
      "${expected_path}"
  done <<'CASES'
invite accept|/invite|PWINTENT123|/invite?code=PWINTENT123
attendance confirmation|/agenda/evento/show-rock?occurrence=occ-1||/agenda/evento/show-rock?occurrence=occ-1
account profile favorite|/parceiro/profile-slug||/parceiro/profile-slug
invite sharing|/convites/compartilhar||/convites/compartilhar
CASES
}

main() {
  local serial
  serial="$(resolve_device_serial)"

  local hosts_raw="${ANDROID_APP_LINK_HOSTS:-}"
  if [[ -z "${hosts_raw}" ]]; then
    hosts_raw="$(parse_manifest_hosts "${MERGED_MANIFEST}" | paste -sd ',' -)"
  fi

  if [[ -z "${hosts_raw}" ]]; then
    echo "ERROR: no app link hosts found. Set ANDROID_APP_LINK_HOSTS or build the APK first." >&2
    exit 1
  fi

  mapfile -t hosts < <(split_csv "${hosts_raw}")
  mapfile -t paths < <(split_csv "${PATHS_RAW}")

  for host in "${hosts[@]}"; do
    for path in "${paths[@]}"; do
      if [[ "${path}" == "/" ]]; then
        assert_resolves_to_app "${serial}" "https://${host}/"
      else
        assert_resolves_to_app "${serial}" "https://${host}${path}/teste"
      fi
    done
  done

  assert_negative_host_is_absent "${serial}"
  validate_open_app_redirects "${serial}" "${OPEN_APP_BASE_URL}"
}

main "$@"
