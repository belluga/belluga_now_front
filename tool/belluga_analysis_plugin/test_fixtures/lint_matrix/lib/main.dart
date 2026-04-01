import 'package:get_it/get_it.dart';

class _GlobalAppService {}

class _BootstrapController {}

void configureGlobals() {
  GetIt.I.registerLazySingleton<_GlobalAppService>(() => _GlobalAppService());

  GetIt.I
      // expect_lint: global_ui_controller_naming_forbidden
      .registerLazySingleton<_BootstrapController>(
        () => _BootstrapController(),
      );
}
