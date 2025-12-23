---
description: Introduce a new Flutter domain aggregate with full architectural rigor—docs, value objects, projections, repository contracts, and DI wiring—aligned with our principles (backend-driven UI, DTO→Domain→Projection flow, feature-first structure).
---

# Method: Create Controller (Flutter)

## Purpose
Introduce a controller that owns UI state, side effects, and StreamValue exposure per Sections 5 and 9 of the Flutter architecture doc. Ensures widgets remain pure UI and controllers encapsulate logic.

## Triggers
- New screen/feature requires state management or async operations.
- Shared behaviour should be extracted out of widgets.

## Inputs
- Feature documentation and domain projections involved.
- Existing controllers in the feature for reference.
- GetIt module registrations.

## Procedure
1. **Document intent** – note the controller’s responsibilities in the module doc and Flutter roadmap if it affects API contracts or shared behaviour.
2. **File location** – create the controller under `lib/presentation/.../screens/<screen>/controllers/` (or feature-level controllers folder if shared).
3. **Class structure**
   - Implement `Disposable` when using `StreamValue` or other resources.
   - Inject repositories/services via constructor; resolve with GetIt.
   - Controllers (and domain services they call) are the *only* presentation-layer actors allowed to talk to repositories or infrastructure adapters. Widgets, routes, and helper builders must depend on controller APIs instead of touching data sources.
4. **State management**
   - Expose state via `StreamValue<T>` fields (with default values when appropriate).
   - Provide intent methods (e.g., `loadData`, `applyDecision`) that update these streams.
5. **UI controllers** – if `TextEditingController`, `ScrollController`, etc. are needed, instantiate and dispose them inside the controller (`onDispose`). Widgets obtain them via getters.
6. **BuildContext independence** – controllers must not receive `BuildContext`. Any navigation/dialog work happens in widgets via callbacks.
7. **DI registration** – register the controller in the feature module (`GetIt.registerFactory` or `registerLazySingleton`) and ensure the ModuleScope provides it.
8. **Realtime delta handling (when applicable)** – if the feature has SSE delta streams:
   - Maintain a paginated cache in the controller and apply delta updates by `id`.
   - On stream reconnect, re-fetch the first page to resync.
9. **Tests/analyzer** – add controller tests if behaviour is complex; run `fvm flutter analyze`.

## Outputs
- Controller file with documented responsibilities and StreamValue exposure.
- DI/module setup referencing the controller.
- Updated docs/roadmap.

## Validation
- Analyzer/test suite passes.
- Widgets consume controller streams/controllers via GetIt without owning state themselves.
