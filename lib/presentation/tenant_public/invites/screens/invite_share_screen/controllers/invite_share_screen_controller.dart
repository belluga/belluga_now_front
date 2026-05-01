import 'dart:async';

import 'package:belluga_now/application/invites/invite_contact_import_hashes.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/invite_contact_region_code_value.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/user/value_objects/friend_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_match_label_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_external_contact_share_target.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

enum InviteSharePane { app, phone }

class InviteShareScreenController with Disposable {
  InviteShareScreenController({
    InvitesRepositoryContract? invitesRepository,
    ContactsRepositoryContract? contactsRepository,
    AppData? appData,
    bool? isWebRuntime,
    String? contactRegionCode,
  })  : _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _contactsRepository =
            contactsRepository ?? GetIt.I.get<ContactsRepositoryContract>(),
        _appData = appData ?? GetIt.I.get<AppData>(),
        _isWebRuntime = isWebRuntime ?? kIsWeb,
        _contactRegionCodeValue = _buildRegionCodeValue(contactRegionCode);

  final InvitesRepositoryContract _invitesRepository;
  final ContactsRepositoryContract _contactsRepository;
  final AppData _appData;
  final bool _isWebRuntime;
  InviteContactRegionCodeValue? _contactRegionCodeValue;

  InviteModel? _currentInvite;

  final friendsSuggestionsStreamValue =
      StreamValue<List<InviteFriendResumeWithStatus>>(defaultValue: const []);
  final selectedFriendsSuggestionsStreamValue =
      StreamValue<List<InviteFriendResume>>(defaultValue: const []);
  final contactsPermissionGranted = StreamValue<bool>(defaultValue: false);
  final sentInvitesStreamValue = StreamValue<List<SentInviteStatus>>(
    defaultValue: const [],
  );
  final shareCodeStreamValue = StreamValue<InviteShareCodeResult?>(
    defaultValue: null,
  );
  final isShareCodeLoadingStreamValue = StreamValue<bool>(defaultValue: true);
  final isPhoneContactsRefreshingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final phoneContactsRefreshFailedStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final selectedInviteableReasonStreamValue = StreamValue<String?>(
    defaultValue: null,
  );
  final selectedPaneStreamValue = StreamValue<InviteSharePane>(
    defaultValue: InviteSharePane.app,
  );
  final externalContactShareTargetsStreamValue =
      StreamValue<List<InviteExternalContactShareTarget>>(
    defaultValue: const [],
  );

  List<ContactModel> _availableContacts = const [];
  List<InviteContactMatch> _importedContactMatches =
      const <InviteContactMatch>[];
  bool _hasLoadedPhoneContacts = false;
  bool _isShareCodeLoading = false;
  bool _isPhoneContactsRefreshing = false;

  void setContactRegionCode(String? regionCode) {
    _contactRegionCodeValue = _buildRegionCodeValue(regionCode);
  }

  Future<void> init(InviteModel invite) async {
    _currentInvite = invite;
    _availableContacts = const [];
    _importedContactMatches = const <InviteContactMatch>[];
    _hasLoadedPhoneContacts = false;
    externalContactShareTargetsStreamValue.addValue(
      const <InviteExternalContactShareTarget>[],
    );
    selectedPaneStreamValue.addValue(InviteSharePane.app);
    await _loadCachedContactsForDisplay();
    await Future.wait([
      _loadInviteTargetsWithStatusSafe(),
      _loadShareCodeSafe(),
    ]);
  }

  Future<void> loadContacts({bool forceDeviceReload = false}) async {
    try {
      final granted = await _contactsRepository.requestPermission();
      if (_isDisposed) return;
      contactsPermissionGranted.addValue(granted);

      if (!granted) {
        _availableContacts = const [];
        return;
      }

      if (forceDeviceReload) {
        await _contactsRepository.refreshContacts();
      } else {
        await _contactsRepository.refreshCachedContacts();
      }
      if (_isDisposed) return;
      _syncAvailableContactsFromRepository();
    } catch (_) {
      if (_isDisposed) return;
      contactsPermissionGranted.addValue(false);
      _availableContacts = const [];
    }
  }

  void toggleFriend(InviteFriendResume friend) {
    final selected = List<InviteFriendResume>.from(
      selectedFriendsSuggestionsStreamValue.value,
    );
    if (selected.contains(friend)) {
      selected.remove(friend);
    } else {
      selected.add(friend);
    }
    selectedFriendsSuggestionsStreamValue.addValue(selected);
  }

  Future<void> refreshPhoneContacts() async {
    await _loadInviteTargetsWithStatusSafe(
      loadPhoneContacts: true,
      forceReloadContacts: true,
      exposeRefreshState: true,
    );
  }

  Future<void> refreshFriends() async {
    await refreshPhoneContacts();
  }

  void selectInviteableReason(String? reason) {
    final normalized = reason?.trim();
    selectedInviteableReasonStreamValue.addValue(
      normalized == null || normalized.isEmpty ? null : normalized,
    );
  }

  Future<void> selectPane(InviteSharePane pane) async {
    selectedPaneStreamValue.addValue(pane);
    if (pane == InviteSharePane.phone && !_hasLoadedPhoneContacts) {
      await _loadInviteTargetsWithStatusSafe(loadPhoneContacts: true);
    }
  }

  Future<void> sendInvites() async {
    final invite = _currentInvite;
    if (invite == null) return;

    final selectedFriends = selectedFriendsSuggestionsStreamValue.value;
    if (selectedFriends.isEmpty) return;
    final occurrenceId = _currentOccurrenceIdValue();
    if (occurrenceId == null) return;

    await _invitesRepository.sendInvites(
      invitesRepoString(invite.eventId, defaultValue: '', isRequired: true),
      (() {
        final recipients = InviteRecipients();
        for (final selectedFriend in selectedFriends) {
          recipients.add(_toEventFriendResume(selectedFriend));
        }
        return recipients;
      })(),
      occurrenceId: occurrenceId,
    );

    selectedFriendsSuggestionsStreamValue.addValue(const []);
    await _syncSentInvites();
  }

  Future<void> sendInviteToFriend(InviteFriendResume friend) async {
    final invite = _currentInvite;
    if (invite == null) return;
    final occurrenceId = _currentOccurrenceIdValue();
    if (occurrenceId == null) return;

    await _invitesRepository.sendInvites(
      invitesRepoString(invite.eventId, defaultValue: '', isRequired: true),
      (() {
        final recipients = InviteRecipients();
        recipients.add(_toEventFriendResume(friend));
        return recipients;
      })(),
      occurrenceId: occurrenceId,
    );
    await _syncSentInvites();
  }

  Future<void> _loadInviteTargetsWithStatus({
    bool loadPhoneContacts = false,
    bool forceReloadContacts = false,
  }) async {
    final invite = _currentInvite;
    if (invite == null) return;

    var contactClassificationAvailable = true;
    if (loadPhoneContacts) {
      await loadContacts(forceDeviceReload: forceReloadContacts);
      _hasLoadedPhoneContacts = true;
      final matches = await _importContactsOpportunistically(
        suppressFailures: !forceReloadContacts,
      );
      if (_isDisposed) return;
      contactClassificationAvailable = matches != null;
      _importedContactMatches = matches ?? const <InviteContactMatch>[];
    }
    final inviteableRecipients =
        await _invitesRepository.fetchInviteableRecipients();
    if (_isDisposed) return;

    if (_hasLoadedPhoneContacts) {
      externalContactShareTargetsStreamValue.addValue(
        contactClassificationAvailable
            ? _buildExternalShareTargets(
                importedMatches: _importedContactMatches,
                backendRecipients: inviteableRecipients,
              )
            : const <InviteExternalContactShareTarget>[],
      );
    }

    final localContactDisplaysByHash = _localContactDisplaysByHash();
    final recipients = _mergeInviteableRecipients(
      backendRecipients: inviteableRecipients
          .map(
            (recipient) => _toInviteFriendResumeFromRecipient(
              recipient,
              localContactDisplaysByHash,
            ),
          )
          .toList(growable: false),
      importedMatches: _importedContactMatches
          .map((match) => _toInviteFriendResume(match))
          .toList(growable: false),
    )..sort((left, right) => left.name.compareTo(right.name));

    final occurrenceId = _currentOccurrenceIdValue();
    if (occurrenceId == null) {
      sentInvitesStreamValue.addValue(const []);
      friendsSuggestionsStreamValue.addValue(
        _mergeFriendsWithStatus(recipients, const <SentInviteStatus>[]),
      );
      return;
    }

    final sentInvites = await _invitesRepository.getSentInvitesForOccurrence(
      occurrenceId,
    );
    if (_isDisposed) return;
    sentInvitesStreamValue.addValue(sentInvites);

    final friendsWithStatus = _mergeFriendsWithStatus(recipients, sentInvites);
    friendsSuggestionsStreamValue.addValue(friendsWithStatus);
  }

  Future<void> _loadInviteTargetsWithStatusSafe({
    bool loadPhoneContacts = false,
    bool forceReloadContacts = false,
    bool exposeRefreshState = false,
  }) async {
    if (loadPhoneContacts && _isPhoneContactsRefreshing) {
      return;
    }
    if (loadPhoneContacts) {
      _isPhoneContactsRefreshing = true;
    }
    if (exposeRefreshState) {
      if (!_isDisposed) {
        phoneContactsRefreshFailedStreamValue.addValue(false);
        isPhoneContactsRefreshingStreamValue.addValue(true);
      }
    }
    try {
      await _loadInviteTargetsWithStatus(
        loadPhoneContacts: loadPhoneContacts,
        forceReloadContacts: forceReloadContacts,
      );
    } catch (_) {
      if (_isDisposed) return;
      externalContactShareTargetsStreamValue.addValue(const []);
      if (exposeRefreshState) {
        phoneContactsRefreshFailedStreamValue.addValue(true);
      } else if (loadPhoneContacts) {
        return;
      } else {
        sentInvitesStreamValue.addValue(const []);
        friendsSuggestionsStreamValue.addValue(const []);
      }
    } finally {
      if (loadPhoneContacts) {
        _isPhoneContactsRefreshing = false;
      }
      if (exposeRefreshState) {
        if (!_isDisposed) {
          isPhoneContactsRefreshingStreamValue.addValue(false);
        }
      }
    }
  }

  Future<List<InviteContactMatch>?> _importContactsOpportunistically({
    required bool suppressFailures,
  }) async {
    try {
      return await _invitesRepository.importContacts(
        (() {
          final contacts = InviteContacts(
            regionCodeValue: _contactRegionCodeValue,
            forceImportValue: DomainBooleanValue()
              ..parse((!suppressFailures).toString()),
          );
          for (final availableContact in _availableContacts) {
            contacts.add(availableContact);
          }
          return contacts;
        })(),
      );
    } catch (_) {
      if (!suppressFailures) {
        rethrow;
      }
      return null;
    }
  }

  Future<void> _syncSentInvites() async {
    final invite = _currentInvite;
    if (invite == null) return;
    final occurrenceId = _currentOccurrenceIdValue();
    if (occurrenceId == null) return;

    final sentInvites = await _invitesRepository.getSentInvitesForOccurrence(
      occurrenceId,
    );
    if (_isDisposed) return;

    sentInvitesStreamValue.addValue(sentInvites);
    final currentFriends = friendsSuggestionsStreamValue.value
        .map((entry) => entry.friend)
        .toList(growable: false);
    friendsSuggestionsStreamValue.addValue(
      _mergeFriendsWithStatus(currentFriends, sentInvites),
    );
  }

  Future<void> _loadShareCode() async {
    final invite = _currentInvite;
    if (invite == null) return;
    final occurrenceId = _currentOccurrenceIdValue();
    if (occurrenceId == null) return;

    final shareCode = await _invitesRepository.createShareCode(
      eventId: invitesRepoString(
        invite.eventId,
        defaultValue: '',
        isRequired: true,
      ),
      occurrenceId: occurrenceId,
    );
    if (_isDisposed) return;
    shareCodeStreamValue.addValue(shareCode);
  }

  InvitesRepositoryContractPrimString? _currentOccurrenceIdValue() {
    final occurrenceId = _currentInvite?.occurrenceId?.trim();
    if (occurrenceId == null || occurrenceId.isEmpty) {
      return null;
    }

    return invitesRepoString(occurrenceId, defaultValue: '', isRequired: true);
  }

  Future<void> reloadShareCode() async {
    await _loadShareCodeSafe();
  }

  Future<void> _loadShareCodeSafe() async {
    if (_isShareCodeLoading) {
      return;
    }
    _isShareCodeLoading = true;
    if (!_isDisposed) {
      isShareCodeLoadingStreamValue.addValue(true);
    }
    try {
      await _loadShareCode();
    } catch (_) {
      if (_isDisposed) return;
      shareCodeStreamValue.addValue(null);
    } finally {
      _isShareCodeLoading = false;
      if (!_isDisposed) {
        isShareCodeLoadingStreamValue.addValue(false);
      }
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

  List<InviteFriendResume> _mergeInviteableRecipients({
    required List<InviteFriendResume> backendRecipients,
    required List<InviteFriendResume> importedMatches,
  }) {
    final merged = <String, InviteFriendResume>{};

    for (final recipient in backendRecipients) {
      merged[_inviteableIdentityKey(recipient)] = recipient;
    }

    for (final match in importedMatches) {
      merged.putIfAbsent(_inviteableIdentityKey(match), () => match);
    }

    return merged.values.toList(growable: false);
  }

  List<InviteExternalContactShareTarget> _buildExternalShareTargets({
    required List<InviteContactMatch> importedMatches,
    required List<InviteableRecipient> backendRecipients,
  }) {
    if (_isWebRuntime) {
      return const <InviteExternalContactShareTarget>[];
    }

    final matchedHashes = {
      ...importedMatches
          .map((match) => match.contactHash.trim())
          .where((hash) => hash.isNotEmpty),
      ...backendRecipients
          .where(
            (recipient) =>
                recipient.inviteableReasons.contains('contact_match'),
          )
          .map((recipient) => recipient.contactHash.trim())
          .where((hash) => hash.isNotEmpty),
    };

    return _availableContacts
        .where(_isShareableExternalContact)
        .where((contact) {
          final localHashes = InviteContactImportHashes.contactHashes(
            contact,
            regionCode: _contactRegionCodeValue?.value,
          );
          return localHashes.intersection(matchedHashes).isEmpty;
        })
        .map(_toExternalShareTarget)
        .toList(growable: false);
  }

  bool _isShareableExternalContact(ContactModel contact) =>
      contact.phones.isNotEmpty || contact.emails.isNotEmpty;

  InviteExternalContactShareTarget _toExternalShareTarget(
    ContactModel contact,
  ) {
    final displayName = contact.displayName.trim().isNotEmpty
        ? contact.displayName.trim()
        : 'Contato sem nome';

    return InviteExternalContactShareTarget(
      id: contact.id,
      displayName: displayName,
      primaryPhone: _firstNonEmpty(contact.phones.map((phone) => phone.value)),
      primaryEmail: _firstNonEmpty(contact.emails.map((email) => email.value)),
    );
  }

  String? _firstNonEmpty(Iterable<String> values) {
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  Future<void> _loadCachedContactsForDisplay() async {
    try {
      await _contactsRepository.loadCachedContacts();
      if (_isDisposed) return;
      _syncAvailableContactsFromRepository();
    } catch (_) {
      if (_isDisposed) return;
      _availableContacts = const [];
    }
  }

  void _syncAvailableContactsFromRepository() {
    final contacts =
        _contactsRepository.contactsStreamValue.value ?? const <ContactModel>[];

    _availableContacts = contacts
        .where(
          (contact) => contact.phones.isNotEmpty || contact.emails.isNotEmpty,
        )
        .toList(growable: false);
  }

  Map<String, _LocalContactDisplay> _localContactDisplaysByHash() {
    final displaysByHash = <String, _LocalContactDisplay>{};

    for (final contact in _availableContacts) {
      final display = _LocalContactDisplay(
        name: _displayNameCandidate(contact.displayName),
        phone: _firstNonEmpty(contact.phones.map((phone) => phone.value)),
      );

      if (!display.hasDisplayFallback) {
        continue;
      }

      final hashes = InviteContactImportHashes.contactHashes(
        contact,
        regionCode: _contactRegionCodeValue?.value,
      );

      for (final hash in hashes) {
        displaysByHash.putIfAbsent(hash, () => display);
      }
    }

    return displaysByHash;
  }

  InviteFriendResume _toInviteFriendResumeFromRecipient(
    InviteableRecipient recipient,
    Map<String, _LocalContactDisplay> localContactDisplaysByHash,
  ) {
    final friendAvatarValue = FriendAvatarValue();
    final normalizedAvatar = recipient.avatarUrl?.trim();
    if (normalizedAvatar != null && normalizedAvatar.isNotEmpty) {
      friendAvatarValue.parse(normalizedAvatar);
    }

    final localDisplay =
        localContactDisplaysByHash[recipient.contactHash.trim()];
    final displayName = _recipientDisplayName(
      recipient: recipient,
      localDisplay: localDisplay,
    );

    return InviteFriendResume(
      idValue: FriendIdValue()..parse(recipient.userId),
      accountProfileIdValue: recipient.receiverAccountProfileIdValue,
      nameValue: TitleValue()..parse(displayName),
      avatarValue: friendAvatarValue,
      matchLabelValue: FriendMatchLabelValue()..parse(recipient.matchLabel),
      inviteableReasons: recipient.inviteableReasons,
      profileExposureLevelValue: recipient.profileExposureLevelValue,
    );
  }

  String _recipientDisplayName({
    required InviteableRecipient recipient,
    required _LocalContactDisplay? localDisplay,
  }) {
    final accountName = _displayNameCandidate(recipient.displayName);
    if (accountName != null) {
      return accountName;
    }

    final localName = localDisplay?.name;
    if (localName != null) {
      return localName;
    }

    final localPhone = localDisplay?.phone;
    if (localPhone != null) {
      return localPhone;
    }

    final accountPhone = _phoneDisplayCandidate(recipient.displayName);
    if (accountPhone != null) {
      return accountPhone;
    }

    final fallback = recipient.displayName.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'Contato sem nome';
  }

  String? _displayNameCandidate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || _looksLikePhoneNumber(normalized)) {
      return null;
    }

    if (!RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(normalized)) {
      return null;
    }

    return normalized;
  }

  String? _phoneDisplayCandidate(String value) {
    final normalized = value.trim();
    return _looksLikePhoneNumber(normalized) ? normalized : null;
  }

  bool _looksLikePhoneNumber(String value) {
    if (RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(value)) {
      return false;
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      return false;
    }

    return RegExp(r'^[\d\s()+\-.]+$').hasMatch(value);
  }

  static InviteContactRegionCodeValue? _buildRegionCodeValue(
    String? regionCode,
  ) {
    final normalized = regionCode?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return InviteContactRegionCodeValue()..parse(normalized);
  }

  String _inviteableIdentityKey(InviteFriendResume friend) {
    final accountProfileId = friend.accountProfileId.trim();
    if (accountProfileId.isNotEmpty) {
      return 'account_profile:$accountProfileId';
    }

    return 'user:${friend.id}';
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
        ..parse(
          match.inviteableReasons.contains('friend')
              ? 'Amigo no Belluga'
              : 'Contato no Belluga',
        ),
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
    isShareCodeLoadingStreamValue.dispose();
    isPhoneContactsRefreshingStreamValue.dispose();
    phoneContactsRefreshFailedStreamValue.dispose();
    selectedInviteableReasonStreamValue.dispose();
    selectedPaneStreamValue.dispose();
    externalContactShareTargetsStreamValue.dispose();
  }
}

class _LocalContactDisplay {
  const _LocalContactDisplay({
    required this.name,
    required this.phone,
  });

  final String? name;
  final String? phone;

  bool get hasDisplayFallback => name != null || phone != null;
}
