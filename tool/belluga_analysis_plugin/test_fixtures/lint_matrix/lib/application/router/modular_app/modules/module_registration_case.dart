// ignore_for_file: unused_element

import 'package:get_it/get_it.dart';

abstract class ModuleContract {
  void registerLazySingleton<T extends Object>(T Function() builder) {}

  void registerFactory<T extends Object>(T Function() builder) {}

  void registerRouteResolver<TModel>(Object Function() factory) {}
}

class _AnyService {}

class _AnyController {}

abstract class _AnyRepositoryContract {}

class _AnyRepository implements _AnyRepositoryContract {}

class _ModuleRegistrationCase extends ModuleContract {
  void bad() {
    // expect_lint: module_direct_getit_registration_forbidden
    GetIt.I.registerLazySingleton<_AnyService>(() => _AnyService());

    // expect_lint: module_direct_getit_registration_forbidden
    GetIt.instance.registerFactory<_AnyService>(() => _AnyService());
  }

  void good() {
    registerLazySingleton<_AnyService>(() => _AnyService());
    registerFactory<_AnyController>(() => _AnyController());
    registerRouteResolver<String>(() => Object());
  }

  void repositoryScopeViolation() {
    // expect_lint: repository_registration_scope_enforced
    registerLazySingleton<_AnyRepositoryContract>(() => _AnyRepository());
  }
}

class _NonModuleRegistrationCase {
  void allowedForNow() {
    // Non-ModuleContract classes are outside this rule scope.
    GetIt.I.registerLazySingleton<_AnyService>(() => _AnyService());
  }
}
