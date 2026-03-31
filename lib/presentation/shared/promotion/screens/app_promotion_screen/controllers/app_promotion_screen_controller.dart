import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/telemetry/web_promotion_telemetry.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

class AppPromotionScreenController implements Disposable {
  String normalizeRedirectPath(String? rawRedirectPath) {
    final normalized = rawRedirectPath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '/';
    }
    return normalized;
  }

  Uri? buildAndroidPromotionUri({
    required String redirectPath,
  }) {
    return buildTenantPromotionUriFromAppContext(
      redirectPath: normalizeRedirectPath(redirectPath),
      platformTarget: 'android',
    );
  }

  Uri? buildIosPromotionUri({
    required String redirectPath,
  }) {
    return buildTenantPromotionUriFromAppContext(
      redirectPath: normalizeRedirectPath(redirectPath),
      platformTarget: 'ios',
    );
  }

  Future<void> launchPromotionUri({
    required Uri uri,
    required String platformTarget,
  }) async {
    await WebPromotionTelemetry.trackOpenAppClick(
      platformTarget: platformTarget,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void onDispose() {}
}
