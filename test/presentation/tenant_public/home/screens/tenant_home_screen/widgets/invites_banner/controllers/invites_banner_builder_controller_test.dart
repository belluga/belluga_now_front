import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/invites_banner/controllers/invites_banner_builder_controller.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home banner hides stale cached invites until backend revalidates empty',
      () async {
    final repository = _FakeInvitesRepository();
    repository.pendingInvitesStreamValue.addValue([_buildInvite('stale-1')]);
    repository.fetchInvitesResult = const <InviteModel>[];
    final controller = InvitesBannerBuilderController(
      invitesRepository: repository,
    );

    controller.init();

    expect(controller.isPendingInvitesDisplayReadyStreamValue.value, isFalse);
    expect(controller.hasPendingInvites, isFalse);
    await Future<void>.delayed(Duration.zero);

    expect(repository.fetchInvitesCalls, 1);
    expect(controller.isPendingInvitesDisplayReadyStreamValue.value, isTrue);
    expect(repository.pendingInvitesStreamValue.value, isEmpty);
    expect(controller.pendingInvitesStreamValue.value, isEmpty);
    expect(controller.hasPendingInvites, isFalse);

    controller.onDispose();
  });

  test('home banner displays pending invites after backend revalidation',
      () async {
    final repository = _FakeInvitesRepository();
    final invite = _buildInvite('fresh-1');
    repository.pendingInvitesStreamValue.addValue([_buildInvite('stale-1')]);
    repository.fetchInvitesResult = [invite];
    final controller = InvitesBannerBuilderController(
      invitesRepository: repository,
    );

    controller.init();

    expect(controller.isPendingInvitesDisplayReadyStreamValue.value, isFalse);
    expect(controller.hasPendingInvites, isFalse);
    await Future<void>.delayed(Duration.zero);

    expect(repository.fetchInvitesCalls, 1);
    expect(controller.isPendingInvitesDisplayReadyStreamValue.value, isTrue);
    expect(controller.pendingInvitesStreamValue.value, [invite]);
    expect(controller.hasPendingInvites, isTrue);

    controller.onDispose();
  });
}

InviteModel _buildInvite(String id) {
  return buildInviteModelFromPrimitives(
    id: id,
    eventId: 'event-$id',
    occurrenceId: 'occurrence-$id',
    eventName: 'Evento $id',
    eventDateTime: DateTime(2026, 3, 16, 20),
    eventImageUrl: 'http://example.com/$id.jpg',
    location: 'Guarapari',
    hostName: 'Host',
    message: 'Convite pendente',
    tags: const ['music'],
    inviterName: 'Convidador',
  );
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  int fetchInvitesCalls = 0;
  List<InviteModel> fetchInvitesResult = const <InviteModel>[];

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async {
    fetchInvitesCalls += 1;
    return fetchInvitesResult;
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    return buildInviteRuntimeSettings();
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString occurrenceId,
  ) async {
    return const <SentInviteStatus>[];
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async {
    return const <InviteContactMatch>[];
  }

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}
}
