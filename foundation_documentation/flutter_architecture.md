# Belluga Now Flutter Architecture Overview

> _Maintainer’s note_: This document distills how the Belluga Now Flutter
> application (Guar[APP]ari) is wired today. It combines the original Belluga
> architectural conventions with the reusable guidance we brought from the
> WhatsFlow project, keeping the strongest parts of both.

---

## 1. Core Architectural Concepts

These principles govern every feature we design:

- **Backend-Driven UI** – Labels, CTAs, colours, and copy come from backend
  contracts rather than being hard-coded in Flutter. This allows dynamic
  branding and experimentation without new builds.
- **Component / Template-Based Design** – We prefer data-driven templates such
  as `ItemLandingPage` and `PartnerLandingPage` over bespoke screens. Feature
  APIs must deliver data shaped for those templates.
- **Asynchronous State Management** – User-specific state (invites queue,
  agenda actions, pending tasks) is fetched asynchronously and exposed through
  reactive services. Controllers observe and react; widgets never poll.
- **Unified Data Models** – Domain models implement shared interfaces when
  behaviour overlaps (e.g., anything displayable in the agenda implements a
  `Schedulable` contract). This keeps cross-module features simple.

## 2. Core Growth Engine: Social & Invites

The invite loop remains foundational:

1. Tenants discover a partner or event.
2. Confirmation grants the partner permission for targeted notifications.
3. The app prompts invites via the “Bora?” flow, encouraging viral spread.
4. New users land in-context and can repeat the cycle.

Implications:

- Permissions and analytics live server-side; the client only consumes
  contract-safe data.
- Firebase Cloud Messaging topics align with partner IDs for push campaigns.
- Invite flows run through dedicated controllers (`InviteFlowController`,
  `InviteShareScreenController`) that surface the entire state via `StreamValue`.

## 3. Map & POI Experience Snapshot

- Map data is fetched via REST (viewport queries) and supplemented with
  WebSocket events for live updates.
- `CityMapController` owns *all* shared state: the `MapController`, filters,
  WebSocket subscriptions, and POI/event streams.
- Helper controllers (`FabMenuController`, `RegionPanelController`, etc.) are
  registered in the map module and interact through `StreamValue`s rather than
  direct state mutation.

## 4. Layered Structure

- **Application layer** – Bootstraps theming (`ApplicationContract`), global
  dependency registration (`ModuleSettings`), and AutoRoute configuration.
- **Domain layer** – Holds value objects, core entities, and use-case logic aligned
  with `foundation_documentation/domain_entities.md`. When a feature needs a
  specialised projection (e.g., `EventSummary`), place it alongside the entity
  under a contextual subfolder such as `domain/events/projections/` so the
  relationship stays explicit.
- **Infrastructure layer** – Talks to backends and exposes DTOs that mirror
  transport payloads. No presentation concerns live here.
- **Presentation layer** – Widgets, controllers, and view models. Widgets are
  pure UI; controllers own state and side effects; view models adapt domain
  objects for rendering.

## 5. Data Flow Contracts

- DTOs live under `lib/infrastructure/services/dal/dto/**` and stay close to
  the network format (nullable primitives, snake_case keys when required).
- Domain models expose `fromDTO` constructors. DTOs never “push” into the
  domain layer; controllers call the domain conversion.
- Repositories convert DTOs to domain models and surface domain-centric APIs.
- Controllers compose repositories, expose their state through
  `StreamValue<T>`, and offer intent methods (e.g., `applyDecision`,
  `toggleCategory`).
- Widgets observe controller `StreamValue`s via `StreamValueBuilder`, enabling
  finely scoped rebuilds.

## 6. Project Structure & Modularity

- `lib/application` – Application contracts, router, dependency bootstrap.
- `lib/domain` – Value objects, entities, repository contracts, shared enums.
- `lib/infrastructure` – Repository implementations, datasources, adapters,
  mock backends.
- `lib/presentation` – Feature-first layout. Under `tenant/` each feature lives
  in its own folder (`tenant/invites`, `tenant/map`, etc.) with:
  - `screens/<screen_name>/` containing the screen, a `controllers/`
    subfolder, and optionally a `widgets/` subfolder for screen-specific UI.
  - `widgets/` at the feature root for helpers shared by multiple screens.
  - `routes/` for AutoRoute wrappers, plus optional `data/` or `models/` when
    the feature carries mock data or local models.
- `foundation_documentation/` – Living architecture docs, module specs, mock
  roadmaps.

### 6.1 Module Creation Workflow (Borrowed & Adapted)

1. **Document first** – Create or update the relevant module document under
   `foundation_documentation/modules/` using the template. Capture purpose,
   key workflows, data schemas, and API contracts.
2. **Create the module** – Add a new `ModuleContract` in
   `lib/application/router/modular_app/modules/` that registers controllers,
   repositories, and any scoped services.
3. **Wire the presentation** – Build screen + controller pairs. Controllers
   register in the module; screens retrieve them through GetIt.
4. **Expose routes** – Update `ModuleSettings.initializeSubmodules()` and the
   AutoRoute configuration to include the new module’s routes.
5. **Sync documentation** – Update the roadmap and module docs once
   implementation details settle.

## 7. Navigation (AutoRoute)

- `AppRouter` mixes top-level routes and module-provided routes. Root routes
  (init, auth, tenant shell) live in `app_router.dart` / `app_router.gr.dart`.
- Feature routes sit in `*_route.dart` files that wrap screens in
  `ModuleScope<FeatureModule>` to guarantee dependencies are registered before
  build.
- Guarded routes (e.g., tenant shell) reference auth controllers/resolvers.

## 8. Dependency Injection (GetIt)

- `ModuleSettings.registerGlobalDependencies()` owns global singletons
  (HTTP client, secure storage, analytics, etc.).
- Each feature module registers its controllers, repositories, and ancillary
  services via `registerFactory` / `registerLazySingleton`.
- Widgets fetch controllers via `GetIt.I.get<T>()`. No widget should instantiate
  a controller directly unless explicitly documented as an exception.
- Disposal is handled within controllers’ `onDispose()` (or via module scopes
  for factories).

## 9. Code Quality & Architectural Principles

- **Widgets are Pure UI** – Widgets render based on controller/view-model
  state. They avoid business logic, async operations, or direct repository
  access.
- **Controllers Manage State & Logic** – Controllers own state transitions,
  side effects, validation, and expose `StreamValue`s for observation.
- **Controllers Own UI Controllers** – Feature controllers (map, invites,
  mercado, experiences, auth recovery) hold `TextEditingController`,
  `ScrollController`, `MapController`, etc. Widgets obtain them through GetIt
  and never create/dispose them locally.
- **Constructor Discipline** – Production constructors stay minimal. We defer
  test-only factories or DI overrides until the testing effort explicitly
  demands them.
- **Reactive State Exposure** – Shared state is surfaced via `StreamValue<T>`.
  No controller keeps parallel private variables for the same data.
- **Strict Theming** – All colours come from `Theme.of(context).colorScheme`
  (except branded values delivered by the backend).
- **DTO → Domain → View Model Flow** – Services return DTOs; repositories map
  them into domain entities (or domain projections) before returning to
  controllers. Controllers work exclusively with domain objects and, when the UI
  needs a specific projection (additional formatting, combined fields), create a
  view model under the screen’s `view_models/` folder. Widgets never touch DTOs.
- **Infrastructure-Scoped Mappers** – Keep DTO knowledge inside the
  infrastructure layer. If a feature needs shared helpers, expose them as
  mixins or mapper classes that live alongside the repository implementation
  (e.g., `infrastructure/mappers/<feature>_dto_mapper.dart`). Repositories may
  apply those mixins, but domain entities must remain unaware of DTO types.
- **One Widget per File** – Significant helper widgets move into dedicated
  files under `widgets/`. Methods returning widgets are reserved for trivial
  snippets; otherwise, promote them to proper widgets.
- **Controllers are BuildContext-Agnostic** – Controllers never require
  `BuildContext`. They signal intent; widgets perform navigation/dialog work.

## 10. Testing & Tooling Notes

- `flutter analyze` must stay clean; CI should run analyzer + unit tests.
- Feature controllers expose intent methods that make unit testing easy
  (e.g., verify `applyDecision` adjusts the invite stream appropriately).
- When adding generated code (AutoRoute, freezed, json_serializable), ensure
  build_runner configs live under `tool/` and that generated files remain
  checked in or explicitly ignored per team policy.

---

_Keep this document current. Every time we introduce a significant pattern or
module, update the relevant section so future engineers (human or AI) can align
quickly._
