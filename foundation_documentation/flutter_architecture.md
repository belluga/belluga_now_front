# Belluga Now Flutter Architecture Overview

> _Maintainer’s note_: This summary captures knowledge inferred while navigating
> the codebase. It is intentionally pragmatic—focused on how things are wired in
> practice so future sessions can jump straight to implementation details.

---

## Layered Structure Snapshot

- **Application layer** wires theming (`application_contract.dart`), global initialisation, and module bootstrap. Keep business logic out of this layer.
- **Domain layer** expresses rules through models that wrap primitives with `ValueObject`s (`MongoIDValue`, `TitleValue`, `DateTimeValue`, etc.).
- **Infrastructure layer** talks to backends (real or mock) and exposes DTOs that mirror external payloads.
- **Presentation layer** focuses on widgets, controllers, and view models. Widgets consume primitives via view models suchs as `EventCardData`, never DTOs or raw value objects.

## Data Flow Contracts

- DTOs live under `lib/infrastructure/services/dal/dto/**` and stay close to the transport format (nullable fields, primitive types).
- Domain models expose `fromDTO` constructors. DTOs never “know” the domain (`toDomain` is avoided).
- Repositories convert DTOs into domain objects and expose domain-centric APIs. They are the only layer that depends on both DTOs and domain entities.
- Controllers compose repositories and publish results through `StreamValue<T>`. Widgets observe them with `StreamValueBuilder`, enabling atomic updates (i.e. only the affected section rerenders).
- View models shape the data widgets need (formatting, fallbacks, asset URLs) so presentation stays decoupled from domain intricacies.

## Project Structure & Modularity

- **`lib/application`**  
  - `ApplicationContract` extends `ModularAppContract` from
    `get_it_modular_with_auto_route`, bootstrapping `AppRouter` and
    `ModuleSettings`.
  - `ModuleSettings` registers global dependencies (backend, repositories,
    controllers) and then registers feature modules.
  - `ApplicationMobile` / `ApplicationWeb` wire platform-specific
    preferences (orientation, etc.) and provide concrete auth/backend builders.

- **Feature Modules (`lib/application/router/modular_app/modules`)**
  - Each module extends `ModuleContract`.
  - They register feature-specific controllers/repositories via GetIt.
  - Modules currently used:
    - `InitializationModule` – registers tenant and landlord home controllers.
    - `AuthModule` – provides login, remember-password, create-password, and
      recovery controllers (lazy or factory registered).
    - `ProfileModule`, `ScheduleModule`, etc. register their respective
      controllers/repositories.

## Navigation

- **Router**: `AppRouter` (AutoRoute) mixes top-level routes and module-provided
  routes.
  - Home (`/`) guarded by `TenantRouteGuard`.
  - Landlord home, login, recovery, etc. available via explicit paths.
  - Schedule routes (`/agenda`, `/agenda/procurar`) currently unguarded
    (deliberately for dev/testing).

- **Route Wrapper Pattern**  
  - Every screen exposed via AutoRoute has a companion `*_route.dart`
    widget that wraps the real screen inside a `ModuleScope<FeatureModule>`.
  - Example: `ScheduleRoute` → `ModuleScope<ScheduleModule>(child:
    ScheduleScreen())`.
  - This ensures module dependencies are initialized/disposed automatically.

## Dependency Injection (GetIt)

- Controllers & repositories are registered in modules or during app init.
- Screens obtain dependencies via `GetIt.I.get<T>()` (with late finals).
- Disposal responsibilities:
  - Some controllers expose `onDispose()` to close streams/controllers.
  - Screens typically call `controller.onDispose()` in `dispose()`, but avoid
    unregistering from GetIt—the module handles lifecycle.

## State Management

- Uses [`stream_value`](https://pub.dev/packages/stream_value) extensively.
  - Controllers expose `StreamValue<T>` for UI state.
  - Widgets use `StreamValueBuilder` to rebuild sections of UI.
  - Pattern encourages atomic streams (e.g. schedule screen has separate
    streams for events, visible dates, etc.).
- `StreamValue` keeps the “bloc-like” intent while allowing targeted updates (fetch more events without touching other widgets). Controllers should dispose every `StreamValue` they own.

- Example patterns:
  - `TenantHomeController` → `StreamValue<HomeOverview?>`.
  - `ScheduleScreenController` tracks events, schedule summaries, visible
    dates, etc. via multiple streams.
  - Auth controllers manage form status (loading, field enabled, errors) as
    streams.

## Code Quality & Architectural Principles

To ensure a maintainable, testable, and scalable codebase, the following principles must be strictly adhered to, especially within the Presentation Layer:

-   **Widgets are for UI (Purely Presentational):**
    -   Widgets should focus solely on rendering the user interface based on the state provided to them.
    -   They should contain minimal to no business logic, complex decision-making, or asynchronous operations.
    -   All UI-specific state that impacts the overall screen should be managed by the controller.

-   **Controllers Manage State & Logic:**
    -   Controllers are responsible for all application state, business logic, and orchestrating data flow.
    -   They expose `StreamValue`s for the UI to consume.
    -   Complex logic, asynchronous calls, and state transitions belong here.

-   **Strict Theming (No Hardcoded Colors):**
    -   All colors used in the UI must derive from `Theme.of(context).colorScheme`.
    -   Hardcoded color values (e.g., `Color(0xFF...)`, `Colors.red`) are strictly forbidden.
    -   The only exception is for dynamic colors coming directly from the backend (e.g., a POI's specific brand color), which should still be handled gracefully.

-   **One Widget Per File (Generally):**
    -   Extract smaller, reusable widgets into their own dedicated files.
    -   **Hierarchical Widget Organization:**
        -   A main widget (e.g., a screen) should reside in its own file at the root of its feature context (e.g., `my_feature_screen.dart`).
        -   Local helper widgets, not intended for broader sharing, should be placed in a `widgets/` subfolder *within the main widget's folder* (e.g., `my_feature_screen/widgets/my_local_helper_widget.dart`).
        -   If a widget initially created as a local helper is later found to be beneficial for reuse across multiple contexts, it should be moved to a higher-level, common `widgets/` folder that oversees all contexts where it is used.
    -   Private helper widgets (`_MyWidget`) within a file should be extracted if they grow beyond a trivial size or are used in multiple places.

-   **Delegation of Dynamic Routing:**
    -   Widgets should delegate dynamic routing logic to the controller.
    -   The widget calls a controller method (e.g., `controller.navigateToDetails(item)`), and the controller handles the logic to determine the correct route and parameters, returning the route to the widget for execution (e.g., `context.router.push(route)`).

-   **Avoid Local `setState` in Screens:**
    -   For any state that impacts the overall screen or is derived from controller actions, it should be managed by the controller and exposed via `StreamValue`s.
    -   `setState` should be reserved for purely transient, local UI state that does not affect the application's core logic or other parts of the UI.

-   **Complex Widgets with Dedicated Controllers:**
    -   For complex UI components (e.g., a custom FAB menu, a detailed filter panel), consider giving them their own dedicated controllers.
    -   These controllers manage the component's internal state and logic, communicating with parent controllers (like `CityMapController`) for broader application state changes.
    -   This enhances modularity, testability, and separation of concerns.

-   **Helper Widgets and Dependency Injection (DI):**
    -   Helper widgets, even when extracted into their own files, can access controllers via GetIt's Dependency Injection mechanism.
    -   If a helper widget is scoped solely for a specific screen (i.e., it's not intended for broader reuse across different screens), it is acceptable for it to retrieve that screen's controller directly via `GetIt.I.get<ScreenController>()`.
    -   This approach avoids 'prop drilling' (passing numerous parameters down the widget tree) and keeps widget constructors clean, while still adhering to the principle of widgets being purely presentational.

## Data Layer

- **Repositories**
  - Interfaces under `lib/domain/repositories`.
  - Implementations under `lib/infrastructure/repositories`.
  - Repositories depend either on GetIt-registered backend contracts or other
    repositories.

- **DTOs**
  - Located in `lib/infrastructure/services/dal/dto/**`.
  - Domain models expose `fromDTO` constructors.
  - Example: Home module uses DTOs → domain models → view models.

- **Backends**
  - `MockBackend` provides mock implementations for features (tenant, auth,
    home, schedule, etc.).
  - Additional mock backends for schedule, notes, etc. under
    `lib/infrastructure/services/dal/dao/mock_backend`.

## Example Feature: Schedule

- `ScheduleScreenController` requests data from `ScheduleRepository`, pushes results into `eventsStreamValue`, and keeps additional `StreamValue`s for date selectors and visibility flags.
- `ScheduleRepository` delegates to `ScheduleBackendContract` (mocked via `MockScheduleBackend`) and converts DTOs to domain models (`EventModel.fromDTO`).
- `ScheduleScreen` maps each `EventModel` into `EventCardData`, reusing the shared `UpcomingEventCard` for visual consistency with the home tab.
- Mock data now covers several calendar days and multiple events per day, so navigating the date row demonstrates distinct cards per selection.

## UI Layer Patterns

- **Bottom Navigation**
  - `BellugaBottomNavigationBar` receives `currentIndex` and drives route
    navigation via `context.router.replaceAll`.
  - Currently only Home (`index 0`) and Agenda (`index 1`) are functional;
    other tabs show a Snackbar placeholder.

- **App Bars**
  - `MainLogo` widget centralizes the display of the horizontal PNG logo and is
    reused by Home, Schedule, Auth screens, etc.

- **Schedule Feature**
  - `ScheduleScreenController` fetches mock data, maintains visible/selected
    dates, and stream-updates the UI.
  - `ScheduleScreen` uses `MainLogo`, bottom navigation, and listens to event
    streams to render cards.

- **Auth Flow**
  - Controllers manage validation, errors, and navigation to subsequent pages.
  - Route wrappers ensure controllers are registered before screen build.

## Styling & Theming Notes

- `ApplicationContract` centralises colour definitions (primary `#4fa0e3`, secondary `#e80d5d`). Derive any additional swatches from these seeds.
- Shared branding elements (like `MainLogo`) should be reused in every top-level screen to avoid divergent asset handling.

## Value Object Notes

- Uses `value_object_pattern` package.
  - Some VO constructors enforce specific lengths (e.g. `TitleValue`
    default min length of 5).  
  - Adjusted event type name creation with `TitleValue(minLenght: 1)` to accept
    shorter names (“Show”).

## Asset Loading

- Logos now rely on PNG (`assets/images/logo_horizontal.png`) after SVG caused
  missing-asset exceptions.
  - Ensure `pubspec.yaml` includes the assets directory (`assets/images/`).

## Error Handling & Gotchas

- When adding new DTO fields, ensure corresponding VO/parsers accept their
  format (e.g., DateTime string parsing, slug creation).
- Stream lifecycles: remember to dispose controllers that own text fields,
  scroll controllers, etc., inside `onDispose()` implementations.
- AutoRoute refresh: run `flutter pub run build_runner build
  --delete-conflicting-outputs` after modifying routes or annotations.

## Workflows & Tooling

- After changing routing/modules or generated files, run
  `flutter pub run build_runner build` to sync AutoRoute outputs.
- Run `flutter analyze` regularly. Existing warnings (missing type annotations,
  `withOpacity` deprecations) are known, but new code should not introduce
  regressions.
- Prefer the established GetIt + `StreamValue` pattern for new features; align
  controller lifecycles with `ScheduleScreenController` and `TenantHomeController`.
- Document new architectural insights here to keep future sessions aligned.

---

### Suggested Workflow Tips

1. **Add dependencies via modules** – keep GetIt registration consistent.
2. **Wrap new routes** with ModuleScope to guarantee dependencies are ready.
3. **Use StreamValue** for state to stay aligned with existing pattern.
4. **Check value-object constraints** when mapping new DTO fields.
5. **Use `MainLogo`** for any screen that needs branding instead of inline assets.

This document should be updated whenever architectural conventions evolve.
