import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:web/web.dart' as web;

AppPromotionStorePlatform? resolvePreferredWebPromotionStorePlatform() {
  final navigator = web.window.navigator;
  final userAgent = navigator.userAgent.toLowerCase();
  final platform = navigator.platform.toLowerCase();
  final maxTouchPoints = navigator.maxTouchPoints;

  if (userAgent.contains('android')) {
    return AppPromotionStorePlatform.android;
  }

  final isIosUserAgent = userAgent.contains('iphone') ||
      userAgent.contains('ipad') ||
      userAgent.contains('ipod');
  final isIpadOsDesktopMode =
      platform.contains('mac') && maxTouchPoints > 1;
  if (isIosUserAgent || isIpadOsDesktopMode) {
    return AppPromotionStorePlatform.ios;
  }

  return null;
}
