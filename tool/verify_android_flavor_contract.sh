#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./tool/verify_android_flavor_contract.sh [--flavor <flavor>]

Validates the Android public-vs-secret flavor contract by checking:
- required public and recovery files are versioned in git;
- required public keys exist in the committed public flavor file;
- Gradle fails closed for:
  * missing public flavor file
  * missing applicationId
  * missing appLinkHosts
  * missing release signing properties file
  * missing release keystore file
  * incomplete Codemagic signing environment
  * missing Codemagic keystore file

This script runs the fail-closed mutations inside a temporary sandbox copy of the
Flutter checkout so the principal working tree stays untouched.
EOF
}

log() {
  echo "[verify_android_flavor_contract] $*"
}

fail() {
  echo "[verify_android_flavor_contract] ERROR: $*" >&2
  exit 1
}

require_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain: $needle"
  fi
}

file_sha256() {
  sha256sum "$1" | awk '{print $1}'
}

read_property_file_value() {
  local file="$1"
  local key="$2"

  awk -F= -v key="$key" '
    $1 == key {
      sub(/^[^=]*=/, "")
      print
      exit
    }
  ' "$file"
}

run_expect_failure() {
  local expected="$1"
  shift
  local output
  set +e
  output="$("$@" 2>&1)"
  local status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    echo "$output"
    fail "command unexpectedly succeeded: $*"
  fi
  require_contains "$output" "$expected"
  log "observed expected failure: $expected"
}

run_expect_success() {
  local output
  set +e
  output="$("$@" 2>&1)"
  local status=$?
  set -e
  if [[ $status -ne 0 ]]; then
    echo "$output"
    fail "command unexpectedly failed: $*"
  fi
  log "observed expected success: $*"
}

flavor="guarappari"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --flavor)
      shift
      [[ $# -gt 0 ]] || fail "missing value for --flavor"
      flavor="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
  shift
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

public_file="android/flavors/${flavor}.public.properties"
signing_file="android/keystores/${flavor}.signing.properties"
keystore_file="android/keystores/${flavor}.jks"
public_example_file="android/flavors/tenant.public.properties.example"
signing_example_file="android/keystores/tenant.signing.properties.example"

task_flavor="${flavor^}"
debug_task="app:assemble${task_flavor}Debug"
release_task="app:bundle${task_flavor}Release"

for path in \
  "$public_file" \
  "$public_example_file" \
  "android/keystores/README.recovery.txt" \
  "$signing_example_file"
do
  git ls-files --error-unmatch "$path" >/dev/null
done
log "tracked file contract looks correct for ${flavor}"

grep -q '^applicationId=' "$public_file" || fail "${public_file} must declare applicationId"
grep -q '^appLinkHosts=' "$public_file" || fail "${public_file} must declare appLinkHosts"
log "public property contract looks correct for ${flavor}"

[[ -f "$signing_file" ]] || fail "missing local signing file for release verification: ${signing_file}"
[[ -f "$keystore_file" ]] || fail "missing local keystore for release verification: ${keystore_file}"

command -v rsync >/dev/null 2>&1 || fail "rsync is required for isolated Android flavor contract verification"

real_public_sha_before="$(file_sha256 "$public_file")"
real_signing_sha_before="$(file_sha256 "$signing_file")"
real_keystore_sha_before="$(file_sha256 "$keystore_file")"

sandbox_dir="$(mktemp -d)"
workspace_dir="${sandbox_dir}/workspace"
backup_dir="${sandbox_dir}/backup"
original_public_present=0
original_signing_present=0
original_keystore_present=0

cleanup() {
  rm -rf "$sandbox_dir"
}
trap cleanup EXIT

mkdir -p "$workspace_dir" "$backup_dir"
rsync -a \
  --exclude '.git' \
  --exclude 'build' \
  --exclude '.dart_tool' \
  --exclude '.idea' \
  --exclude '.fvm/flutter_sdk' \
  "$repo_root/" "$workspace_dir/"

workspace_public_file="${workspace_dir}/${public_file}"
workspace_signing_file="${workspace_dir}/${signing_file}"
workspace_keystore_file="${workspace_dir}/${keystore_file}"

if [[ -f "$workspace_public_file" ]]; then
  cp "$workspace_public_file" "${backup_dir}/public.properties"
  original_public_present=1
fi
if [[ -f "$workspace_signing_file" ]]; then
  cp "$workspace_signing_file" "${backup_dir}/signing.properties"
  original_signing_present=1
fi
if [[ -f "$workspace_keystore_file" ]]; then
  cp "$workspace_keystore_file" "${backup_dir}/flavor.jks"
  original_keystore_present=1
fi

restore_file() {
  local original_present="$1"
  local backup_path="$2"
  local target_path="$3"

  if [[ "$original_present" -eq 1 && -f "$backup_path" ]]; then
    mkdir -p "$(dirname "$target_path")"
    cp "$backup_path" "$target_path"
  fi
}

restore_public_file() {
  restore_file "$original_public_present" "${backup_dir}/public.properties" "$workspace_public_file"
}

restore_signing_file() {
  restore_file "$original_signing_present" "${backup_dir}/signing.properties" "$workspace_signing_file"
}

restore_keystore_file() {
  restore_file "$original_keystore_present" "${backup_dir}/flavor.jks" "$workspace_keystore_file"
}

run_gradle() {
  (
    cd "$workspace_dir"
    env \
      -u CM_KEYSTORE_PATH \
      -u CM_KEYSTORE_PASSWORD \
      -u CM_KEY_ALIAS \
      -u CM_KEY_PASSWORD \
      ./android/gradlew --no-daemon -p android "$@" --dry-run
  )
}

run_gradle_with_codemagic_signing_env() {
  local key_alias
  local key_password
  local store_password

  key_alias="$(read_property_file_value "${backup_dir}/signing.properties" "keyAlias")"
  key_password="$(read_property_file_value "${backup_dir}/signing.properties" "keyPassword")"
  store_password="$(read_property_file_value "${backup_dir}/signing.properties" "storePassword")"

  (
    cd "$workspace_dir"
    env \
      CM_KEYSTORE_PATH="$workspace_keystore_file" \
      CM_KEYSTORE_PASSWORD="$store_password" \
      CM_KEY_ALIAS="$key_alias" \
      CM_KEY_PASSWORD="$key_password" \
      ./android/gradlew --no-daemon -p android "$@" --dry-run
  )
}

run_gradle_with_incomplete_codemagic_env() {
  local store_password
  store_password="$(read_property_file_value "${backup_dir}/signing.properties" "storePassword")"

  (
    cd "$workspace_dir"
    env \
      CM_KEYSTORE_PATH="$workspace_keystore_file" \
      CM_KEYSTORE_PASSWORD="$store_password" \
      ./android/gradlew --no-daemon -p android "$@" --dry-run
  )
}

rm -f "$workspace_public_file"
run_expect_failure \
  "Missing committed public flavor properties for \`${flavor}\`" \
  run_gradle "$debug_task"
restore_public_file

perl -0pi -e 's/^applicationId=.*\n//m' "$workspace_public_file"
run_expect_failure \
  'Public flavor properties for `'"${flavor}"'` is missing required property `applicationId`.' \
  run_gradle "$debug_task"
restore_public_file

perl -0pi -e 's/^appLinkHosts=.*\n//m' "$workspace_public_file"
run_expect_failure \
  'Public flavor properties for `'"${flavor}"'` is missing required property `appLinkHosts`.' \
  run_gradle "$debug_task"
restore_public_file

rm -f "$workspace_signing_file"
run_expect_success run_gradle_with_codemagic_signing_env "$release_task"
run_expect_failure \
  "Incomplete Codemagic signing environment for release flavor \`${flavor}\`: missing CM_KEY_ALIAS, CM_KEY_PASSWORD." \
  run_gradle_with_incomplete_codemagic_env "$release_task"
run_expect_failure \
  "Missing signing properties for release flavor \`${flavor}\`" \
  run_gradle "$release_task"
restore_signing_file

rm -f "$workspace_keystore_file"
rm -f "$workspace_signing_file"
run_expect_failure \
  "Missing Codemagic keystore file for release flavor \`${flavor}\`" \
  run_gradle_with_codemagic_signing_env "$release_task"
restore_signing_file
run_expect_failure \
  "Missing keystore file for release flavor \`${flavor}\`" \
  run_gradle "$release_task"
restore_keystore_file

[[ -f "$workspace_public_file" ]] || fail "restore failed for ${workspace_public_file}"
[[ -f "$workspace_signing_file" ]] || fail "restore failed for ${workspace_signing_file}"
[[ -f "$workspace_keystore_file" ]] || fail "restore failed for ${workspace_keystore_file}"

[[ "$(file_sha256 "$public_file")" == "$real_public_sha_before" ]] || fail "principal checkout file changed during validation: ${public_file}"
[[ "$(file_sha256 "$signing_file")" == "$real_signing_sha_before" ]] || fail "principal checkout file changed during validation: ${signing_file}"
[[ "$(file_sha256 "$keystore_file")" == "$real_keystore_sha_before" ]] || fail "principal checkout file changed during validation: ${keystore_file}"

log "all Android flavor contract checks passed for ${flavor}"
