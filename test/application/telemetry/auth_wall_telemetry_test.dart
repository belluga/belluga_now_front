import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AuthWallTelemetry.resetForTesting);

  test('pending action replay is enabled by default', () {
    AuthWallTelemetry.trackTriggered(
      actionType: AuthWallActionType.favorite,
      redirectPath: '/parceiro/casa-marracini',
      payload: const <String, dynamic>{'partnerId': 'partner-1'},
    );

    final action = AuthWallTelemetry.consumePendingAction(
      '/parceiro/casa-marracini',
    );

    expect(action?.actionType, AuthWallActionType.favorite);
    expect(action?.payload?['partnerId'], 'partner-1');
  });

  test('web promotion handoff can record context without replaying mutation',
      () {
    AuthWallTelemetry.trackTriggered(
      actionType: AuthWallActionType.favorite,
      redirectPath: '/parceiro/casa-marracini',
      payload: const <String, dynamic>{'partnerId': 'partner-1'},
      allowPendingActionReplay: false,
    );

    final action = AuthWallTelemetry.consumePendingAction(
      '/parceiro/casa-marracini',
    );
    final signupProperties =
        AuthWallTelemetry.consumeSignupCompletedProperties();

    expect(action, isNull);
    expect(signupProperties['source'], AuthWallTelemetry.authWallSource);
    expect(signupProperties['action_type'], AuthWallActionType.favorite);
    expect(signupProperties['redirect_path'], '/parceiro/casa-marracini');
  });
}
