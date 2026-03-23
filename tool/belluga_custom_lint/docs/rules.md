# Belluga Custom Lint Rules

## Status Model
- `P0`: architecture blocking targets (promote to `error` after debt burn-down).
- `P1`: advisory warnings during migration, promotable to blocking.
- `P2`: consistency warnings.

## Warning Treatment Linkage
- Lint diagnostics now use `correctionMessage` in `Treatments: ...` format.
- This provides immediate remediation context directly in the warning output.

## Canonical Contract References
- Architecture source of truth: `foundation_documentation/modules/flutter_client_experience_module.md` (`2.1.1 Presentation DI Matrix`).
- Operational enforcement source: `delphi-ai/skills/flutter-architecture-adherence/SKILL.md`.
- This file is the executable lint surface (rule IDs + treatments). Prefer references over duplicating rule prose across multiple docs.

## Presentation DI Matrix (Canonical)
| Context | Allowed | Forbidden |
|---|---|---|
| Screen (`presentation/**/screens/**`) | Resolve same-feature controller via `GetIt`; consume controller-owned state/controllers/keys. | Resolve repository/service/DAO/backend/DTO; resolve cross-feature controllers; own UI controllers/keys locally. |
| Auxiliary widget (`presentation/**/widgets/**`) isolated | Local UI controllers/keys only when fully local and not bridged into feature controller API. | Non-controller DI; cross-feature controller DI. |
| Auxiliary widget interacting with feature controller | Consume feature-controller-owned UI controllers/keys and trigger controller intents. | Keep local UI controller/key and bridge it into feature controller methods. |
| Module class (`ModuleContract`) | `registerLazySingleton`, `registerFactory`, `registerRouteResolver`. | Direct `GetIt.I.register*` / `GetIt.instance.register*`. |
| Global bootstrap (`main.dart`, `ModuleSettings`, app bootstrap repository) | App-lifecycle non-UI services/contracts/gates/coordinators. | Any global registration named `*Controller` / `*ControllerContract`. |

## Rule Catalog
- `ui_getit_non_controller_forbidden` (`P0`): UI must resolve only controller types through `GetIt`.
- `ui_direct_repository_service_resolution_forbidden` (`P0`): UI cannot resolve repository/service/DAO/backend/DTO types.
- `ui_cross_feature_controller_resolution_forbidden` (`P0`): UI cannot resolve controllers from another feature root.
- `module_scoped_controller_dispose_forbidden` (`P0`): UI cannot dispose module-scoped controllers.
- `ui_streamvalue_ownership_forbidden` (`P0`): UI cannot own `StreamValue`/`StreamController`.
- `ui_dto_import_forbidden` (`P0`): presentation cannot import DTO artifacts.
- `domain_dto_dependency_forbidden` (`P0`): domain cannot depend on DTO artifacts.
- `domain_json_factory_forbidden` (`P0`): domain cannot declare `fromJson`/`fromMap` factories.
- `repository_json_parsing_forbidden` (`P0`): repositories cannot parse raw JSON or hydrate DTOs directly.
- `repository_model_stream_lifecycle_methods_required` (`P1`): repositories owning `StreamValue` with `*Model` payload must expose initialize/populate + refresh lifecycle methods returning `void`/`Future<void>`.
- `repository_model_streamvalue_nullable_required` (`P1`): repositories must keep model-carrying `StreamValue` payloads top-level nullable (`StreamValue<T?>`).
- `repository_registration_scope_enforced` (`P1`): repositories can be registered only in `module_settings.dart`.
- `repository_registration_lifecycle_enforced` (`P1`): repositories cannot be registered with factory lifecycle; use singleton lifecycle.
- `repository_raw_payload_map_forbidden` (`P0`): repositories cannot own raw payload map typing/parsing/building (`Map<String, Object?>`).
- `repository_raw_transport_typing_forbidden` (`P0`): repositories cannot declare raw transport typing such as `dynamic` or `Map<String, dynamic>`.
- `service_json_parsing_forbidden` (`P0`): services cannot parse raw JSON or hydrate DTOs directly.
- `repository_service_catch_return_fallback_forbidden` (`P0`): repositories/services cannot return fallback values inside `catch/on` handlers.
- `repository_inline_dto_to_domain_mapper_forbidden` (`P0`): repositories cannot own inline DTO -> domain mapper methods.
- `module_direct_getit_registration_forbidden` (`P0`): classes extending `ModuleContract` cannot use direct `GetIt.I.register*`.
- `controller_direct_navigation_forbidden` (`P1`): controllers cannot call Navigator/router navigation methods.
- `controller_repository_async_model_fetch_forbidden` (`P1`): controllers cannot invoke repository async methods returning `*Model` payloads directly.
- `controller_streamvalue_model_ownership_forbidden` (`P1`): controllers cannot own `StreamValue` with `*Model` payload; canonical model streams must be delegated from repositories.
- `ui_navigator_usage_forbidden` (`P1`): UI cannot call `Navigator.*` directly.
- `ui_navigation_after_await_forbidden` (`P1`): UI navigation after async gaps is forbidden.
- `route_page_must_live_in_routes_folder` (`P1`): `@RoutePage` declarations must live in `lib/presentation/**/routes/**`.
- `ui_build_side_effects_forbidden` (`P1`): side effects in `build`/`didChangeDependencies` are forbidden.
- `ui_route_param_hydration_forbidden` (`P1`): screens cannot hydrate feature data from `widget.<route_param>` inside lifecycle methods (`initState`/`didUpdateWidget`).
- `route_path_param_requires_resolver_route` (`P1`): route pages using `@PathParam` must extend `ResolverRoute<,>` for model hydration through a route resolver.
- `ui_future_stream_builder_forbidden` (`P1`): `FutureBuilder`/`StreamBuilder` are forbidden under `StreamValue` architecture.
- `ui_streamvalue_builder_null_check_forbidden` (`P1`): UI must not null-check the builder value inside `StreamValueBuilder`; use `onNullWidget`.
- `ui_controller_ownership_forbidden` (`P1`): Screen files cannot own UI controllers/keys; auxiliary widgets can own them only when isolated from feature controller interactions.
- `domain_primitive_field_forbidden` (`P1`): domain fields cannot use primitive transport-oriented types directly.
- `screen_controller_resolution_pattern_required` (`P2`): screen classes must not receive controller params; resolve controller in screen file.
- `multi_public_class_file_warning` (`P2`): files under `lib/` should keep one public class per file.
- `multi_widget_file_warning` (`P2`): screen files should avoid multiple widget classes.
- `controller_buildcontext_dependency_forbidden` (`P2`): controllers cannot use `BuildContext` in API/signatures.
- `global_ui_controller_naming_forbidden` (`P2`): sanctioned global registrations cannot use UI controller naming (`*Controller`, `*ControllerContract`).
- `tenant_canonical_domain_required` (`P0`): tenant-scoped networking/config code must derive API/admin origins from `AppData.mainDomainValue`, not `href`/`hostname`/`schema`.

Rollout note: `repository_raw_payload_map_forbidden` is currently kept disabled in root `analysis_options.yaml` and enforced via branch-delta checks during the debt burndown program.

## Violation/Fix Examples

### `ui_getit_non_controller_forbidden`
Violation:
```dart
final service = GetIt.I.get<AnalyticsService>();
```
Fix:
```dart
final controller = GetIt.I.get<HomeController>();
```

### `ui_direct_repository_service_resolution_forbidden`
Violation:
```dart
final repo = GetIt.I.get<ScheduleRepositoryContract>();
```
Fix:
```dart
controller.refresh();
```

### `ui_cross_feature_controller_resolution_forbidden`
Violation:
```dart
final mapController = GetIt.I.get<MapController>();
```
Fix:
```dart
final homeController = GetIt.I.get<HomeController>();
```

### `module_scoped_controller_dispose_forbidden`
Violation:
```dart
controller.dispose();
```
Fix:
```dart
// No manual disposal in UI; scope teardown handles lifecycle.
```

### `ui_streamvalue_ownership_forbidden`
Violation:
```dart
final streamValue = StreamValue<int>(defaultValue: 0);
```
Fix:
```dart
final streamValue = controller.counterStreamValue;
```

### `ui_dto_import_forbidden`
Violation:
```dart
import 'package:app/infrastructure/dal/dto/event_dto.dart';
```
Fix:
```dart
import 'package:app/domain/schedule/event.dart';
```

### `domain_dto_dependency_forbidden`
Violation:
```dart
import 'package:app/infrastructure/dal/dto/event_dto.dart';
```
Fix:
```dart
class Event {
  const Event({required this.id});
  final String id;
}
```

### `domain_json_factory_forbidden`
Violation:
```dart
class EventConfig {
  factory EventConfig.fromJson(Map<String, dynamic> json) => EventConfig();
}
```
Fix:
```dart
class EventConfig {
  factory EventConfig.fromPrimitives({required EventNameValue nameValue}) =>
      EventConfig();
}
```

### `repository_json_parsing_forbidden`
Violation:
```dart
final dto = EventDTO.fromJson(json);
```
Fix:
```dart
final dto = await backend.fetchEventDto();
return mapEventDto(dto);
```

### `repository_model_stream_lifecycle_methods_required`
Violation:
```dart
class ScheduleRepository {
  final eventsStreamValue = StreamValue<List<EventModel>?>(defaultValue: null);
}
```
Fix:
```dart
class ScheduleRepository {
  final eventsStreamValue = StreamValue<List<EventModel>?>(defaultValue: null);

  Future<void> initializeEvents() async { ... }
  Future<void> refreshEvents() async { ... }
}
```

### `repository_model_streamvalue_nullable_required`
Violation:
```dart
final eventsStreamValue = StreamValue<List<EventModel>>(defaultValue: const []);
```
Fix:
```dart
final eventsStreamValue = StreamValue<List<EventModel>?>(defaultValue: null);
```

### `repository_registration_scope_enforced`
Violation:
```dart
// file: lib/application/router/modular_app/modules/home_module.dart
registerLazySingleton<ScheduleRepositoryContract>(() => ScheduleRepository());
```
Fix:
```dart
// move repository registration to:
// lib/application/router/modular_app/module_settings.dart
```

### `repository_registration_lifecycle_enforced`
Violation:
```dart
GetIt.I.registerFactory<ScheduleRepositoryContract>(() => ScheduleRepository());
```
Fix:
```dart
GetIt.I.registerLazySingleton<ScheduleRepositoryContract>(
  () => ScheduleRepository(),
);
```

### `repository_raw_transport_typing_forbidden`
Violation:
```dart
Map<String, dynamic> _extractItem(dynamic raw) { ... }
```
Fix:
```dart
Future<EventDto> fetchEventDto() => _dao.fetchEventDto();
```

### `repository_raw_payload_map_forbidden`
Violation:
```dart
Map<String, Object?> _extractItem(Object? raw) { ... }
final payload = <String, Object?>{'name': name};
```
Fix:
```dart
final response = await dao.fetchAccountItemDto();
return mapAccountDto(response);
```

Resolution playbook:
1. Create or extend a DAO/DTO **response decoder** that receives raw HTTP payload and outputs typed DTOs (or typed decoder models).
2. Move all repository `_extract*` map/envelope/list parsing into that decoder (including `is Map`, `as/cast`, `whereType<Map>`).
3. For write flows, create a DAO-side **request encoder/builder** that assembles transport maps/multipart payloads.
4. Make repository methods consume typed decoder outputs and return domain/projections only (no raw map ownership).
5. During debt-lane rollout, run branch-delta guard (`bash tool/belluga_custom_lint/bin/check_branch_delta_raw_payload_map.sh`) even when the rule is disabled globally in root config.

No-workaround policy (linted as violations in repositories):
- `Map` without generics as a replacement for `Map<String, Object?>`.
- `is Map` / `is! Map` used for envelope parsing in repositories.
- `cast<String, Object?>()` or `whereType<Map>()` used to bypass typed raw-map checks.

### `service_json_parsing_forbidden`
Violation:
```dart
final payload = jsonDecode(raw);
```
Fix:
```dart
return backend.decodePayload(raw);
```

### `repository_service_catch_return_fallback_forbidden`
Violation:
```dart
try {
  return await backend.fetch();
} catch (_) {
  return const <Model>[]; // fallback hidden in repository/service
}
```
Fix:
```dart
try {
  return await backend.fetch();
} catch (error, stackTrace) {
  Error.throwWithStackTrace(
    StateError('Repository fetch failed: $error'),
    stackTrace,
  );
}
```

### `repository_inline_dto_to_domain_mapper_forbidden`
Violation:
```dart
EventModel mapEvent(EventDTO dto) => EventModel.fromPrimitives(...);
```
Fix:
```dart
class EventRepository with EventDtoMapper {
  EventModel read(EventDTO dto) => mapEventDto(dto);
}
```

### `module_direct_getit_registration_forbidden`
Violation:
```dart
class HomeModule extends ModuleContract {
  void configure() {
    GetIt.I.registerLazySingleton<HomeService>(() => HomeService());
  }
}
```
Fix:
```dart
class HomeModule extends ModuleContract {
  void configure() {
    registerLazySingleton<HomeService>(() => HomeService());
  }
}
```

### `controller_direct_navigation_forbidden`
Violation:
```dart
router.push(const HomeRoute());
```
Fix:
```dart
navigationIntentStreamValue.add(HomeNavigationIntent.openHome());
```

### `controller_repository_async_model_fetch_forbidden`
Violation:
```dart
final events = await _scheduleRepository.fetchAgendaEvents();
```
Fix:
```dart
await _scheduleRepository.refreshAgendaEvents();
// UI consumes controller-delegated repository StreamValue
```

### `controller_streamvalue_model_ownership_forbidden`
Violation:
```dart
final displayedEventsStreamValue =
    StreamValue<List<EventModel>?>(defaultValue: null);
```
Fix:
```dart
StreamValue<List<EventModel>?> get displayedEventsStreamValue =>
    _scheduleRepository.homeAgendaEventsStreamValue;
```

### `ui_navigator_usage_forbidden`
Violation:
```dart
Navigator.of(context).push(route);
```
Fix:
```dart
context.router.push(route);
```

### `ui_navigation_after_await_forbidden`
Violation:
```dart
await controller.save();
context.router.pop();
```
Fix:
```dart
await controller.save();
// controller emits navigation intent, UI reacts synchronously
```

### `route_page_must_live_in_routes_folder`
Violation:
```dart
// lib/presentation/tenant_admin/accounts/screens/location_picker_screen.dart
@RoutePage()
class TenantAdminLocationPickerScreen extends StatefulWidget { ... }
```
Fix:
```dart
// lib/presentation/tenant_admin/accounts/routes/tenant_admin_location_picker_route.dart
@RoutePage(name: 'TenantAdminLocationPickerRoute')
class TenantAdminLocationPickerRoutePage extends StatelessWidget { ... }
```

### `route_path_param_requires_resolver_route`
Violation:
```dart
@RoutePage()
class AccountDetailRoute extends StatelessWidget {
  const AccountDetailRoute({@PathParam('slug') required this.slug});
  final String slug;
}
```
Fix:
```dart
@RoutePage()
class AccountDetailRoute extends ResolverRoute<AccountModel, AccountsModule> {
  const AccountDetailRoute({@PathParam('slug') required this.slug});
  final String slug;

  @override
  RouteResolverParams get resolverParams => {'slug': slug};
}
```

### `ui_build_side_effects_forbidden`
Violation:
```dart
@override
Widget build(BuildContext context) {
  controller.fetchData();
  return const SizedBox.shrink();
}
```
Fix:
```dart
@override
void initState() {
  super.initState();
  controller.load();
}
```

### `ui_route_param_hydration_forbidden`
Violation:
```dart
@override
void initState() {
  super.initState();
  _controller.loadAccountProfile(widget.slug);
}
```
Fix:
```dart
// RouteModelResolver hydrates route model/id before screen build.
// Screen remains passive and consumes resolved data.
@override
void initState() {
  super.initState();
  _controller.loadAccountProfile(resolvedAccountProfileId);
}
```

### `ui_future_stream_builder_forbidden`
Violation:
```dart
FutureBuilder(future: controller.loadOnce(), builder: ...)
```
Fix:
```dart
StreamValueBuilder(streamValue: controller.stateStreamValue, builder: ...)
```

### `ui_controller_ownership_forbidden`
Violation:
```dart
final _controller = TextEditingController();
final _formKey = GlobalKey<FormState>();
```
Fix:
```dart
// Screen:
// move ownership to feature controller.
//
// Auxiliary widget:
// keep local only if it does not pass/bridge this controller to feature controller calls.
```

### `domain_primitive_field_forbidden`
Rollout note:
```yaml
custom_lint:
  rules:
    - domain_primitive_field_forbidden: false
```
Violation:
```dart
class EventModel {
  EventModel(String id) : id = id;

  final String id;
}
```
Fix:
```dart
class EventModel {
  EventModel({required EventIdValue idValue}) : idValue = idValue;

  final EventIdValue idValue;
}
```

### `screen_controller_resolution_pattern_required`
Violation:
```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller});
  final HomeController controller;
}
```
Fix:
```dart
class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final HomeController controller = GetIt.I.get<HomeController>();
}
```

### `multi_public_class_file_warning`
Violation:
```dart
class EventCard {}
class EventBadge {}
```
Fix:
```dart
class EventCard {}

class _EventBadge {}
```

### `multi_widget_file_warning`
Violation:
```dart
class HomeScreen extends StatelessWidget {}
class HomeCardWidget extends StatelessWidget {}
```
Fix:
```dart
// Keep screen in *_screen.dart and move other widgets to dedicated files.
```

### `controller_buildcontext_dependency_forbidden`
Violation:
```dart
void load(BuildContext context) {}
```
Fix:
```dart
void load() {}
```

### `global_ui_controller_naming_forbidden`
Violation:
```dart
GetIt.I.registerFactory<AuthController>(() => AuthController());
```
Fix:
```dart
GetIt.I.registerFactory<AuthSessionService>(() => AuthSessionService());
```

### `tenant_canonical_domain_required`
Violation:
```dart
final origin = Uri.parse(appData.href);
return origin.resolve('/api').toString();
```
Fix:
```dart
final origin = appData.mainDomainValue.value;
return origin.resolve('/api').toString();
```

## Allowlist Policy
- `SEM EXCEÇÃO`: no allowlist and no per-file lint bypass for architecture rules.
- If a warning is incorrect, fix/calibrate the rule; do not bypass the rule.

## Migration Policy
- Stage 1: CI advisory run (`continue-on-error`) + debt inventory.
- Stage 2: burn-down by rule family.
- Stage 3: promote `P0` to blocking (`error`) after zero debt.
- Stage 4: selectively promote `P1` rules to blocking.
