import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/application/telemetry/web_promotion_telemetry.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/app_promotion_screen/controllers/app_promotion_web_store_platform_resolver_stub.dart'
    if (dart.library.html) '../screens/app_promotion_screen/controllers/app_promotion_web_store_platform_resolver_web.dart'
    as web_store_platform;

typedef WebInstalledAppHandoffLauncher = Future<bool> Function(Uri uri);
typedef WebPromotionFallbackNavigator = void Function(
  BuildContext context,
  String redirectPath,
);

void launchWebInstalledAppHandoffOrPromotion({
  required BuildContext context,
  required String redirectPath,
  String? actionType,
  Map<String, dynamic>? payload,
  AppPromotionStorePlatform? preferredStorePlatform,
  Uri? canonicalWebOriginUri,
  WebInstalledAppHandoffLauncher? launcher,
  WebPromotionFallbackNavigator? fallbackNavigator,
}) {
  final normalizedRedirectPath =
      redirectPath.trim().isEmpty ? '/' : redirectPath.trim();
  if (actionType != null && actionType.trim().isNotEmpty) {
    AuthWallTelemetry.trackTriggered(
      actionType: actionType,
      redirectPath: normalizedRedirectPath,
      payload: payload,
      allowPendingActionReplay: false,
    );
  }

  final pushFallback = fallbackNavigator ?? _pushPromotionBoundary;
  if (!kIsWeb) {
    pushFallback(context, normalizedRedirectPath);
    return;
  }

  final preferred = preferredStorePlatform ??
      web_store_platform.resolvePreferredWebPromotionStorePlatform();
  if (preferred != AppPromotionStorePlatform.android) {
    pushFallback(context, normalizedRedirectPath);
    return;
  }
  const platformTarget = AppPromotionStorePlatform.android;

  final uri = buildWebInstalledAppHandoffUri(
    redirectPath: normalizedRedirectPath,
    platformTarget: platformTarget.platformTarget,
    canonicalWebOriginUri: canonicalWebOriginUri,
  );
  if (uri == null) {
    pushFallback(context, normalizedRedirectPath);
    return;
  }

  unawaited(
    WebPromotionTelemetry.trackOpenAppClick(
      platformTarget: platformTarget.platformTarget,
    ),
  );
  unawaited((launcher ?? _launchExternal)(uri));
}

Uri? buildWebInstalledAppHandoffUri({
  required String redirectPath,
  required String platformTarget,
  Uri? canonicalWebOriginUri,
}) {
  if (canonicalWebOriginUri != null) {
    return buildTenantPromotionUriFromAppContext(
      redirectPath: redirectPath,
      platformTarget: platformTarget,
      mainDomainUri: canonicalWebOriginUri,
      fallbackToPromotionBoundary: true,
    );
  }

  return buildTenantPromotionUriFromCanonicalWebContext(
    redirectPath: redirectPath,
    platformTarget: platformTarget,
    fallbackToPromotionBoundary: true,
  );
}

Future<bool> _launchExternal(Uri uri) {
  return launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
}

void _pushPromotionBoundary(BuildContext context, String redirectPath) {
  try {
    context.router.pushPath(
      buildWebPromotionBoundaryPath(
        redirectPath: redirectPath,
      ),
    );
  } catch (_) {
    // Some widget tests render action surfaces without a router.
  }
}
