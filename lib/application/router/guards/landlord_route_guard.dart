import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

class LandlordRouteGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final appData = GetIt.I.get<AppData>();
    final envType = appData.typeValue.value;

    String routeName = '';
    try {
      routeName = resolver.route.name;
    } catch (_) {
      routeName = '';
    }

    if (routeName == TenantAdminShellRoute.name) {
      if (envType == EnvironmentType.tenant) {
        resolver.next(true);
        return;
      }

      final landlordAuthRepository = GetIt.I.isRegistered<
              LandlordAuthRepositoryContract>()
          ? GetIt.I.get<LandlordAuthRepositoryContract>()
          : null;
      final hasValidSession = landlordAuthRepository?.hasValidSession ?? false;
      if (hasValidSession) {
        resolver.next(true);
      } else {
        resolver.next(false);
        router.replaceAll([const LandlordHomeRoute()]);
      }
      return;
    }

    final hostname = appData.hostname;
    final landlordHost = _resolveLandlordHost(BellugaConstants.landlordDomain);

    final isLandlordHost = landlordHost != null && hostname == landlordHost;
    final isLandlordEnv = envType == EnvironmentType.landlord;

    if (isLandlordHost || isLandlordEnv) {
      resolver.next(true);
      return;
    }

    // Tenant host must never access landlord routes (even deep links).
    resolver.next(false);
    router.replaceAll([const TenantHomeRoute()]);
  }

  String? _resolveLandlordHost(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }

    return trimmed;
  }
}
