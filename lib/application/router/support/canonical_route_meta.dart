import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:flutter/widgets.dart';

const canonicalRouteFamilyMetaKey = 'canonicalRouteFamily';
const canonicalRouteChromeMetaKey = 'canonicalRouteChromeMode';

Map<String, dynamic> canonicalRouteMeta({
  required CanonicalRouteFamily family,
  RouteChromeMode chromeMode = RouteChromeMode.standard,
}) {
  return <String, dynamic>{
    canonicalRouteFamilyMetaKey: family.name,
    canonicalRouteChromeMetaKey: chromeMode.name,
  };
}

CanonicalRouteFamily? resolveCanonicalRouteFamilyFromMeta(
  Map<String, dynamic> meta,
) {
  final raw = meta[canonicalRouteFamilyMetaKey];
  if (raw is CanonicalRouteFamily) {
    return raw;
  }
  if (raw is String) {
    return CanonicalRouteFamily.values.cast<CanonicalRouteFamily?>().firstWhere(
          (value) => value?.name == raw,
          orElse: () => null,
        );
  }
  return null;
}

RouteChromeMode? resolveRouteChromeModeFromMeta(Map<String, dynamic> meta) {
  final raw = meta[canonicalRouteChromeMetaKey];
  if (raw is RouteChromeMode) {
    return raw;
  }
  if (raw is String) {
    return RouteChromeMode.values.cast<RouteChromeMode?>().firstWhere(
          (value) => value?.name == raw,
          orElse: () => null,
        );
  }
  return null;
}

CanonicalRouteFamily? resolveCurrentCanonicalRouteFamily(BuildContext context) {
  try {
    return resolveCanonicalRouteFamilyFromMeta(context.topRoute.meta);
  } catch (_) {
    return null;
  }
}
