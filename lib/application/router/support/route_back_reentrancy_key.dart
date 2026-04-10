import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

String resolveRouteBackReentrancyKey(
  BuildContext context, {
  required String fallbackRouteName,
}) {
  try {
    return context.topRoute.name;
  } catch (_) {
    return fallbackRouteName;
  }
}
