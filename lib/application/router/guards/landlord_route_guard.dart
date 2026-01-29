import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

class LandlordRouteGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final appData = GetIt.I.get<AppData>();
    final envType = appData.typeValue.value;
    final hostname = appData.hostname;

    final isLandlordHost = hostname == BellugaConstants.landlordDomain;
    final isLandlordEnv = envType == EnvironmentType.landlord;
    final hasLandlordSession =
        GetIt.I.isRegistered<LandlordAuthRepositoryContract>() &&
            GetIt.I.get<LandlordAuthRepositoryContract>().hasValidSession;
    final isLandlordMode =
        GetIt.I.isRegistered<AdminModeRepositoryContract>() &&
            GetIt.I.get<AdminModeRepositoryContract>().isLandlordMode;

    if (isLandlordHost || isLandlordEnv || (hasLandlordSession && isLandlordMode)) {
      resolver.next(true);
      return;
    }

    // Tenant host must never access landlord routes (even deep links).
    resolver.next(false);
    router.replaceAll([const TenantHomeRoute()]);
  }
}
