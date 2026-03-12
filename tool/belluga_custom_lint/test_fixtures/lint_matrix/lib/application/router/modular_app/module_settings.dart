import 'package:get_it/get_it.dart';

class _ModuleSettingsService {}

class _ModuleSettingsControllerContract {}

void registerModuleSettingsGlobals() {
  GetIt.I.registerFactory<_ModuleSettingsService>(
    () => _ModuleSettingsService(),
  );

  // expect_lint: global_ui_controller_naming_forbidden
  GetIt.I.registerFactory<_ModuleSettingsControllerContract>(
    () => _ModuleSettingsControllerContract(),
  );
}
