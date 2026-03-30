# Belluga Analyzer Plugin Rules

## Source of Truth
- Architecture diagnostics are enforced by `belluga_analysis_plugin` via analyzer plugin.
- `custom_lint` is decommissioned for architecture gating.

## Official Commands
- Full project analyzer gate (local + CI, run at repository root):
  - `fvm dart analyze --format machine`
- Local analyzer-state reset and warmup (run from `flutter-app` root when CLI results go false-clean, stale, or hang unexpectedly):
  - `bash ./scripts/reset_analyzer_state.sh`
- Important:
  - Do not use `fvm dart analyze lib` as architecture source-of-truth in this repo.
  - If the root analyzer output looks false-clean, stale, or hangs unexpectedly, reset local analyzer state with `bash ./scripts/reset_analyzer_state.sh` and rerun `fvm dart analyze --format machine`.
  - The first analyzer run after `./scripts/reset_analyzer_state.sh` can be significantly slower while `~/.dartServer/.plugin_manager` rebuilds the plugin AOT snapshot.
- Rule matrix anti-regression gate:
  - `bash tool/belluga_analysis_plugin/bin/validate_rule_matrix.sh`

## `domain_primitive_field_forbidden`

### Canonical remediation (mandatory)
- The ONLY acceptable remediation is **ValueObject**.
- Validation ownership stays in ValueObjects (never in controllers/parsers outside domain VOs).
- DTOs are the only boundary allowed to receive transport primitives.
- Domain constructors/method parameters must be only: `Domain`, `ValueObject<T>`, or `List/Set/Iterable` whose element type is `Domain` or `ValueObject<T>`.
- Any other parameter type is forbidden (`String`, `int`, `DateTime`, `Map`, bare `List/Set/Iterable`, `List<String>`, etc.).
- Typedef aliases do not remediate primitive usage.
- Any class under `domain/**/value_objects/**` must extend `ValueObject<T>` (plain classes in this folder are forbidden).

### Approved ValueObject bases
Use existing base classes when they match the semantic type, for example:
- `GenericStringValue`
- `IntValue`
- `DecimalValue`
- `DateTimeValue`
- `URIValue`

If none matches the domain semantic, create a new `*Value` class extending `ValueObject<T>`.

`ValueObject<T>` generic constraints:
- `T` cannot be `Map`, `List`, `Set`, `Iterable`, or collection-like abstractions.
- If grouped data is needed, model it as auxiliary domain types with their own ValueObject fields.

### Collections and map policy
- `List/Set/Iterable` are allowed only when element types are ValueObjects or domain-owned types.
- Bare `List/Set/Iterable` (without type argument) are forbidden.
- `Map` in domain fields/constructors/method signatures and collection/map return signatures is forbidden.
- Replace `Map` usage with auxiliary domain models composed by ValueObjects.
- Getter/method return types cannot expose `Map/List/Set/Iterable` with primitive payload.
- Parsing helpers like `fromRaw`/`fromJson` belong to DTO/decoder/VO layers, not domain entities.

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

## `controller_delegated_streamvalue_dispose_forbidden`

### Rule intent
Controllers must not dispose delegated `StreamValue` sources.

### Delegated semantics
- External stream target (for example `repository.streamValue.dispose()`).
- Explicit controller getter returning `StreamValue` (for example `get feedStreamValue => ...`).

### Remediation playbook
1. Remove `.dispose()` calls on delegated/external/getter-based `StreamValue`.
2. Keep disposal only for controller-owned `StreamValue` fields.

## `controller_owned_streamvalue_dispose_required`

### Rule intent
Controller-owned `StreamValue` fields must be disposed in `onDispose()` or `dispose()`.

### Remediation playbook
1. For each owned `StreamValue` field, add `<field>.dispose()` in `onDispose()`/`dispose()`.
2. Keep delegated stream disposal forbidden (see previous rule).
