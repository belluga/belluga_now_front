import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';

const _disablePush = bool.fromEnvironment('DISABLE_PUSH', defaultValue: false);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  testWidgets(
    'foreground app reflects a real direct invite received by FCM',
    (tester) async {
      expect(
        _disablePush,
        isFalse,
        reason:
            'This E2E must run with FLUTTER_INTEGRATION_DISABLE_PUSH=false.',
      );

      await GetIt.I.reset();

      final app = Application();
      GetIt.I.registerSingleton<ApplicationContract>(app);

      await app.init();
      await tester.pumpWidget(app);
      await _pumpFor(tester, const Duration(seconds: 2));

      final authRepository = GetIt.I.get<AuthRepositoryContract>();
      final userId = (await authRepository.getUserId())?.trim() ?? '';
      expect(
        userId,
        isNotEmpty,
        reason: 'The device must keep an existing tenant-public identity.',
      );
      expect(
        authRepository.userToken.trim(),
        isNotEmpty,
        reason: 'The integration runner must preserve app data; do not reset.',
      );

      final invitesRepository = GetIt.I.get<InvitesRepositoryContract>();
      await invitesRepository.init();

      final beforeInvites = invitesRepository.pendingInvitesStreamValue.value;
      final beforeTargetKeys = beforeInvites.map(_targetKey).toSet();
      debugPrint(
        'INVITE_PUSH_E2E_READY user_id=$userId '
        'authorized=${authRepository.isAuthorized} '
        'pending_before=${beforeInvites.length}',
      );

      final reflected = await _waitForNewInvite(
        tester: tester,
        invitesRepository: invitesRepository,
        beforeTargetKeys: beforeTargetKeys,
        timeout: const Duration(minutes: 3),
      );

      debugPrint(
        'INVITE_PUSH_E2E_REFLECTED '
        'invite_id=${reflected.id} '
        'event_id=${reflected.eventId} '
        'occurrence_id=${reflected.occurrenceId ?? ''} '
        'pending_after=${invitesRepository.pendingInvitesStreamValue.value.length}',
      );
    },
    skip: _disablePush,
  );
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final endAt = DateTime.now().add(duration);
  while (DateTime.now().isBefore(endAt)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<InviteModel> _waitForNewInvite({
  required WidgetTester tester,
  required InvitesRepositoryContract invitesRepository,
  required Set<String> beforeTargetKeys,
  required Duration timeout,
}) async {
  final endAt = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endAt)) {
    await tester.pump(const Duration(milliseconds: 500));
    final current = invitesRepository.pendingInvitesStreamValue.value;
    for (final invite in current) {
      if (!beforeTargetKeys.contains(_targetKey(invite))) {
        return invite;
      }
    }
  }

  fail(
    'Timed out waiting for a new invite pushed into pendingInvitesStreamValue.',
  );
}

String _targetKey(InviteModel invite) {
  return '${invite.eventId}:${invite.occurrenceId ?? ''}';
}
