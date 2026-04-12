import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/application/router/guards/web_anonymous_promotion_guard.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/create_password_controller_contract.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/remember_password_contract.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/recovery_password_token_controller_contract.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_create_new_password_screen/controllers/create_password_controller.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/controllers/auth_login_controller.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/controllers/remember_password_controller.dart';
import 'package:belluga_now/presentation/shared/auth/screens/recovery_password_bug/controllers/recovery_password_token_controller.dart';
import 'package:belluga_now/presentation/landlord_area/auth/controllers/auth_login_landlord_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class AuthModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<AuthLoginControllerContract>(
      () => AuthLoginController(),
    );
    registerLazySingleton<RememberPasswordContract>(
      () => RememberPasswordController(),
    );

    registerFactory<CreatePasswordControllerContract>(
      () => CreatePasswordController(),
    );

    registerLazySingleton<AuthRecoveryPasswordControllerContract>(
      () => AuthRecoveryPasswordController(),
    );

    registerLazySingleton<AuthLoginLandlordController>(
      () => AuthLoginLandlordController(),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/auth/login',
          page: AuthLoginRoute.page,
          guards: [TenantRouteGuard(), WebAnonymousPromotionGuard()],
          meta: canonicalRouteMeta(family: CanonicalRouteFamily.authLogin),
        ),
        AutoRoute(
          path: '/auth/recover_password',
          page: RecoveryPasswordRoute.page,
          guards: [TenantRouteGuard(), WebAnonymousPromotionGuard()],
          meta: canonicalRouteMeta(
            family: CanonicalRouteFamily.recoveryPassword,
          ),
        ),
        AutoRoute(
          path: '/auth/create-password',
          page: AuthCreateNewPasswordRoute.page,
          guards: [TenantRouteGuard(), AuthRouteGuard()],
          meta: canonicalRouteMeta(
            family: CanonicalRouteFamily.authCreateNewPassword,
          ),
        ),
      ];
}
