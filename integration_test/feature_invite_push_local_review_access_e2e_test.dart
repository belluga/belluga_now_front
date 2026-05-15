import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';

const _disablePush = bool.fromEnvironment('DISABLE_PUSH', defaultValue: false);
const _reviewPhone = String.fromEnvironment(
  'E2E_REVIEW_PHONE',
  defaultValue: '+5527998869802',
);
const _reviewCode = String.fromEnvironment(
  'E2E_REVIEW_CODE',
  defaultValue: '123456',
);
const _expectedUserId = String.fromEnvironment(
  'E2E_EXPECTED_USER_ID',
  defaultValue: '69ff77d3585e33100c0fe5ef',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  testWidgets(
    'review-access login reflects a real direct invite and updates the home banner in foreground',
    (tester) async {
      expect(
        _disablePush,
        isFalse,
        reason:
            'This E2E must run with FLUTTER_INTEGRATION_DISABLE_PUSH=false.',
      );

      await _clearIdentityStorage();
      await GetIt.I.reset();

      final app = Application();
      GetIt.I.registerSingleton<ApplicationContract>(app);

      await app.init();
      await tester.pumpWidget(app);
      await _pumpFor(tester, const Duration(seconds: 2));

      final authRepository = GetIt.I.get<AuthRepositoryContract>();
      await _performRepositoryReviewAccessLogin(authRepository);
      await _waitForAuthorizedUser(authRepository);

      final userId = (await authRepository.getUserId())?.trim() ?? '';
      expect(userId, isNotEmpty, reason: 'Authenticated user id is required.');
      if (_expectedUserId.trim().isNotEmpty) {
        expect(
          userId,
          _expectedUserId,
          reason: 'The local review-access login must bind to the seeded '
              'recipient identity used by the backend invite smoke flow.',
        );
      }

      app.appRouter.replaceAll([const TenantHomeRoute()]);
      await _pumpFor(tester, const Duration(seconds: 2));
      await _dismissLocationGateIfNeeded(tester);

      final invitesRepository = GetIt.I.get<InvitesRepositoryContract>();
      await invitesRepository.init();

      final beforeInvites = invitesRepository.pendingInvitesStreamValue.value;
      final beforeTargetKeys = beforeInvites.map(_targetKey).toSet();
      final expectedAfterCount = beforeInvites.length + 1;
      debugPrint(
        'INVITE_PUSH_LOCAL_E2E_READY user_id=$userId '
        'authorized=${authRepository.isAuthorized} '
        'pending_before=${beforeInvites.length}',
      );

      final reflected = await _waitForNewInvite(
        tester: tester,
        invitesRepository: invitesRepository,
        beforeTargetKeys: beforeTargetKeys,
        timeout: const Duration(minutes: 3),
      );

      await _waitForBannerText(
        tester,
        'Voce tem $expectedAfterCount convites pendentes',
      );

      final afterInvites = invitesRepository.pendingInvitesStreamValue.value;
      expect(
        afterInvites
            .any((invite) => _targetKey(invite) == _targetKey(reflected)),
        isTrue,
      );
      expect(afterInvites.length, expectedAfterCount);

      debugPrint(
        'INVITE_PUSH_LOCAL_E2E_REFLECTED '
        'invite_id=${reflected.id} '
        'event_id=${reflected.eventId} '
        'occurrence_id=${reflected.occurrenceId ?? ''} '
        'pending_after=${afterInvites.length}',
      );
    },
    skip: _disablePush,
  );
}

Future<void> _clearIdentityStorage() async {
  await AuthRepository.storage.delete(key: 'user_token');
  await AuthRepository.storage.delete(key: 'user_id');
  await AuthRepository.storage.delete(key: 'device_id');
}

Future<void> _performRepositoryReviewAccessLogin(
  AuthRepositoryContract authRepository,
) async {
  expect(
    _reviewPhone.trim(),
    isNotEmpty,
    reason:
        'E2E_REVIEW_PHONE must be configured for local phone OTP review access.',
  );
  expect(
    _reviewCode.trim(),
    isNotEmpty,
    reason:
        'E2E_REVIEW_CODE must be configured for local phone OTP review access.',
  );

  final challenge = await authRepository.requestPhoneOtpChallenge(
    authRepoString(_reviewPhone),
  );
  final challengeId = challenge.challengeIdValue.value.trim();
  expect(
    challengeId,
    isNotEmpty,
    reason: 'Review-access OTP challenge must return a challenge_id.',
  );
  await authRepository.verifyPhoneOtpChallenge(
    challengeId: authRepoString(challengeId),
    phone: authRepoString(_reviewPhone),
    code: authRepoString(_reviewCode),
  );
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final endAt = DateTime.now().add(duration);
  while (DateTime.now().isBefore(endAt)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _waitForAuthorizedUser(
  AuthRepositoryContract authRepository, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final endAt = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endAt)) {
    final userId = (await authRepository.getUserId())?.trim() ?? '';
    if (authRepository.isAuthorized && userId.isNotEmpty) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  fail('Timed out waiting for review-access authentication.');
}

Future<void> _dismissLocationGateIfNeeded(WidgetTester tester) async {
  final allowButton = find.text('Permitir localização');
  if (await _waitForMaybeFinder(tester, allowButton)) {
    await tester.tap(allowButton.first);
    await _pumpFor(tester, const Duration(seconds: 2));
  }

  final continueButton = find.text('Continuar sem localização ao vivo');
  if (await _waitForMaybeFinder(tester, continueButton)) {
    await tester.tap(continueButton.first);
    await _pumpFor(tester, const Duration(seconds: 1));
  }

  final notNowButton = find.text('Agora não');
  if (await _waitForMaybeFinder(tester, notNowButton)) {
    await tester.tap(notNowButton.first);
    await _pumpFor(tester, const Duration(seconds: 1));
  }
}

Future<bool> _waitForMaybeFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 300),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

Future<void> _waitForBannerText(
  WidgetTester tester,
  String expectedText, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final finder = find.text(expectedText, skipOffstage: false);
  final endAt = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endAt)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Timed out waiting for invites banner text: $expectedText');
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
