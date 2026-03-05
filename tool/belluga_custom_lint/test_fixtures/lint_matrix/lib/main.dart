import 'package:get_it/get_it.dart';

class GlobalAppService {}

class BootstrapController {}

void configureGlobals() {
  GetIt.I.registerLazySingleton<GlobalAppService>(() => GlobalAppService());

  GetIt.I
      // expect_lint: global_ui_controller_naming_forbidden
      .registerLazySingleton<BootstrapController>(() => BootstrapController());
}
