# Belluga Now Flutter Architecture Overview

> _Maintainer’s note_: This summary captures knowledge inferred while navigating
> the codebase. It is intentionally pragmatic—focused on how things are wired in
> practice so future sessions can jump straight to implementation details.

---

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

- Example patterns:
  - `TenantHomeController` → `StreamValue<HomeOverview?>`.
  - `ScheduleScreenController` tracks events, schedule summaries, visible
    dates, etc. via multiple streams.
  - Auth controllers manage form status (loading, field enabled, errors) as
    streams.

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

---

### Suggested Workflow Tips

1. **Add dependencies via modules** – keep GetIt registration consistent.
2. **Wrap new routes** with ModuleScope to guarantee dependencies are ready.
3. **Use StreamValue** for state to stay aligned with existing pattern.
4. **Check value-object constraints** when mapping new DTO fields.
5. **Use `MainLogo`** for any screen that needs branding instead of inline assets.

This document should be updated whenever architectural conventions evolve.
