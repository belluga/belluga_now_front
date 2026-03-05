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
- `module_direct_getit_registration_forbidden` (`P0`): classes extending `ModuleContract` cannot use direct `GetIt.I.register*`.
- `controller_direct_navigation_forbidden` (`P1`): controllers cannot call Navigator/router navigation methods.
- `ui_navigator_usage_forbidden` (`P1`): UI cannot call `Navigator.*` directly.
- `ui_navigation_after_await_forbidden` (`P1`): UI navigation after async gaps is forbidden.
- `ui_build_side_effects_forbidden` (`P1`): side effects in `build`/`didChangeDependencies` are forbidden.
- `ui_future_stream_builder_forbidden` (`P1`): `FutureBuilder`/`StreamBuilder` are forbidden under `StreamValue` architecture.
- `ui_controller_ownership_forbidden` (`P1`): Screen files cannot own UI controllers/keys; auxiliary widgets can own them only when isolated from feature controller interactions.
- `screen_controller_resolution_pattern_required` (`P2`): screen classes must not receive controller params; resolve controller in screen file.
- `multi_widget_file_warning` (`P2`): screen files should avoid multiple widget classes.
- `controller_buildcontext_dependency_forbidden` (`P2`): controllers cannot use `BuildContext` in API/signatures.
- `global_ui_controller_naming_forbidden` (`P2`): sanctioned global registrations cannot use UI controller naming (`*Controller`, `*ControllerContract`).

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

## Allowlist Policy
- `SEM EXCEÇÃO`: no allowlist and no per-file lint bypass for architecture rules.
- If a warning is incorrect, fix/calibrate the rule; do not bypass the rule.

## Migration Policy
- Stage 1: CI advisory run (`continue-on-error`) + debt inventory.
- Stage 2: burn-down by rule family.
- Stage 3: promote `P0` to blocking (`error`) after zero debt.
- Stage 4: selectively promote `P1` rules to blocking.
