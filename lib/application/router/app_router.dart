import 'package:auto_route/auto_route.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@AutoRouterConfig()
class AppRouter extends AppRouterContract {
  @override
  List<AutoRoute> get routes => [
        ...childModules.expand((module) => module.routes),
      ];
}
