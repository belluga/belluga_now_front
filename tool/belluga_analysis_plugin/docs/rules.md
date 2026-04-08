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
  - After creating or altering analyzer rules, treat the next analyzer run as a cold plugin rebuild window:
    - do not launch multiple `dart analyze` processes in parallel,
    - let one analyzer process finish rebuilding `~/.dartServer/.plugin_manager` first,
    - then re-run validation commands.
  - Cold rebuilds after rule changes can transiently produce corrupted plugin snapshots (`plugin.aot: file too short` / `IsolateSpawnException`) if the plugin manager rebuild is interrupted or raced.
  - Legacy orphan artifacts under `tool/belluga_custom_lint/` can still pollute local editor/analyzer state even though `custom_lint` is decommissioned. The reset script clears those artifacts as part of analyzer recovery.
  - A successful plugin-cache rebuild is necessary, but does not by itself prove root-command parity; if root remains false-clean while explicit-file analyze reports real diagnostics, treat root parity as unresolved and continue under `TODO-v1-analyzer-cli-parity-deterministic-runner.md`.
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

## `controller_delegated_streamvalue_write_forbidden`

### Rule intent
Controllers must not mutate delegated `StreamValue` sources owned by repositories/services or exposed via explicit delegation getters.

### Ownership rule
- Delegated `StreamValue` is read-only in controllers.
- If canonical shared state must change, the controller must call an explicit repository getter/setter or repository mutation API.
- Direct controller-side `.addValue(...)` / `.addError(...)` against delegated streams is forbidden, even when the mutation is logically “needed”.

### Delegated semantics
- External stream target (for example `repository.streamValue.addValue(...)`).
- Explicit controller getter returning `StreamValue` from a delegated source (for example `get feedStreamValue => _repository.feedStreamValue`).

### Forbidden mutations
- `.addValue(...)`
- `.addError(...)`

### Remediation playbook
1. Treat delegated repository/service `StreamValue` as read-only inside the controller.
2. If the controller needs to mutate canonical shared state, add/use an explicit repository getter/setter or repository mutation API and perform the stream write inside the repository.
3. If the controller needs only local screen-stage state, introduce a controller-owned `StreamValue`.

## `controller_streamvalue_parameter_forbidden`

### Rule intent
Controllers must not accept `StreamValue` as a method/helper parameter. Passing `StreamValue` around as a parameter hides ownership, makes delegated mutation easier to smuggle through generic helpers, and weakens the single-writer contract.

### Remediation playbook
1. Remove helper methods that accept `StreamValue` parameters in controllers.
2. Keep mutation explicit at the owned field call site (for example `loadingStreamValue.addValue(true)`).
3. If a small helper is still needed, pass a closure (`VoidCallback`) or create a semantic setter bound to the owned field rather than accepting `StreamValue`.
4. Delegated repository/service `StreamValue` remains read-only in controllers; changing canonical shared state must still go through repository APIs.

## `controller_repository_pagination_arguments_forbidden`

### Rule intent
Controllers must not pass raw pagination control arguments (`page`, `pageSize`, `cursor`, `limit`, etc.) into repository calls.

### Remediation playbook
1. Remove raw pagination arguments from controller-to-repository calls.
2. Expose semantic repository intents instead, for example:
   - `refreshFeed()`
   - `loadNextFeedSlice()`
   - `loadHomeAgenda()`
   - `loadMoreHomeAgenda()`
3. Keep page bookkeeping, cursors, and backend pagination semantics private inside repository implementations.

## `repository_contract_pagination_controls_forbidden`

### Rule intent
For the Schedule/Home/Agenda lane, repository contracts must not expose raw pagination control arguments or delegated pagination state. Public repository APIs may express semantic load/load-more behavior, but page numbers, sizes, cursors, offsets, limits, `hasMore...` delegates, and `loadNext...Page()` APIs are repository-internal concerns.

### Remediation playbook
1. Remove `page`, `pageSize`, `cursor`, `limit`, `offset`, and similar parameters from repository contracts.
2. Remove `hasMore...` delegates and page-addressed method names such as `loadNext...Page()` from repository contracts.
3. Replace them with semantic repository methods, for example:
   - `loadEventSearch(...)`
   - `loadMoreEventSearch(...)`
   - `loadConfirmedEvents(...)`
   - aggregate-specific `refresh...` / `loadMore...` APIs
4. Keep page-envelope helpers and next-page / has-more state private inside the repository implementation.

## `domain_paged_result_type_forbidden`

### Rule intent
For the Schedule/Home/Agenda lane, public domain paged-result/envelope/cache-snapshot types (for example `PagedEventsResult` or `HomeAgendaCacheSnapshot`) are forbidden. Pagination wrappers and cache/query snapshots are transport/repository concerns, not domain surface contracts.

### Remediation playbook
1. Delete public domain paged-result wrappers from `lib/domain/**`.
2. Delete public cache/query snapshot wrappers from `lib/domain/**` when they carry repository-private page/query state.
3. If pagination bookkeeping is still needed, keep it as a private helper inside the repository implementation.
4. Expose only:
   - materialized domain items, or
   - aggregate-specific semantic methods/streams owned by the repository.

## `controller_owned_streamvalue_dispose_required`

### Rule intent
Controller-owned `StreamValue` fields must be disposed in `onDispose()` or `dispose()`.

### Remediation playbook
1. For each owned `StreamValue` field, add `<field>.dispose()` in `onDispose()`/`dispose()`.
2. Keep delegated stream disposal forbidden (see previous rule).
