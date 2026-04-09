import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TenantPublicWebDesktopFrame extends StatelessWidget {
  const TenantPublicWebDesktopFrame({
    super.key,
    required this.child,
    required this.routeName,
    this.isWebRuntime = kIsWeb,
    this.maxContentWidth = _defaultMaxContentWidth,
  });

  static const double _defaultMaxContentWidth = 430.0;

  static const Set<String> _framedRouteNames = {
    TenantHomeRoute.name,
    DiscoveryRoute.name,
    PartnerDetailRoute.name,
    StaticAssetDetailRoute.name,
    EventSearchRoute.name,
    ImmersiveEventDetailRoute.name,
    InviteFlowRoute.name,
    InviteEntryRoute.name,
    InviteShareRoute.name,
    AppPromotionRoute.name,
    CityMapRoute.name,
    PoiDetailsRoute.name,
    LocationPermissionRoute.name,
    ProfileRoute.name,
  };

  final Widget child;
  final String? routeName;
  final bool isWebRuntime;
  final double maxContentWidth;

  static bool shouldFrameRoute(String? routeName) {
    if (routeName == null) {
      return false;
    }

    final normalizedRouteName = routeName.trim();
    if (normalizedRouteName.isEmpty) {
      return false;
    }

    return _framedRouteNames.contains(normalizedRouteName);
  }

  @override
  Widget build(BuildContext context) {
    if (!isWebRuntime || !shouldFrameRoute(routeName)) {
      return child;
    }

    final viewportWidth = MediaQuery.sizeOf(context).width;
    if (!viewportWidth.isFinite || viewportWidth <= maxContentWidth) {
      return child;
    }

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: child,
        ),
      ),
    );
  }
}
