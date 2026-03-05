import 'package:get_it/get_it.dart';

abstract class ModuleContract {
  void registerLazySingleton<T extends Object>(T Function() builder) {}

  void registerFactory<T extends Object>(T Function() builder) {}

  void registerRouteResolver<TModel>(Object Function() factory) {}
}

class AnyService {}

class AnyController {}

class ModuleRegistrationCase extends ModuleContract {
  void bad() {
    // expect_lint: module_direct_getit_registration_forbidden
    GetIt.I.registerLazySingleton<AnyService>(() => AnyService());

    // expect_lint: module_direct_getit_registration_forbidden
    GetIt.instance.registerFactory<AnyService>(() => AnyService());
  }

  void good() {
    registerLazySingleton<AnyService>(() => AnyService());
    registerFactory<AnyController>(() => AnyController());
    registerRouteResolver<String>(() => Object());
  }
}

class NonModuleRegistrationCase {
  void allowedForNow() {
    // Non-ModuleContract classes are outside this rule scope.
    GetIt.I.registerLazySingleton<AnyService>(() => AnyService());
  }
}
