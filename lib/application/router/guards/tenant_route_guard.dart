import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

class TenantRouteGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final appData = GetIt.I.get<AppData>();
    final envType = appData.typeValue.value;

    // The `/api/v1/environment` bootstrap (main domain) is the source of truth for web tenant routing.
    if (envType == EnvironmentType.tenant) {
      resolver.next(true);
      return;
    }

    // Landlord host must never access tenant routes (even deep links).
    String attemptedPath = '';
    try {
      attemptedPath = resolver.route.fullPath;
    } catch (_) {
      attemptedPath = '';
    }

    resolver.next(false);
    router.replaceAll([_resolveLandlordInitialRoute(attemptedPath)]);
  }

  PageRouteInfo _resolveLandlordInitialRoute(String attemptedPath) {
    if (_isHistoricalTenantHomePath(attemptedPath) ||
        _isHistoricalLandlordPath(attemptedPath)) {
      return const TenantAdminShellRoute();
    }

    if (!GetIt.I.isRegistered<AdminModeRepositoryContract>() ||
        !GetIt.I.isRegistered<LandlordAuthRepositoryContract>()) {
      return const LandlordHomeRoute();
    }

    final modeRepository = GetIt.I.get<AdminModeRepositoryContract>();
    final landlordAuthRepository =
        GetIt.I.get<LandlordAuthRepositoryContract>();
    final shouldOpenAdminDirectly =
        modeRepository.isLandlordMode && landlordAuthRepository.hasValidSession;

    if (shouldOpenAdminDirectly) {
      return const TenantAdminShellRoute();
    }

    return const LandlordHomeRoute();
  }

  bool _isHistoricalTenantHomePath(String attemptedPath) {
    final path = attemptedPath.trim();
    return path == 'home' || path == '/home';
  }

  bool _isHistoricalLandlordPath(String attemptedPath) {
    final path = attemptedPath.trim();
    return path == 'landlord' || path == '/landlord';
  }
}
