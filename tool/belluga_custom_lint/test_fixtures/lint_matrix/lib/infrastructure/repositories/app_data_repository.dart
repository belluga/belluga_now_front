import 'package:get_it/get_it.dart';

class AppDataRepository {}

class AppDataSyncController {}

void registerAppDataGlobals() {
  GetIt.I.registerSingleton<AppDataRepository>(AppDataRepository());

  // expect_lint: global_ui_controller_naming_forbidden
  GetIt.I.registerSingleton<AppDataSyncController>(AppDataSyncController());
}
