#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
fixture_dir="$repo_root/tool/belluga_analysis_plugin/test_fixtures/lint_matrix"
analysis_options_file="$fixture_dir/analysis_options.yaml"
plugin_path="$repo_root/tool/belluga_analysis_plugin"

timeout_seconds="${TIMEOUT_SECONDS:-300}"

if [[ ! -d "$fixture_dir" ]]; then
  echo "[validate_rule_matrix] fixture directory not found: $fixture_dir"
  exit 1
fi

echo "[validate_rule_matrix] synchronizing fixture package dependencies..."
(
  cd "$fixture_dir"
  fvm flutter pub get
)

analysis_backup="$(mktemp)"
output_file="$(mktemp)"
expected_codes_file="$(mktemp)"
found_codes_file="$(mktemp)"
positive_expectations_file="$(mktemp)"
negative_expectations_file="$(mktemp)"
cp "$analysis_options_file" "$analysis_backup"

temp_files=()
cleanup() {
  cp "$analysis_backup" "$analysis_options_file" || true
  rm -f "$analysis_backup" "$output_file" "$expected_codes_file" "$found_codes_file" "$positive_expectations_file" "$negative_expectations_file"
  for f in "${temp_files[@]}"; do
    rm -f "$f" || true
  done
}
trap cleanup EXIT

cat > "$analysis_options_file" <<YAML
plugins:
  belluga_analysis_plugin:
    path: $plugin_path
YAML

mkdir -p "$fixture_dir/integration_test"
mkdir -p "$fixture_dir/lib/application/observability"
mkdir -p "$fixture_dir/lib/infrastructure/repositories"
mkdir -p "$fixture_dir/lib/presentation/tenant_public/home/routes"
mkdir -p "$fixture_dir/lib/presentation/tenant_public/home/widgets"

integration_case="$fixture_dir/integration_test/anonymous_auth_identified_login_case_test.dart"
cat > "$integration_case" <<'DART'
const kAnonymousAuthOnlyContract = true;

void runAnonymousOnlyCase(AuthRepository authRepository) {
  // expect_lint: integration_anonymous_auth_identified_login_forbidden
  authRepository.loginWithEmailPassword('email', 'password');
}

class AuthRepository {
  void loginWithEmailPassword(String email, String password) {}
}
DART
temp_files+=("$integration_case")

raw_transport_case="$fixture_dir/lib/infrastructure/repositories/repository_raw_transport_typing_case.dart"
cat > "$raw_transport_case" <<'DART'
class RepositoryRawTransportTypingCase {
  RepositoryRawTransportTypingCase({required this.payload});

  // expect_lint: repository_raw_transport_typing_forbidden
  final Map<String, dynamic> payload;
}
DART
temp_files+=("$raw_transport_case")

catch_return_case="$fixture_dir/lib/infrastructure/repositories/repository_catch_return_fallback_case.dart"
cat > "$catch_return_case" <<'DART'
class RepositoryCatchReturnFallbackCase {
  Future<int> load() async {
    try {
      throw Exception('boom');
    } catch (_) {
      // expect_lint: repository_service_catch_return_fallback_forbidden
      return 0;
    }
  }
}
DART
temp_files+=("$catch_return_case")

sentry_case="$fixture_dir/lib/application/observability/sentry_unreported_debug_print_case.dart"
cat > "$sentry_case" <<'DART'
class SentryUnreportedDebugPrintCase {
  Future<int> loadSilently() async {
    try {
      throw Exception('boom');
    } catch (error) {
      // expect_lint: flutter_sentry_unreported_debug_print_catch_forbidden
      debugPrint('failed: $error');
      return 0;
    }
  }

  Future<int> loadReported() async {
    try {
      throw Exception('boom');
    } catch (error, stackTrace) {
      SentryErrorReporter.captureRecoverable(
        origin: 'fixture.reported',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('failed: $error');
      return 0;
    }
  }

  Future<int> loadExpectedControlFlow() async {
    try {
      throw Exception('optional platform metadata unavailable');
    } catch (error) {
      // expected_control_flow: optional metadata can be absent locally.
      debugPrint('metadata unavailable: $error');
      return 0;
    }
  }

  Future<int> loadPropagated() async {
    try {
      throw Exception('boom');
    } catch (error) {
      debugPrint('failed: $error');
      rethrow;
    }
  }
}

void debugPrint(String message) {}

class SentryErrorReporter {
  static void captureRecoverable({
    required String origin,
    required Object error,
    required StackTrace stackTrace,
  }) {}
}
DART
temp_files+=("$sentry_case")

route_case="$fixture_dir/lib/presentation/tenant_public/home/routes/route_required_non_url_args_case.dart"
cat > "$route_case" <<'DART'
@RoutePage()
class RouteRequiredNonUrlArgsCase {
  RouteRequiredNonUrlArgsCase({required this.id});

  // expect_lint: route_required_non_url_args_forbidden
  final String id;
}

class RoutePage {
  const RoutePage();
}
DART
temp_files+=("$route_case")

timezone_case="$fixture_dir/lib/presentation/tenant_public/home/widgets/timezone_conversion_case.dart"
cat > "$timezone_case" <<'DART'
class TimezoneConversionCase {
  DateTime normalize(DateTime input) {
    // expect_lint: timezone_service_direct_datetime_conversion_forbidden
    return input.toLocal();
  }
}
DART
temp_files+=("$timezone_case")

mapfile -t fixture_dart_files < <(
  find "$fixture_dir/lib" "$fixture_dir/integration_test" -type f -name '*.dart' |
    sed "s|^$fixture_dir/||" |
    sort
)

if [[ "${#fixture_dart_files[@]}" -eq 0 ]]; then
  echo "[validate_rule_matrix] no Dart files found under fixture"
  exit 1
fi

(
  while true; do
    echo "[validate_rule_matrix] $(date +%H:%M:%S) running analyze..."
    sleep 10
  done
) &
heartbeat_pid=$!

set +e
(
  cd "$fixture_dir"
  timeout "$timeout_seconds" fvm dart analyze --format machine "${fixture_dart_files[@]}"
) > "$output_file" 2>&1
analyze_status=$?
set -e

kill "$heartbeat_pid" >/dev/null 2>&1 || true
wait "$heartbeat_pid" 2>/dev/null || true

if [[ "$analyze_status" -eq 124 ]]; then
  echo "[validate_rule_matrix] timed out after ${timeout_seconds}s"
  sed -n '1,120p' "$output_file"
  exit 1
fi

if [[ "$analyze_status" -ne 0 && "$analyze_status" -ne 2 && "$analyze_status" -ne 3 ]]; then
  echo "[validate_rule_matrix] unexpected analyzer exit code: $analyze_status"
  sed -n '1,200p' "$output_file"
  exit "$analyze_status"
fi

if grep -Eiq "plugin.*crash|Failed to start plugin|Unhandled exception.*plugin" "$output_file"; then
  echo "[validate_rule_matrix] analyzer plugin runtime error detected"
  sed -n '1,200p' "$output_file"
  exit 1
fi

grep -RhoE --include='*.dart' 'expect_lint:[[:space:]]*[a-z0-9_,[:space:]]+' \
  "$fixture_dir/lib" "$fixture_dir/integration_test" |
  sed -E 's/.*expect_lint:[[:space:]]*//' |
  tr ',' '\n' |
  tr -d ' ' |
  sed '/^$/d' |
  sort -u > "$expected_codes_file"

(awk -F'|' '/^(INFO|WARNING|ERROR)\|/ {print tolower($3)}' "$output_file" || true) |
  tr -d ' ' |
  sed '/^$/d' |
  sort -u > "$found_codes_file"

missing_codes="$(comm -23 "$expected_codes_file" "$found_codes_file" || true)"

if [[ -n "$missing_codes" ]]; then
  echo "[validate_rule_matrix] missing expected lint codes:"
  echo "$missing_codes"
  echo "[validate_rule_matrix] analyzer output (first 200 lines):"
  sed -n '1,200p' "$output_file"
  exit 1
fi

while IFS=: read -r source_file source_line marker; do
  [[ -z "$source_file" ]] && continue
  codes="$(sed -E 's/.*expect_lint:[[:space:]]*//' <<<"$marker")"
  IFS=',' read -ra code_items <<<"$codes"
  for code in "${code_items[@]}"; do
    code="${code//[[:space:]]/}"
    [[ -z "$code" ]] && continue
    printf '%s\t%s\t%s\n' "$source_file" "$source_line" "$code" >> "$positive_expectations_file"
  done
done < <(grep -RIn --include='*.dart' 'expect_lint:' "$fixture_dir/lib" "$fixture_dir/integration_test")

if ! python3 - "$positive_expectations_file" "$output_file" <<'PY'
import os
import sys


def unmatched_expectations(expectations, diagnostics):
    candidates = []
    for expected_file, expected_line, expected_code in expectations:
        matching = [
            index
            for index, (diagnostic_file, diagnostic_line, diagnostic_code) in enumerate(diagnostics)
            if diagnostic_file == expected_file
            and diagnostic_code == expected_code
            and abs(diagnostic_line - expected_line) <= 3
        ]
        matching.sort(key=lambda index: abs(diagnostics[index][1] - expected_line))
        candidates.append(matching)

    diagnostic_owner = {}

    def assign(expectation_index, visited):
        for diagnostic_index in candidates[expectation_index]:
            if diagnostic_index in visited:
                continue
            visited.add(diagnostic_index)
            current_owner = diagnostic_owner.get(diagnostic_index)
            if current_owner is None or assign(current_owner, visited):
                diagnostic_owner[diagnostic_index] = expectation_index
                return True
        return False

    matched = set()
    for expectation_index in range(len(expectations)):
        if assign(expectation_index, set()):
            matched.add(expectation_index)
    return [
        expectation
        for index, expectation in enumerate(expectations)
        if index not in matched
    ]


synthetic_expectations = [('/fixture.dart', 17, 'same_code'), ('/fixture.dart', 20, 'same_code')]
synthetic_diagnostics = [('/fixture.dart', 18, 'same_code')]
assert len(unmatched_expectations(synthetic_expectations, synthetic_diagnostics)) == 1

expectations = []
with open(sys.argv[1], encoding='utf-8') as expectation_file:
    for line in expectation_file:
        source_file, source_line, code = line.rstrip('\n').split('\t')
        expectations.append((os.path.realpath(source_file), int(source_line), code.lower()))

diagnostics = []
with open(sys.argv[2], encoding='utf-8') as analyzer_output:
    for line in analyzer_output:
        fields = line.rstrip('\n').split('|')
        if len(fields) < 6 or fields[0] not in {'INFO', 'WARNING', 'ERROR'}:
            continue
        try:
            diagnostics.append((fields[3], int(fields[4]), fields[2].lower()))
        except ValueError:
            continue

missing = unmatched_expectations(expectations, diagnostics)
for source_file, source_line, code in missing:
    print(f'[validate_rule_matrix] missing unique expected lint {code} near {source_file}:{source_line}')
sys.exit(1 if missing else 0)
PY
then
  echo "[validate_rule_matrix] analyzer output (first 200 lines):"
  sed -n '1,200p' "$output_file"
  exit 1
fi

grep -RIn --include='*.dart' 'expect_no_lint:' \
  "$fixture_dir/lib" "$fixture_dir/integration_test" |
  sed -E 's#^(.+):([0-9]+):.*expect_no_lint:[[:space:]]*([a-z0-9_]+).*#\1\t\2\t\3#' \
  > "$negative_expectations_file"

negative_failures=0
while IFS=$'\t' read -r source_file source_line code; do
  [[ -z "$source_file" ]] && continue
  resolved_source_file="$(realpath "$source_file")"
  target_line="$((source_line + 1))"
  if grep -Fiq "|$code|$resolved_source_file|$target_line|" "$output_file"; then
    echo "[validate_rule_matrix] unexpected lint $code at $source_file:$target_line"
    negative_failures=1
  fi
done < "$negative_expectations_file"

if [[ "$negative_failures" -ne 0 ]]; then
  echo "[validate_rule_matrix] analyzer output (first 200 lines):"
  sed -n '1,200p' "$output_file"
  exit 1
fi

sentry_lint_count="$(
  awk -F'|' 'tolower($3) == "flutter_sentry_unreported_debug_print_catch_forbidden" {count++} END {print count + 0}' "$output_file"
)"
if [[ "$sentry_lint_count" -ne 1 ]]; then
  echo "[validate_rule_matrix] expected exactly one sentry debugPrint catch lint, found: $sentry_lint_count"
  echo "[validate_rule_matrix] analyzer output (first 200 lines):"
  sed -n '1,200p' "$output_file"
  exit 1
fi

total_expected="$(wc -l < "$expected_codes_file")"
total_found="$(wc -l < "$found_codes_file")"
total_positive_expectations="$(wc -l < "$positive_expectations_file")"
echo "[validate_rule_matrix] success: $total_positive_expectations unique expectation bindings across $total_expected lint codes were detected."
echo "[validate_rule_matrix] total distinct codes emitted: $total_found"
