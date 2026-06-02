import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/widgets/app_promotion_modal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

final class AccountProfileFavoriteAuthGate {
  AccountProfileFavoriteAuthGate._();

  static Future<void> handleRequiredAuthentication({
    required BuildContext context,
    required String accountProfileId,
    required String redirectPath,
    bool isWebRuntime = kIsWeb,
  }) async {
    final payload = {'partnerId': accountProfileId};

    if (isWebRuntime) {
      AuthWallTelemetry.trackTriggered(
        actionType: AuthWallActionType.favorite,
        redirectPath: redirectPath,
        payload: payload,
        allowPendingActionReplay: false,
      );
      await AppPromotionModal.show(
        context,
        redirectPath: redirectPath,
      );
      return;
    }

    AuthWallTelemetry.trackTriggered(
      actionType: AuthWallActionType.favorite,
      redirectPath: redirectPath,
      payload: payload,
      allowPendingActionReplay: true,
    );

    final encodedRedirect = Uri.encodeQueryComponent(redirectPath);
    await context.router.replacePath('/auth/login?redirect=$encodedRedirect');
  }
}
