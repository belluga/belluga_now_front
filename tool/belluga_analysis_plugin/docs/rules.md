# Belluga Analyzer Plugin Rules

## Source of Truth
- Architecture diagnostics are enforced by `belluga_analysis_plugin` via analyzer plugin.
- `custom_lint` is decommissioned for architecture gating.

## Official Commands
- Full project analyzer gate (local + CI, run at repository root):
  - `fvm dart analyze --format machine`
- Important:
  - Do not use `fvm dart analyze lib` as architecture source-of-truth in this repo.
  - Directory-target mode is currently inconsistent here (`lib` can false-clean while root/file targets emit diagnostics).
- Rule matrix anti-regression gate:
  - `bash tool/belluga_analysis_plugin/bin/validate_rule_matrix.sh`

## `domain_primitive_field_forbidden`

### Canonical remediation (mandatory)
- The ONLY acceptable remediation is **ValueObject**.
- Validation ownership stays in ValueObjects (never in controllers/parsers outside domain VOs).
- Typedef aliases do not remediate primitive usage.

### Approved ValueObject bases
Use existing base classes when they match the semantic type, for example:
- `GenericStringValue`
- `IntValue`
- `DecimalValue`
- `DateTimeValue`
- `URIValue`

If none matches the domain semantic, create a new `*Value` class extending `ValueObject<T>`.

### Collections and map policy
- `List/Set/Iterable` are allowed only when element types are ValueObjects or domain-owned types.
- Bare `List/Set/Iterable` (without type argument) are forbidden.
- `Map` in domain fields/constructors/method signatures is forbidden.
- Replace `Map` usage with auxiliary domain models composed by ValueObjects.

### Quick examples
Violation:
```dart
class EventFilter {
  final Map<String, Object?> metadata;
  final List<String> tags;
}
```

Canonical direction:
```dart
class EventFilter {
  final EventMetadata metadata;
  final List<EventTagValue> tags;
}
```

## `repository_raw_payload_map_forbidden`

### Rule intent
Repositories cannot own raw payload map typing/parsing/building (`Map<String, Object?>`).

### Remediation playbook
1. Move raw payload parsing to DAO/DTO decoder layer.
2. Make repository consume typed DTO/decoder output only.
3. Keep transport map assembly/parsing out of repositories.
