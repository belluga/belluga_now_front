import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_group.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_account_profile_ids.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_name_value.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/controllers/contact_group_management_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/contact_group_management_screen.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset(dispose: false);
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
  });

  testWidgets('creates contact group from dedicated management screen',
      (tester) async {
    final repository = _FakeInvitesRepository();
    final controller = ContactGroupManagementController(
      invitesRepository: repository,
    );
    GetIt.I.registerSingleton<ContactGroupManagementController>(controller);
    addTearDown(controller.onDispose);

    await tester.pumpWidget(
      MaterialApp(
        home: const ContactGroupManagementScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grupos de contatos'), findsOneWidget);
    expect(find.text('Rolê'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Tribo');
    await tester.tap(find.text('Ana'));
    await tester.tap(find.text('Criar grupo'));
    await tester.pumpAndSettle();

    expect(repository.createdNames, ['Tribo']);
    expect(repository.createdMemberIds.single, ['profile-1']);
    expect(find.text('Tribo'), findsOneWidget);

    await tester.tap(find.byTooltip('Renomear').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Rolê editado');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repository.renamedNames, ['Rolê editado']);
    expect(find.text('Rolê editado'), findsOneWidget);
    expect(find.text('Rolê'), findsNothing);

    await tester.tap(find.byTooltip('Editar membros').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Bia').last);
    await tester.tap(find.text('Salvar membros'));
    await tester.pumpAndSettle();

    expect(repository.updatedMemberIds.single, ['profile-1', 'profile-2']);
    expect(find.text('2 contato(s)'), findsOneWidget);

    await tester.tap(find.byTooltip('Excluir').first);
    await tester.pumpAndSettle();

    expect(repository.deletedGroupIds, ['group-1']);
    expect(find.text('Rolê editado'), findsNothing);
  });
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  final createdNames = <String>[];
  final createdMemberIds = <List<String>>[];
  final renamedNames = <String>[];
  final updatedMemberIds = <List<String>>[];
  final deletedGroupIds = <String>[];
  final groups = <InviteContactGroup>[
    buildInviteContactGroup(
      id: 'group-1',
      name: 'Rolê',
      recipientAccountProfileIds: const ['profile-1'],
    ),
  ];

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() async => [
        buildInviteableRecipient(
          userId: 'user-1',
          accountProfileId: 'profile-1',
          displayName: 'Ana',
        ),
        buildInviteableRecipient(
          userId: 'user-2',
          accountProfileId: 'profile-2',
          displayName: 'Bia',
        ),
      ];

  @override
  Future<List<InviteContactGroup>> fetchContactGroups() async =>
      List<InviteContactGroup>.of(groups);

  @override
  Future<InviteContactGroup?> createContactGroup({
    required InviteContactGroupNameValue nameValue,
    required InviteAccountProfileIds recipientAccountProfileIds,
  }) async {
    final name = nameValue.value;
    final memberIds = recipientAccountProfileIds.toList(growable: false);
    createdNames.add(name);
    createdMemberIds.add(memberIds);
    final group = buildInviteContactGroup(
      id: 'group-created',
      name: name,
      recipientAccountProfileIds: memberIds,
    );
    groups.add(group);

    return group;
  }

  @override
  Future<InviteContactGroup?> updateContactGroup({
    required InviteContactGroupIdValue groupIdValue,
    InviteContactGroupNameValue? nameValue,
    InviteAccountProfileIds? recipientAccountProfileIds,
  }) async {
    final groupId = groupIdValue.value;
    final name = nameValue?.value;
    final memberIds = recipientAccountProfileIds?.toList(growable: false);
    if (name != null) {
      renamedNames.add(name);
    }
    if (memberIds != null) {
      updatedMemberIds.add(memberIds);
    }
    final existingIndex = groups.indexWhere((group) => group.id == groupId);
    final current = existingIndex >= 0 ? groups[existingIndex] : null;
    final updated = buildInviteContactGroup(
      id: groupId,
      name: name ?? current?.name ?? 'Grupo',
      recipientAccountProfileIds: memberIds ??
          current?.recipientAccountProfileIds.toList(growable: false) ??
          const <String>[],
    );
    if (existingIndex >= 0) {
      groups[existingIndex] = updated;
    }

    return updated;
  }

  @override
  Future<void> deleteContactGroup(
      InviteContactGroupIdValue groupIdValue) async {
    final groupId = groupIdValue.value;
    deletedGroupIds.add(groupId);
    groups.removeWhere((group) => group.id == groupId);
  }

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async =>
      const <InviteModel>[];

  @override
  Future<InviteRuntimeSettings> fetchSettings() => throw UnimplementedError();

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) =>
      throw UnimplementedError();

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) =>
      throw UnimplementedError();

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) =>
      throw UnimplementedError();

  @override
  Future<InviteMaterializeResult> materializeShareCode(
    InvitesRepositoryContractPrimString code,
  ) =>
      throw UnimplementedError();

  @override
  Future<List<InviteContactMatch>> importContacts(InviteContacts contacts) =>
      throw UnimplementedError();

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
    InvitesRepositoryContractPrimString eventId,
  ) =>
      throw UnimplementedError();
}
