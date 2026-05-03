import 'dart:async';

import 'package:belluga_now/domain/invites/invite_account_profile_ids.dart';
import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/invite_contact_group.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_name_value.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ContactGroupManagementController with Disposable {
  ContactGroupManagementController({
    InvitesRepositoryContract? invitesRepository,
  }) : _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>();

  final InvitesRepositoryContract _invitesRepository;

  final groupsStreamValue =
      StreamValue<List<InviteContactGroup>>(defaultValue: const []);
  final inviteableRecipientsStreamValue =
      StreamValue<List<InviteableRecipient>>(defaultValue: const []);
  final savingStreamValue = StreamValue<bool>(defaultValue: false);
  final selectedCreateProfileIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const <String>{});
  final createGroupNameController = TextEditingController();

  Future<void> init() async {
    await refresh();
  }

  Future<void> refresh() async {
    await _invitesRepository.refreshInviteableRecipients();
    final groups = await _invitesRepository.fetchContactGroups();
    if (_isDisposed) return;
    inviteableRecipientsStreamValue.addValue(
        _invitesRepository.inviteableRecipientsStreamValue.value ??
            const <InviteableRecipient>[]);
    groupsStreamValue.addValue(groups);
  }

  Future<void> createGroup({
    required String name,
    required List<String> recipientAccountProfileIds,
  }) async {
    await _mutate(() {
      return _invitesRepository.createContactGroup(
        nameValue: InviteContactGroupNameValue()..parse(name),
        recipientAccountProfileIds: _buildProfileIds(
          recipientAccountProfileIds,
        ),
      );
    });
  }

  Future<void> renameGroup({
    required InviteContactGroup group,
    required String name,
  }) async {
    await _mutate(() {
      return _invitesRepository.updateContactGroup(
        groupIdValue: group.idValue,
        nameValue: InviteContactGroupNameValue()..parse(name),
      );
    });
  }

  Future<void> updateGroupMembers({
    required InviteContactGroup group,
    required List<String> recipientAccountProfileIds,
  }) async {
    await _mutate(() {
      return _invitesRepository.updateContactGroup(
        groupIdValue: group.idValue,
        recipientAccountProfileIds: _buildProfileIds(
          recipientAccountProfileIds,
        ),
      );
    });
  }

  Future<void> deleteGroup(InviteContactGroup group) async {
    await _mutate(() => _invitesRepository.deleteContactGroup(group.idValue));
  }

  void toggleCreateProfileSelection({
    required String accountProfileId,
    required bool selected,
  }) {
    if (_isDisposed) {
      return;
    }
    final next = Set<String>.of(selectedCreateProfileIdsStreamValue.value);
    if (selected) {
      next.add(accountProfileId);
    } else {
      next.remove(accountProfileId);
    }
    selectedCreateProfileIdsStreamValue
        .addValue(Set<String>.unmodifiable(next));
  }

  void clearCreateDraft() {
    createGroupNameController.clear();
    selectedCreateProfileIdsStreamValue.addValue(const <String>{});
  }

  Future<void> _mutate(Future<void> Function() mutation) async {
    if (_isDisposed) return;
    savingStreamValue.addValue(true);
    try {
      await mutation();
      await refresh();
    } finally {
      if (!_isDisposed) {
        savingStreamValue.addValue(false);
      }
    }
  }

  bool _isDisposed = false;

  InviteAccountProfileIds _buildProfileIds(List<String> rawIds) {
    return InviteAccountProfileIds(
      rawIds.map((id) => InviteAccountProfileIdValue()..parse(id)),
    );
  }

  @override
  FutureOr<void> onDispose() {
    _isDisposed = true;
    createGroupNameController.dispose();
    groupsStreamValue.dispose();
    inviteableRecipientsStreamValue.dispose();
    savingStreamValue.dispose();
    selectedCreateProfileIdsStreamValue.dispose();
  }
}
