import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/invite_account_profile_ids.dart';
import 'package:belluga_now/domain/invites/invite_contact_group.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_name_value.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/controllers/contact_group_management_controller.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads inviteables and executes contact group CRUD', () async {
    final repository = _FakeInvitesRepository();
    final controller = ContactGroupManagementController(
      invitesRepository: repository,
    );

    await controller.init();

    expect(controller.inviteableRecipientsStreamValue.value, hasLength(2));
    expect(controller.groupsStreamValue.value.single.name, 'Rolê');

    await controller.createGroup(
      name: 'Amigos',
      recipientAccountProfileIds: ['profile-1'],
    );
    expect(
      controller.groupsStreamValue.value.map((group) => group.name),
      contains('Amigos'),
    );

    final createdGroup = controller.groupsStreamValue.value.firstWhere(
      (group) => group.name == 'Amigos',
    );
    await controller.renameGroup(
      group: createdGroup,
      name: 'Amigos próximos',
    );
    expect(
      controller.groupsStreamValue.value.map((group) => group.name),
      contains('Amigos próximos'),
    );

    final renamedGroup = controller.groupsStreamValue.value.firstWhere(
      (group) => group.name == 'Amigos próximos',
    );
    await controller.updateGroupMembers(
      group: renamedGroup,
      recipientAccountProfileIds: ['profile-1', 'profile-2'],
    );
    expect(
      controller.groupsStreamValue.value
          .firstWhere((group) => group.id == renamedGroup.id)
          .recipientAccountProfileIds,
      ['profile-1', 'profile-2'],
    );

    await controller.deleteGroup(renamedGroup);
    expect(
      controller.groupsStreamValue.value.map((group) => group.id),
      isNot(contains(renamedGroup.id)),
    );

    expect(repository.createdNames, ['Amigos']);
    expect(repository.renamedNames, ['Amigos próximos']);
    expect(repository.updatedMemberIds.single, ['profile-1', 'profile-2']);
    expect(repository.deletedGroupIds, ['group-created']);

    await controller.onDispose();
  });
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  final inviteables = <InviteableRecipient>[
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

  final groups = <InviteContactGroup>[
    buildInviteContactGroup(
      id: 'group-1',
      name: 'Rolê',
      recipientAccountProfileIds: const ['profile-1'],
    ),
  ];

  final createdNames = <String>[];
  final renamedNames = <String>[];
  final updatedMemberIds = <List<String>>[];
  final deletedGroupIds = <String>[];

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() async =>
      inviteables;

  @override
  Future<List<InviteContactGroup>> fetchContactGroups() async =>
      List<InviteContactGroup>.of(groups);

  @override
  Future<InviteContactGroup?> createContactGroup({
    required InviteContactGroupNameValue nameValue,
    required InviteAccountProfileIds recipientAccountProfileIds,
  }) async {
    final name = nameValue.value;
    createdNames.add(name);
    final group = buildInviteContactGroup(
      id: 'group-created',
      name: name,
      recipientAccountProfileIds: recipientAccountProfileIds.toList(
        growable: false,
      ),
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
      name: name ?? current?.name ?? 'Rolê',
      recipientAccountProfileIds: memberIds ??
          current?.recipientAccountProfileIds.toList(growable: false) ??
          ['profile-1'],
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
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString eventId,
  ) =>
      throw UnimplementedError();
}
