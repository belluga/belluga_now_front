import 'package:get_it/get_it.dart';

class _ModuleSettingsService {}

class _ModuleSettingsControllerContract {}

abstract class _ModuleSettingsRepositoryContract {}

class _ModuleSettingsRepository implements _ModuleSettingsRepositoryContract {}

void registerModuleSettingsGlobals() {
  GetIt.I.registerFactory<_ModuleSettingsService>(
    () => _ModuleSettingsService(),
  );

  // expect_lint: repository_registration_lifecycle_enforced
  GetIt.I.registerFactory<_ModuleSettingsRepositoryContract>(
    () => _ModuleSettingsRepository(),
  );

  // expect_lint: global_ui_controller_naming_forbidden
  GetIt.I.registerFactory<_ModuleSettingsControllerContract>(
    () => _ModuleSettingsControllerContract(),
  );
}
