import 'package:get_it/get_it.dart';

class AccountProfileDetailController {}

class RouteInstanceScope {
  static T get<T extends Object>(Object context) {
    throw UnimplementedError();
  }
}

class AccountProfileDetailScreen {
  void badControllerLookup() {
    // expect_lint: route_scoped_detail_controller_getit_forbidden
    GetIt.I.get<AccountProfileDetailController>();
  }

  void goodControllerLookup(Object context) {
    RouteInstanceScope.get<AccountProfileDetailController>(context);
  }
}
