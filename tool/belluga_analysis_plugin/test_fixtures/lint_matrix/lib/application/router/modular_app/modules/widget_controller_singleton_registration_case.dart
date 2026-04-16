import 'package:lint_matrix_fixture/presentation/tenant_public/home/controllers/home_feature_controller.dart';
import 'package:lint_matrix_fixture/presentation/tenant_public/home/screens/home_screen/widgets/agenda_section/controllers/home_agenda_section_controller.dart';

abstract class ModuleContract {
  void registerLazySingleton<T extends Object>(T Function() builder) {}

  void registerFactory<T extends Object>(T Function() builder) {}
}

class WidgetControllerSingletonRegistrationCase extends ModuleContract {
  void bad() {
    // expect_lint: widget_controller_singleton_registration_forbidden
    registerLazySingleton<HomeAgendaSectionController>(
      () => HomeAgendaSectionController(),
    );

    // expect_lint: widget_controller_singleton_registration_forbidden
    registerLazySingleton(HomeAgendaSectionController.new);
  }

  void good() {
    registerFactory<HomeAgendaSectionController>(
      () => HomeAgendaSectionController(),
    );

    registerLazySingleton<HomeFeatureController>(() => HomeFeatureController());
  }
}
