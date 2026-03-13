import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
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
  final contactsStreamValue =
      StreamValue<List<ContactModel>>(defaultValue: const []);
  final selectedContactsStreamValue =
      StreamValue<List<ContactModel>>(defaultValue: const []);
  final contactsPermissionGranted = StreamValue<bool>(defaultValue: false);
  final sentInvitesStreamValue =
      StreamValue<List<SentInviteStatus>>(defaultValue: const []);
  final shareCodeStreamValue =
      StreamValue<InviteShareCodeResult?>(defaultValue: null);

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
        contactsStreamValue.addValue(const []);
        return;
      }

      final contacts = await _contactsRepository.getContacts();
      if (_isDisposed) return;

      final validContacts = contacts
          .where((contact) =>
              contact.phones.isNotEmpty || contact.emails.isNotEmpty)
          .toList(growable: false);
      contactsStreamValue.addValue(validContacts);
    } catch (_) {
      if (_isDisposed) return;
      contactsPermissionGranted.addValue(false);
      contactsStreamValue.addValue(const []);
    }
  }

  void toggleContact(ContactModel contact) {
    final selected = List<ContactModel>.from(selectedContactsStreamValue.value);
    if (selected.contains(contact)) {
      selected.remove(contact);
    } else {
      selected.add(contact);
    }
    selectedContactsStreamValue.addValue(selected);
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

  Future<void> sendInvites() async {
    final invite = _currentInvite;
    if (invite == null) return;

    final selectedFriends = selectedFriendsSuggestionsStreamValue.value;
    if (selectedFriends.isEmpty) return;

    await _invitesRepository.sendInvites(
      invite.eventId,
      selectedFriends.map(_toEventFriendResume).toList(growable: false),
      occurrenceId: invite.occurrenceId,
    );

    selectedFriendsSuggestionsStreamValue.addValue(const []);
    await _syncSentInvites();
  }

  Future<void> sendInviteToFriend(InviteFriendResume friend) async {
    final invite = _currentInvite;
    if (invite == null) return;

    await _invitesRepository.sendInvites(
      invite.eventId,
      <EventFriendResume>[_toEventFriendResume(friend)],
      occurrenceId: invite.occurrenceId,
    );
    await _syncSentInvites();
  }

  Future<void> _loadInviteTargetsWithStatus({
    bool forceReloadContacts = false,
  }) async {
    final invite = _currentInvite;
    if (invite == null) return;

    if (forceReloadContacts || contactsStreamValue.value.isEmpty) {
      await loadContacts();
    }

    final contacts = contactsStreamValue.value;
    final matches = await _invitesRepository.importContacts(contacts);
    if (_isDisposed) return;

    final recipients = matches
        .map(
          (match) => InviteFriendResume.fromPrimitives(
            id: match.userId,
            name: match.displayName,
            avatarUrl: match.avatarUrl,
            matchLabel: 'Contato no Belluga',
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));

    final sentInvites =
        await _invitesRepository.getSentInvitesForEvent(invite.eventId);
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

  Future<void> _syncSentInvites() async {
    final invite = _currentInvite;
    if (invite == null) return;

    final sentInvites =
        await _invitesRepository.getSentInvitesForEvent(invite.eventId);
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
      eventId: invite.eventId,
      occurrenceId: invite.occurrenceId,
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
    return EventFriendResume.fromPrimitives(
      id: friend.id,
      displayName: friend.name,
      avatarUrl: friend.avatarValue.value?.toString(),
    );
  }

  bool _isDisposed = false;

  @override
  FutureOr<void> onDispose() async {
    _isDisposed = true;
    friendsSuggestionsStreamValue.dispose();
    selectedFriendsSuggestionsStreamValue.dispose();
    contactsStreamValue.dispose();
    selectedContactsStreamValue.dispose();
    contactsPermissionGranted.dispose();
    sentInvitesStreamValue.dispose();
    shareCodeStreamValue.dispose();
  }
}
