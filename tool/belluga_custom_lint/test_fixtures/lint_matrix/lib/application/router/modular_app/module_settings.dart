import 'package:get_it/get_it.dart';

class ModuleSettingsService {}

class ModuleSettingsControllerContract {}

void registerModuleSettingsGlobals() {
  GetIt.I.registerFactory<ModuleSettingsService>(() => ModuleSettingsService());

  // expect_lint: global_ui_controller_naming_forbidden
  GetIt.I.registerFactory<ModuleSettingsControllerContract>(
    () => ModuleSettingsControllerContract(),
  );
}
