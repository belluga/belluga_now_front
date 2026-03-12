import 'package:get_it/get_it.dart';

class _AppDataRepository {}

class _AppDataSyncController {}

void registerAppDataGlobals() {
  GetIt.I.registerSingleton<_AppDataRepository>(_AppDataRepository());

  // expect_lint: global_ui_controller_naming_forbidden
  GetIt.I.registerSingleton<_AppDataSyncController>(
    _AppDataSyncController(),
  );
}
