import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/application/router/guards/web_anonymous_fallback_guard.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/controllers/contact_group_management_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class InvitesModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<InviteFlowScreenController>(
      () => InviteFlowScreenController(),
    );
    registerLazySingleton<InviteShareScreenController>(
      () => InviteShareScreenController(),
    );
    registerLazySingleton<ContactGroupManagementController>(
      () => ContactGroupManagementController(),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/convites',
          page: InviteFlowRoute.page,
          guards: [
            TenantRouteGuard(),
            WebAnonymousFallbackGuard(
              allowAnonymousWeb: _allowAnonymousInvitePreview,
            ),
          ],
          meta: canonicalRouteMeta(family: CanonicalRouteFamily.inviteFlow),
        ),
        AutoRoute(
          path: '/invite',
          page: InviteEntryRoute.page,
          guards: [
            TenantRouteGuard(),
            WebAnonymousFallbackGuard(
              allowAnonymousWeb: _allowAnonymousInvitePreview,
            ),
          ],
          meta: canonicalRouteMeta(family: CanonicalRouteFamily.inviteEntry),
        ),
        AutoRoute(
          path: '/convites/compartilhar',
          page: InviteShareRoute.page,
          guards: [TenantRouteGuard(), AuthRouteGuard()],
          meta: canonicalRouteMeta(family: CanonicalRouteFamily.inviteShare),
        ),
        AutoRoute(
          path: '/convites/grupos',
          page: ContactGroupManagementRoute.page,
          guards: [TenantRouteGuard(), AuthRouteGuard()],
          meta: canonicalRouteMeta(family: CanonicalRouteFamily.inviteShare),
        ),
      ];

  static bool _allowAnonymousInvitePreview(RouteMatch route) {
    final code = route.queryParams.rawMap['code']?.toString().trim();
    return code != null && code.isNotEmpty;
  }

  @visibleForTesting
  static bool allowAnonymousInvitePreviewForTesting(RouteMatch route) {
    return _allowAnonymousInvitePreview(route);
  }
}
