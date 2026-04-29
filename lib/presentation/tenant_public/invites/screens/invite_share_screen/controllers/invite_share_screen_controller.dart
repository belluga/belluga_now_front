import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/user/value_objects/friend_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_match_label_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InviteShareScreenController with Disposable {
  InviteShareScreenController({
    InvitesRepositoryContract? invitesRepository,
    ContactsRepositoryContract? contactsRepository,
    AppData? appData,
  })  : _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _contactsRepository =
            contactsRepository ?? GetIt.I.get<ContactsRepositoryContract>(),
        _appData = appData ?? GetIt.I.get<AppData>();

  final InvitesRepositoryContract _invitesRepository;
  final ContactsRepositoryContract _contactsRepository;
  final AppData _appData;

  InviteModel? _currentInvite;

  final friendsSuggestionsStreamValue =
      StreamValue<List<InviteFriendResumeWithStatus>>(defaultValue: const []);
  final selectedFriendsSuggestionsStreamValue =
      StreamValue<List<InviteFriendResume>>(defaultValue: const []);
  final contactsPermissionGranted = StreamValue<bool>(defaultValue: false);
  final sentInvitesStreamValue =
      StreamValue<List<SentInviteStatus>>(defaultValue: const []);
  final shareCodeStreamValue =
      StreamValue<InviteShareCodeResult?>(defaultValue: null);
  final selectedInviteableReasonStreamValue =
      StreamValue<String?>(defaultValue: null);

  List<ContactModel> _availableContacts = const [];

  Future<void> init(InviteModel invite) async {
    _currentInvite = invite;
    await Future.wait([
      _loadInviteTargetsWithStatusSafe(),
      _loadShareCodeSafe(),
    ]);
  }

  Future<void> loadContacts() async {
    try {
      final granted = await _contactsRepository.requestPermission();
      if (_isDisposed) return;
      contactsPermissionGranted.addValue(granted);

      if (!granted) {
        _availableContacts = const [];
        return;
      }

      await _contactsRepository.refreshContacts();
      if (_isDisposed) return;
      final contacts = _contactsRepository.contactsStreamValue.value ??
          const <ContactModel>[];

      final validContacts = contacts
          .where((contact) =>
              contact.phones.isNotEmpty || contact.emails.isNotEmpty)
          .toList(growable: false);
      _availableContacts = validContacts;
    } catch (_) {
      if (_isDisposed) return;
      contactsPermissionGranted.addValue(false);
      _availableContacts = const [];
    }
  }

  void toggleFriend(InviteFriendResume friend) {
    final selected = List<InviteFriendResume>.from(
        selectedFriendsSuggestionsStreamValue.value);
    if (selected.contains(friend)) {
      selected.remove(friend);
    } else {
      selected.add(friend);
    }
    selectedFriendsSuggestionsStreamValue.addValue(selected);
  }

  Future<void> refreshFriends() async {
    await _loadInviteTargetsWithStatusSafe(forceReloadContacts: true);
  }

  void selectInviteableReason(String? reason) {
    final normalized = reason?.trim();
    selectedInviteableReasonStreamValue.addValue(
      normalized == null || normalized.isEmpty ? null : normalized,
    );
  }

  Future<void> sendInvites() async {
    final invite = _currentInvite;
    if (invite == null) return;

    final selectedFriends = selectedFriendsSuggestionsStreamValue.value;
    if (selectedFriends.isEmpty) return;

    await _invitesRepository.sendInvites(
      invitesRepoString(
        invite.eventId,
        defaultValue: '',
        isRequired: true,
      ),
      (() {
        final recipients = InviteRecipients();
        for (final selectedFriend in selectedFriends) {
          recipients.add(_toEventFriendResume(selectedFriend));
        }
        return recipients;
      })(),
      occurrenceId: invite.occurrenceId == null
          ? null
          : invitesRepoString(
              invite.occurrenceId,
              defaultValue: '',
              isRequired: false,
            ),
    );

    selectedFriendsSuggestionsStreamValue.addValue(const []);
    await _syncSentInvites();
  }

  Future<void> sendInviteToFriend(InviteFriendResume friend) async {
    final invite = _currentInvite;
    if (invite == null) return;

    await _invitesRepository.sendInvites(
      invitesRepoString(
        invite.eventId,
        defaultValue: '',
        isRequired: true,
      ),
      (() {
        final recipients = InviteRecipients();
        recipients.add(_toEventFriendResume(friend));
        return recipients;
      })(),
      occurrenceId: invite.occurrenceId == null
          ? null
          : invitesRepoString(
              invite.occurrenceId,
              defaultValue: '',
              isRequired: false,
            ),
    );
    await _syncSentInvites();
  }

  Future<void> _loadInviteTargetsWithStatus({
    bool forceReloadContacts = false,
  }) async {
    final invite = _currentInvite;
    if (invite == null) return;

    if (forceReloadContacts || _availableContacts.isEmpty) {
      await loadContacts();
    }

    final matches = await _importContactsOpportunistically();
    if (_isDisposed) return;

    final inviteableRecipients =
        await _invitesRepository.fetchInviteableRecipients();
    if (_isDisposed) return;

    final recipients = (inviteableRecipients.isNotEmpty
        ? inviteableRecipients
            .map((recipient) => recipient.toFriendResume())
            .toList(growable: false)
        : matches
            .map(
              (match) => _toInviteFriendResume(match),
            )
            .toList(growable: false))
      ..sort((left, right) => left.name.compareTo(right.name));

    final sentInvites = await _invitesRepository.getSentInvitesForEvent(
      invitesRepoString(
        invite.eventId,
        defaultValue: '',
        isRequired: true,
      ),
    );
    if (_isDisposed) return;
    sentInvitesStreamValue.addValue(sentInvites);

    final friendsWithStatus = _mergeFriendsWithStatus(recipients, sentInvites);
    friendsSuggestionsStreamValue.addValue(friendsWithStatus);
  }

  Future<void> _loadInviteTargetsWithStatusSafe({
    bool forceReloadContacts = false,
  }) async {
    try {
      await _loadInviteTargetsWithStatus(
        forceReloadContacts: forceReloadContacts,
      );
    } catch (_) {
      if (_isDisposed) return;
      sentInvitesStreamValue.addValue(const []);
      friendsSuggestionsStreamValue.addValue(const []);
    }
  }

  Future<List<InviteContactMatch>> _importContactsOpportunistically() async {
    try {
      return await _invitesRepository.importContacts(
        (() {
          final contacts = InviteContacts();
          for (final availableContact in _availableContacts) {
            contacts.add(availableContact);
          }
          return contacts;
        })(),
      );
    } catch (_) {
      return const <InviteContactMatch>[];
    }
  }

  Future<void> _syncSentInvites() async {
    final invite = _currentInvite;
    if (invite == null) return;

    final sentInvites = await _invitesRepository.getSentInvitesForEvent(
      invitesRepoString(
        invite.eventId,
        defaultValue: '',
        isRequired: true,
      ),
    );
    if (_isDisposed) return;

    sentInvitesStreamValue.addValue(sentInvites);
    final currentFriends = friendsSuggestionsStreamValue.value
        .map((entry) => entry.friend)
        .toList(growable: false);
    friendsSuggestionsStreamValue
        .addValue(_mergeFriendsWithStatus(currentFriends, sentInvites));
  }

  Future<void> _loadShareCode() async {
    final invite = _currentInvite;
    if (invite == null) return;

    final shareCode = await _invitesRepository.createShareCode(
      eventId: invitesRepoString(
        invite.eventId,
        defaultValue: '',
        isRequired: true,
      ),
      occurrenceId: invite.occurrenceId == null
          ? null
          : invitesRepoString(
              invite.occurrenceId,
              defaultValue: '',
              isRequired: false,
            ),
    );
    if (_isDisposed) return;
    shareCodeStreamValue.addValue(shareCode);
  }

  Future<void> _loadShareCodeSafe() async {
    try {
      await _loadShareCode();
    } catch (_) {
      if (_isDisposed) return;
      shareCodeStreamValue.addValue(null);
    }
  }

  Uri? buildShareUri(InviteShareCodeResult? shareCode) {
    if (shareCode == null || shareCode.code.trim().isEmpty) {
      return null;
    }
    final origin = _appData.mainDomainValue.value.origin;
    final base = origin.toString().replaceFirst(RegExp(r'/$'), '');
    return Uri.parse(
      '$base/invite?code=${Uri.encodeQueryComponent(shareCode.code)}',
    );
  }

  List<InviteFriendResumeWithStatus> _mergeFriendsWithStatus(
    List<InviteFriendResume> friends,
    List<SentInviteStatus> sentInvites,
  ) {
    final inviteStatusMap = <String, SentInviteStatus>{
      for (final invite in sentInvites) invite.friend.id: invite,
    };

    return friends
        .map(
          (friend) => InviteFriendResumeWithStatus(
            friend: friend,
            inviteStatus: inviteStatusMap[friend.id]?.status,
          ),
        )
        .toList(growable: false);
  }

  EventFriendResume _toEventFriendResume(InviteFriendResume friend) {
    final avatarUrlValue = UserAvatarValue();
    final avatarUrl = friend.avatarValue.value?.toString().trim();
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarUrlValue.parse(avatarUrl);
    }

    return EventFriendResume(
      idValue: UserIdValue()..parse(friend.id),
      accountProfileIdValue: friend.accountProfileId.isEmpty
          ? null
          : (InviteAccountProfileIdValue()..parse(friend.accountProfileId)),
      displayNameValue: UserDisplayNameValue()..parse(friend.name),
      avatarUrlValue: avatarUrlValue,
    );
  }

  InviteFriendResume _toInviteFriendResume(InviteContactMatch match) {
    final avatarValue = FriendAvatarValue();
    final avatarUrl = match.avatarUrl?.trim();
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarValue.parse(avatarUrl);
    }

    return InviteFriendResume(
      idValue: FriendIdValue()..parse(match.userId),
      accountProfileIdValue: match.receiverAccountProfileId.isEmpty
          ? null
          : (InviteAccountProfileIdValue()
            ..parse(match.receiverAccountProfileId)),
      nameValue: TitleValue()..parse(match.displayName),
      avatarValue: avatarValue,
      matchLabelValue: FriendMatchLabelValue()
        ..parse(match.inviteableReasons.contains('friend')
            ? 'Amigo no Belluga'
            : 'Contato no Belluga'),
      inviteableReasons: match.inviteableReasons,
      profileExposureLevelValue: match.profileExposureLevelValue,
    );
  }

  bool _isDisposed = false;

  @override
  FutureOr<void> onDispose() async {
    _isDisposed = true;
    friendsSuggestionsStreamValue.dispose();
    selectedFriendsSuggestionsStreamValue.dispose();
    contactsPermissionGranted.dispose();
    sentInvitesStreamValue.dispose();
    shareCodeStreamValue.dispose();
    selectedInviteableReasonStreamValue.dispose();
  }
}
