import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/integration_test_bootstrap.dart';
import '../../integration_test/support/stage_invite_test_support.dart';

@Tags(<String>['stage-compatibility'])
void main() {
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();
  const stageTimeout = Timeout(Duration(minutes: 10));

  if (!StageInviteTestSupport.isConfigured) {
    test(
      'Stage invite compatibility suite requires explicit stage configuration',
      () async {},
      skip: true,
      timeout: stageTimeout,
    );
    return;
  }

  StageInviteTestSupport.ensureConfigured();

  setUpAll(() {
    StageInviteTestSupport.installHttpOverridesIfNeeded();
  });

  tearDownAll(() {
    StageInviteTestSupport.restoreHttpOverrides();
  });

  late StageInviteSupportClient supportClient;
  StageInviteFixture? activeFixture;

  tearDown(() async {
    try {
      if (activeFixture != null) {
        await supportClient.cleanup(activeFixture!.runId);
      }
    } finally {
      activeFixture = null;
      await resetStageInviteRuntime();
    }
  });

  setUp(() {
    supportClient = StageInviteSupportClient();
  });

  test(
    'Stage accept flow materializes canonical invite and supersedes competing pending invite',
    () async {
      activeFixture = await supportClient.bootstrap(scenario: 'accept_pending');
      final runtime = await createStageInviteRuntime();

      await runtime.authRepository.loginWithEmailPassword(
        activeFixture!.inviteeEmail,
        activeFixture!.inviteePassword,
      );

      final preview = await runtime.invitesRepository.previewShareCode(
        activeFixture!.shareCode,
      );
      expect(preview, isNotNull);
      expect(preview!.eventId, activeFixture!.eventId);

      final materialized = await runtime.invitesRepository.materializeShareCode(
        activeFixture!.shareCode,
      );
      expect(materialized.isPending, isTrue);
      expect(materialized.inviteId, isNotEmpty);

      final accepted = await runtime.invitesRepository.acceptInvite(
        materialized.inviteId,
      );
      expect(accepted.isAccepted, isTrue);
      expect(accepted.creditedAcceptance, isTrue);
      expect(accepted.supersededInviteIds, isNotEmpty);

      final state = await supportClient.state(activeFixture!.runId);
      expect(state.invites.length, 2);
      expect(
        state.invites.where((invite) => invite.status == 'accepted').length,
        1,
      );
      expect(
        state.invites
            .where(
              (invite) =>
                  invite.status == 'superseded' &&
                  invite.supersessionReason == 'other_invite_credited',
            )
            .length,
        1,
      );
    },
    timeout: stageTimeout,
  );

  test(
    'Stage decline flow keeps competing invite pending after canonical decline',
    () async {
      activeFixture =
          await supportClient.bootstrap(scenario: 'decline_pending');
      final runtime = await createStageInviteRuntime();

      await runtime.authRepository.loginWithEmailPassword(
        activeFixture!.inviteeEmail,
        activeFixture!.inviteePassword,
      );

      final materialized = await runtime.invitesRepository.materializeShareCode(
        activeFixture!.shareCode,
      );
      expect(materialized.isPending, isTrue);

      final declined = await runtime.invitesRepository.declineInvite(
        materialized.inviteId,
      );
      expect(declined.status, 'declined');
      expect(declined.groupHasOtherPending, isTrue);

      final state = await supportClient.state(activeFixture!.runId);
      expect(state.invites.length, 2);
      expect(
        state.invites.where((invite) => invite.status == 'declined').length,
        1,
      );
      expect(
        state.invites.where((invite) => invite.status == 'pending').length,
        1,
      );
    },
    timeout: stageTimeout,
  );

  test(
    'Stage direct confirmation supersedes materialized invite without credited acceptance',
    () async {
      activeFixture = await supportClient.bootstrap(
        scenario: 'direct_confirmation_superseded',
      );
      final runtime = await createStageInviteRuntime();

      await runtime.authRepository.loginWithEmailPassword(
        activeFixture!.inviteeEmail,
        activeFixture!.inviteePassword,
      );

      final materialized = await runtime.invitesRepository.materializeShareCode(
        activeFixture!.shareCode,
      );
      expect(materialized.isPending, isTrue);

      await runtime.userEventsRepository.confirmEventAttendance(
        activeFixture!.eventId,
      );

      final state = await supportClient.state(activeFixture!.runId);
      expect(state.invites.length, 1);
      expect(state.invites.single.status, 'superseded');
      expect(
        state.invites.single.supersessionReason,
        'direct_confirmation',
      );
      expect(state.invites.single.creditedAcceptance, isFalse);
      expect(state.attendance, isNotNull);
      expect(state.attendance!.status, 'active');
      expect(state.attendance!.kind, 'free_confirmation');
    },
    timeout: stageTimeout,
  );

  test(
    'Stage expired share preview is rejected by the live backend contract',
    () async {
      activeFixture = await supportClient.bootstrap(scenario: 'expired_share');
      final runtime = await createStageInviteRuntime();

      await expectLater(
        runtime.invitesRepository.previewShareCode(activeFixture!.shareCode),
        throwsA(isA<Object>()),
      );
    },
    timeout: stageTimeout,
  );
}
