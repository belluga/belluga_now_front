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
import 'package:belluga_now/domain/schedule/sent_invite_summary.dart';
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
    Set<String> Function(ContactModel contact, {String? regionCode})?
        localContactHashResolver,
  })  : _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _contactsRepository =
            contactsRepository ?? GetIt.I.get<ContactsRepositoryContract>(),
        _appData = appData ?? GetIt.I.get<AppData>(),
        _isWebRuntime = isWebRuntime ?? kIsWeb,
        _contactRegionCodeValue = _buildRegionCodeValue(contactRegionCode),
        _localContactHashResolver =
            localContactHashResolver ?? InviteContactImportHashes.contactHashes;

  final InvitesRepositoryContract _invitesRepository;
  final ContactsRepositoryContract _contactsRepository;
  final AppData _appData;
  final bool _isWebRuntime;
  final Set<String> Function(ContactModel contact, {String? regionCode})
      _localContactHashResolver;
  InviteContactRegionCodeValue? _contactRegionCodeValue;

  InviteModel? _currentInvite;

  final friendsSuggestionsStreamValue =
      StreamValue<List<InviteFriendResumeWithStatus>?>(defaultValue: null);
  final selectedFriendsSuggestionsStreamValue =
      StreamValue<List<InviteFriendResume>>(defaultValue: const []);
  final contactsPermissionGranted = StreamValue<bool>(defaultValue: false);
  final sentInvitesStreamValue = StreamValue<List<SentInviteStatus>>(
    defaultValue: const [],
  );
  final sentInviteSummaryStreamValue = StreamValue<SentInviteSummary>(
    defaultValue: SentInviteSummary.empty(),
  );
  final shareCodeStreamValue = StreamValue<InviteShareCodeResult?>(
    defaultValue: null,
  );
  final isShareCodeLoadingStreamValue = StreamValue<bool>(defaultValue: true);
  final isPhoneContactsRefreshingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final isPhonePaneInitialLoadingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final phoneContactsRefreshFailedStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final inviteSendFailedStreamValue = StreamValue<bool>(defaultValue: false);
  final selectedInviteableReasonStreamValue = StreamValue<String?>(
    defaultValue: null,
  );
  final selectedPaneStreamValue = StreamValue<InviteSharePane>(
    defaultValue: InviteSharePane.app,
  );
  final externalContactShareTargetsStreamValue =
      StreamValue<List<InviteExternalContactShareTarget>?>(defaultValue: null);
  final sendingInviteRecipientKeysStreamValue = StreamValue<Set<String>>(
    defaultValue: const <String>{},
  );
  bool _isShareCodeLoading = false;
  bool _isPhoneContactsRefreshing = false;
  bool _isPrimingCachedContactsForDisplay = false;
  bool _hasReadDeviceContactsForEmptyCache = false;
  int _inviteShareSessionVersion = 0;
  int? _shareCodeLoadingSessionVersion;
  int? _phoneContactsRefreshSessionVersion;

  bool get _hasLoadedPhoneContacts =>
      _contactsRepository.contactsStreamValue.value != null;

  String get appPaneLabel {
    final normalized = _appData.nameValue.value.trim();
    return normalized.isEmpty ? 'APP' : normalized;
  }

  String? get debugContactRegionCodeValue => _contactRegionCodeValue?.value;

  void setContactRegionCode(String? regionCode) {
    _contactRegionCodeValue = _buildRegionCodeValue(regionCode);
  }

  void setContactRegionCodeIfAbsent(String? regionCode) {
    if (_contactRegionCodeValue != null) {
      return;
    }
    _contactRegionCodeValue = _buildRegionCodeValue(regionCode);
  }

  Future<void> init(InviteModel invite) async {
    _inviteShareSessionVersion += 1;
    _currentInvite = invite;
    final sessionVersion = _inviteShareSessionVersion;
    final expectedOccurrenceId = _currentOccurrenceIdValue();
    selectedFriendsSuggestionsStreamValue.addValue(const []);
    inviteSendFailedStreamValue.addValue(false);
    sendingInviteRecipientKeysStreamValue.addValue(const <String>{});
    phoneContactsRefreshFailedStreamValue.addValue(false);
    isPhoneContactsRefreshingStreamValue.addValue(false);
    isPhonePaneInitialLoadingStreamValue.addValue(false);
    sentInvitesStreamValue.addValue(_cachedSentInvitesForCurrentOccurrence());
    sentInviteSummaryStreamValue.addValue(
      _cachedSentInviteSummaryForCurrentOccurrence(),
    );
    shareCodeStreamValue.addValue(null);
    selectedInviteableReasonStreamValue.addValue(null);
    selectedPaneStreamValue.addValue(InviteSharePane.app);
    _hydrateInviteTargetsFromRepositoryCache();
    unawaited(_primeCachedContactsForDisplay(
      sessionVersion: sessionVersion,
      occurrenceId: expectedOccurrenceId,
    ));
    await Future.wait([
      _loadInviteTargetsWithStatusSafe(
        sessionVersion: sessionVersion,
        occurrenceId: expectedOccurrenceId,
      ),
      _loadShareCodeSafe(
        sessionVersion: sessionVersion,
        occurrenceId: expectedOccurrenceId,
      ),
    ]);
  }

  Future<void> _primeCachedContactsForDisplay({
    required int sessionVersion,
    required InvitesRepositoryContractPrimString? occurrenceId,
  }) async {
    _isPrimingCachedContactsForDisplay = true;
    try {
      await _loadCachedContactsForDisplay();
      if (!_isCurrentInviteShareContext(
        sessionVersion: sessionVersion,
        occurrenceId: occurrenceId,
      )) {
        return;
      }
      _hydrateInviteTargetsFromRepositoryCache();
      _publishPhonePaneFromRepositoryCacheIfAvailable();
      if (_availableContactsFromRepository().isNotEmpty) {
        await _refreshImportedContactMatchesOpportunistically(
          suppressFailures: true,
        );
        if (!_isCurrentInviteShareContext(
          sessionVersion: sessionVersion,
          occurrenceId: occurrenceId,
        )) {
          return;
        }
        _hydrateInviteTargetsFromRepositoryCache();
        _publishPhonePaneFromRepositoryCacheIfAvailable();
      }
    } finally {
      final isCurrentContext = _isCurrentInviteShareContext(
        sessionVersion: sessionVersion,
        occurrenceId: occurrenceId,
      );
      if (isCurrentContext) {
        _isPrimingCachedContactsForDisplay = false;
      }
      final shouldFinalizeDeferredAppPaneHydration = isCurrentContext &&
          friendsSuggestionsStreamValue.value == null &&
          _currentInviteableRecipientsFromRepository() != null;
      if (shouldFinalizeDeferredAppPaneHydration) {
        _applyInviteTargetsFromRepositories(
          sentInvites: sentInvitesStreamValue.value,
          publishPhonePane:
              selectedPaneStreamValue.value == InviteSharePane.phone &&
                  _hasLoadedPhoneContacts,
        );
      }
    }
  }

  Future<void> loadContacts({bool forceDeviceReload = false}) async {
    try {
      final contactsBeforePermission = _contactsRepository
          .contactsStreamValue.value
          ?.where(_isShareableExternalContact)
          .toList(growable: false);
      final granted = await _contactsRepository.requestPermission();
      if (_isDisposed) return;
      contactsPermissionGranted.addValue(granted);

      if (!granted) {
        return;
      }

      final shouldReadDeviceContacts = forceDeviceReload ||
          (!_hasReadDeviceContactsForEmptyCache &&
              (contactsBeforePermission == null ||
                  contactsBeforePermission.isEmpty));
      if (shouldReadDeviceContacts) {
        await _contactsRepository.refreshContacts();
        _hasReadDeviceContactsForEmptyCache = true;
      } else {
        await _contactsRepository.refreshCachedContacts();
      }
      if (_isDisposed) return;
    } catch (_) {
      if (_isDisposed) return;
      contactsPermissionGranted.addValue(false);
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
    final sessionVersion = _inviteShareSessionVersion;
    final expectedOccurrenceId = _currentOccurrenceIdValue();
    selectedPaneStreamValue.addValue(pane);
    if (pane == InviteSharePane.phone && _hasLoadedPhoneContacts) {
      _publishPhonePaneFromRepositoryCacheIfAvailable();
    }
    final shouldLoadPhoneContacts = pane == InviteSharePane.phone &&
        (!_hasLoadedPhoneContacts ||
            (_availableContactsFromRepository().isEmpty &&
                !_hasReadDeviceContactsForEmptyCache));
    if (shouldLoadPhoneContacts) {
      isPhonePaneInitialLoadingStreamValue.addValue(true);
      try {
        await _loadInviteTargetsWithStatusSafe(
          loadPhoneContacts: true,
          forceReloadContacts: _hasLoadedPhoneContacts &&
              _availableContactsFromRepository().isEmpty,
        );
      } finally {
        if (_isCurrentInviteShareContext(
          sessionVersion: sessionVersion,
          occurrenceId: expectedOccurrenceId,
        )) {
          isPhonePaneInitialLoadingStreamValue.addValue(false);
        }
      }
    }
  }

  Future<void> sendInvites() async {
    final invite = _currentInvite;
    if (invite == null) return;

    final selectedFriends = selectedFriendsSuggestionsStreamValue.value;
    if (selectedFriends.isEmpty) return;
    final occurrenceId = _currentOccurrenceIdValue();
    if (occurrenceId == null) return;
    final eventId =
        invitesRepoString(invite.eventId, defaultValue: '', isRequired: true);
    final sessionVersion = _inviteShareSessionVersion;
    final eligibleFriends =
        selectedFriends.where(_canSendDirectInvite).toList(growable: false);
    if (eligibleFriends.isEmpty) {
      inviteSendFailedStreamValue.addValue(true);
      return;
    }
    final sendableFriends = eligibleFriends
        .where((friend) => !_isInviteSendInFlight(friend))
        .toList(growable: false);
    if (sendableFriends.isEmpty) return;

    final inFlightKeys = _markInviteSendsInFlight(sendableFriends);
    try {
      inviteSendFailedStreamValue.addValue(false);
      await _invitesRepository.sendInvites(
        eventId,
        (() {
          final recipients = InviteRecipients();
          for (final selectedFriend in sendableFriends) {
            recipients.add(_toEventFriendResume(selectedFriend));
          }
          return recipients;
        })(),
        occurrenceId: occurrenceId,
      );

      if (!_isCurrentInviteSendSession(sessionVersion)) {
        return;
      }
      final acknowledgedStatuses = _acknowledgedSentInviteStatuses(
        occurrenceId: occurrenceId,
        friends: sendableFriends,
      );
      if (acknowledgedStatuses.isEmpty) {
        throw StateError('Invite send was not acknowledged.');
      }

      selectedFriendsSuggestionsStreamValue.addValue(const []);
      _publishSentInviteStatuses(acknowledgedStatuses);
      if (acknowledgedStatuses.length < sendableFriends.length) {
        inviteSendFailedStreamValue.addValue(true);
      }
      await _syncSentInvitesBestEffort(
        sessionVersion: sessionVersion,
        occurrenceId: occurrenceId,
        eventId: eventId,
      );
    } catch (_) {
      if (!_isDisposed && _isCurrentInviteSendSession(sessionVersion)) {
        inviteSendFailedStreamValue.addValue(true);
      }
    } finally {
      _clearInviteSendKeysInFlight(inFlightKeys);
    }
  }

  Future<void> sendInviteToFriend(InviteFriendResume friend) async {
    final invite = _currentInvite;
    if (invite == null) return;
    final occurrenceId = _currentOccurrenceIdValue();
    if (occurrenceId == null) return;
    final eventId =
        invitesRepoString(invite.eventId, defaultValue: '', isRequired: true);
    final sessionVersion = _inviteShareSessionVersion;
    if (!_canSendDirectInvite(friend)) {
      inviteSendFailedStreamValue.addValue(true);
      return;
    }
    if (_isInviteSendInFlight(friend)) return;

    final inFlightKeys = _markInviteSendsInFlight([friend]);
    try {
      inviteSendFailedStreamValue.addValue(false);
      await _invitesRepository.sendInvites(
        eventId,
        (() {
          final recipients = InviteRecipients();
          recipients.add(_toEventFriendResume(friend));
          return recipients;
        })(),
        occurrenceId: occurrenceId,
      );
      if (!_isCurrentInviteSendSession(sessionVersion)) {
        return;
      }
      final acknowledgedStatuses = _acknowledgedSentInviteStatuses(
        occurrenceId: occurrenceId,
        friends: [friend],
      );
      if (acknowledgedStatuses.isEmpty) {
        throw StateError('Invite send was not acknowledged.');
      }
      _publishSentInviteStatuses(acknowledgedStatuses);
      await _syncSentInvitesBestEffort(
        sessionVersion: sessionVersion,
        occurrenceId: occurrenceId,
        eventId: eventId,
      );
    } catch (_) {
      if (!_isDisposed && _isCurrentInviteSendSession(sessionVersion)) {
        inviteSendFailedStreamValue.addValue(true);
      }
    } finally {
      _clearInviteSendKeysInFlight(inFlightKeys);
    }
  }

  String inviteSendKeyForFriend(InviteFriendResume friend) =>
      _scopedInviteSendKey(friend);

  bool _canSendDirectInvite(InviteFriendResume friend) =>
      friend.accountProfileId.trim().isNotEmpty;

  bool _isInviteSendInFlight(InviteFriendResume friend) =>
      sendingInviteRecipientKeysStreamValue.value.contains(
        inviteSendKeyForFriend(friend),
      );

  bool _isCurrentInviteSendSession(int sessionVersion) =>
      !_isDisposed && _inviteShareSessionVersion == sessionVersion;

  bool _isCurrentInviteShareContext({
    required int sessionVersion,
    required InvitesRepositoryContractPrimString? occurrenceId,
  }) =>
      _isCurrentInviteSendSession(sessionVersion) &&
      _isStillCurrentOccurrence(occurrenceId);

  Set<String> _markInviteSendsInFlight(Iterable<InviteFriendResume> friends) {
    final keys = friends.map(_scopedInviteSendKey).toSet();
    if (_isDisposed || keys.isEmpty) return keys;
    final nextKeys = {
      ...sendingInviteRecipientKeysStreamValue.value,
      ...keys,
    };
    sendingInviteRecipientKeysStreamValue.addValue(nextKeys);
    return keys;
  }

  String _scopedInviteSendKey(InviteFriendResume friend) {
    final occurrenceId = _currentOccurrenceIdValue()?.value.trim();
    final recipientKey = _inviteableIdentityKey(friend);
    if (occurrenceId == null || occurrenceId.isEmpty) {
      return 'session:$_inviteShareSessionVersion|$recipientKey';
    }
    return 'session:$_inviteShareSessionVersion|occurrence:$occurrenceId|$recipientKey';
  }

  void _clearInviteSendKeysInFlight(Set<String> keys) {
    if (_isDisposed) return;
    final nextKeys = {
      ...sendingInviteRecipientKeysStreamValue.value,
    };
    for (final key in keys) {
      nextKeys.remove(key);
    }
    sendingInviteRecipientKeysStreamValue.addValue(nextKeys);
  }

  List<SentInviteStatus> _acknowledgedSentInviteStatuses({
    required InvitesRepositoryContractPrimString occurrenceId,
    required List<InviteFriendResume> friends,
  }) {
    final sentInvites = _cachedSentInvitesForOccurrence(occurrenceId);
    final requestedKeys = friends.map(_inviteableIdentityKey).toSet();
    return sentInvites
        .where(
            (invite) => requestedKeys.contains(_sentInviteIdentityKey(invite)))
        .toList(growable: false);
  }

  void _publishSentInviteStatuses(List<SentInviteStatus> sentInviteStatuses) {
    if (_isDisposed || sentInviteStatuses.isEmpty) return;
    final existingByKey = <String, SentInviteStatus>{
      for (final invite in sentInvitesStreamValue.value)
        _sentInviteIdentityKey(invite): invite,
    };

    for (final status in sentInviteStatuses) {
      existingByKey[_sentInviteIdentityKey(status)] = status;
    }

    final sentInvites = existingByKey.values.toList(growable: false);
    sentInvitesStreamValue.addValue(sentInvites);
    _applyInviteTargetsFromRepositories(sentInvites: sentInvites);
  }

  Future<void> _syncSentInvitesBestEffort({
    required int sessionVersion,
    required InvitesRepositoryContractPrimString? occurrenceId,
    required InvitesRepositoryContractPrimString? eventId,
  }) async {
    try {
      if (!_isCurrentInviteShareContext(
        sessionVersion: sessionVersion,
        occurrenceId: occurrenceId,
      )) {
        return;
      }
      await _refreshInviteableRecipientsForCurrentOccurrence(
        sessionVersion: sessionVersion,
        occurrenceId: occurrenceId,
        eventId: eventId,
      );
      if (!_isCurrentInviteShareContext(
        sessionVersion: sessionVersion,
        occurrenceId: occurrenceId,
      )) {
        return;
      }
      await _applyInviteTargetsFromRepositoriesWithStatus();
    } catch (_) {
      if (!_isCurrentInviteShareContext(
        sessionVersion: sessionVersion,
        occurrenceId: occurrenceId,
      )) {
        return;
      }
      _applyInviteTargetsFromRepositories(
        sentInvites: sentInvitesStreamValue.value,
      );
    }
  }

  Future<void> _loadInviteTargetsWithStatus({
    bool loadPhoneContacts = false,
    bool forceReloadContacts = false,
    required int sessionVersion,
    required InvitesRepositoryContractPrimString? occurrenceId,
    required InvitesRepositoryContractPrimString? eventId,
  }) async {
    final expectedOccurrenceId = occurrenceId;

    final publishPhonePane = loadPhoneContacts ||
        selectedPaneStreamValue.value == InviteSharePane.phone;
    Future<void>? backgroundImportedMatchesRefresh;
    var backgroundImportedMatchesRefreshCompleted = false;

    if (loadPhoneContacts) {
      await loadContacts(forceDeviceReload: forceReloadContacts);
      if (!_isCurrentInviteShareContext(
        sessionVersion: sessionVersion,
        occurrenceId: expectedOccurrenceId,
      )) {
        return;
      }
      await _refreshImportedContactMatchesOpportunistically(
        suppressFailures: !forceReloadContacts,
      );
      if (!_isCurrentInviteShareContext(
        sessionVersion: sessionVersion,
        occurrenceId: expectedOccurrenceId,
      )) {
        return;
      }
    } else if (_availableContactsFromRepository().isNotEmpty) {
      backgroundImportedMatchesRefresh =
          _refreshImportedContactMatchesOpportunistically(
        suppressFailures: true,
      ).whenComplete(() {
        backgroundImportedMatchesRefreshCompleted = true;
      });
    }

    await _refreshInviteableRecipientsForCurrentOccurrence(
      sessionVersion: sessionVersion,
      occurrenceId: expectedOccurrenceId,
      eventId: eventId,
    );
    if (!_isCurrentInviteShareContext(
      sessionVersion: sessionVersion,
      occurrenceId: expectedOccurrenceId,
    )) {
      return;
    }

    final inviteableRecipients = _currentInviteableRecipientsFromRepository();
    final shouldDeferInitialAppPanePublication =
        ((backgroundImportedMatchesRefresh != null &&
                    !backgroundImportedMatchesRefreshCompleted) ||
                _isPrimingCachedContactsForDisplay) &&
            !(inviteableRecipients?.isNotEmpty ?? false) &&
            friendsSuggestionsStreamValue.value == null;
    await _applyInviteTargetsFromRepositoriesWithStatus(
      publishAppPane: !shouldDeferInitialAppPanePublication,
      publishPhonePane: publishPhonePane,
    );

    if (backgroundImportedMatchesRefresh != null) {
      unawaited(
        backgroundImportedMatchesRefresh.then((_) {
          if (!_isCurrentInviteShareContext(
            sessionVersion: sessionVersion,
            occurrenceId: expectedOccurrenceId,
          )) {
            return;
          }
          _applyInviteTargetsFromRepositories(
            sentInvites: sentInvitesStreamValue.value,
            publishPhonePane: publishPhonePane,
          );
        }),
      );
    }
  }

  Future<void> _loadInviteTargetsWithStatusSafe({
    bool loadPhoneContacts = false,
    bool forceReloadContacts = false,
    bool exposeRefreshState = false,
    int? sessionVersion,
    InvitesRepositoryContractPrimString? occurrenceId,
  }) async {
    final activeSessionVersion = sessionVersion ?? _inviteShareSessionVersion;
    final expectedOccurrenceId = occurrenceId ?? _currentOccurrenceIdValue();
    final expectedEventId = _currentEventIdValue();
    if (loadPhoneContacts &&
        _isPhoneContactsRefreshing &&
        _phoneContactsRefreshSessionVersion == activeSessionVersion) {
      return;
    }
    if (loadPhoneContacts) {
      _isPhoneContactsRefreshing = true;
      _phoneContactsRefreshSessionVersion = activeSessionVersion;
    }
    if (exposeRefreshState) {
      if (_isCurrentInviteShareContext(
        sessionVersion: activeSessionVersion,
        occurrenceId: expectedOccurrenceId,
      )) {
        phoneContactsRefreshFailedStreamValue.addValue(false);
        isPhoneContactsRefreshingStreamValue.addValue(true);
      }
    }
    try {
      await _loadInviteTargetsWithStatus(
        loadPhoneContacts: loadPhoneContacts,
        forceReloadContacts: forceReloadContacts,
        sessionVersion: activeSessionVersion,
        occurrenceId: expectedOccurrenceId,
        eventId: expectedEventId,
      );
    } catch (_) {
      if (!_isCurrentInviteShareContext(
        sessionVersion: activeSessionVersion,
        occurrenceId: expectedOccurrenceId,
      )) {
        return;
      }
      if (exposeRefreshState) {
        phoneContactsRefreshFailedStreamValue.addValue(true);
        _publishPhonePaneFallbackTargetsAfterImportFailure();
      } else if (loadPhoneContacts) {
        _publishPhonePaneFallbackTargetsAfterImportFailure();
        return;
      } else {
        sentInvitesStreamValue.addValue(const []);
        if (!_publishCurrentInviteTargetsFromRepositoryCache()) {
          friendsSuggestionsStreamValue.addValue(
            const <InviteFriendResumeWithStatus>[],
          );
        }
      }
    } finally {
      final ownsPhoneRefreshState = loadPhoneContacts &&
          _phoneContactsRefreshSessionVersion == activeSessionVersion;
      if (ownsPhoneRefreshState) {
        _isPhoneContactsRefreshing = false;
        _phoneContactsRefreshSessionVersion = null;
      }
      if (exposeRefreshState) {
        if (_isCurrentInviteShareContext(
          sessionVersion: activeSessionVersion,
          occurrenceId: expectedOccurrenceId,
        )) {
          isPhoneContactsRefreshingStreamValue.addValue(false);
        }
      }
    }
  }

  Future<void> _refreshImportedContactMatchesOpportunistically({
    required bool suppressFailures,
  }) async {
    try {
      await _invitesRepository.refreshImportedContactMatches(
        (() {
          final availableContacts = _availableContactsFromRepository();
          final contacts = InviteContacts(
            regionCodeValue: _contactRegionCodeValue,
            forceImportValue: DomainBooleanValue()
              ..parse((!suppressFailures).toString()),
          );
          for (final availableContact in availableContacts) {
            contacts.add(availableContact);
          }
          return contacts;
        })(),
      );
    } catch (_) {
      if (!suppressFailures) {
        rethrow;
      }
    }
  }

  Future<void> _loadShareCode({
    required int sessionVersion,
    InvitesRepositoryContractPrimString? occurrenceId,
  }) async {
    final invite = _currentInvite;
    if (invite == null) return;
    final expectedOccurrenceId = occurrenceId ?? _currentOccurrenceIdValue();
    if (expectedOccurrenceId == null) return;

    final shareCode = await _invitesRepository.createShareCode(
      eventId: invitesRepoString(
        invite.eventId,
        defaultValue: '',
        isRequired: true,
      ),
      occurrenceId: expectedOccurrenceId,
    );
    if (!_isCurrentInviteShareContext(
      sessionVersion: sessionVersion,
      occurrenceId: expectedOccurrenceId,
    )) {
      return;
    }
    shareCodeStreamValue.addValue(shareCode);
  }

  InvitesRepositoryContractPrimString? _currentOccurrenceIdValue() {
    final occurrenceId = _currentInvite?.occurrenceId?.trim();
    if (occurrenceId == null || occurrenceId.isEmpty) {
      return null;
    }

    return invitesRepoString(occurrenceId, defaultValue: '', isRequired: true);
  }

  InvitesRepositoryContractPrimString? _currentEventIdValue() {
    final eventId = _currentInvite?.eventId.trim();
    if (eventId == null || eventId.isEmpty) {
      return null;
    }

    return invitesRepoString(eventId, defaultValue: '', isRequired: true);
  }

  Future<void> reloadShareCode() async {
    await _loadShareCodeSafe();
  }

  Future<void> _loadShareCodeSafe({
    int? sessionVersion,
    InvitesRepositoryContractPrimString? occurrenceId,
  }) async {
    final activeSessionVersion = sessionVersion ?? _inviteShareSessionVersion;
    final expectedOccurrenceId = occurrenceId ?? _currentOccurrenceIdValue();
    if (_isShareCodeLoading &&
        _shareCodeLoadingSessionVersion == activeSessionVersion) {
      return;
    }
    _isShareCodeLoading = true;
    _shareCodeLoadingSessionVersion = activeSessionVersion;
    if (_isCurrentInviteShareContext(
      sessionVersion: activeSessionVersion,
      occurrenceId: expectedOccurrenceId,
    )) {
      isShareCodeLoadingStreamValue.addValue(true);
    }
    try {
      await _loadShareCode(
        sessionVersion: activeSessionVersion,
        occurrenceId: expectedOccurrenceId,
      );
    } catch (_) {
      if (!_isCurrentInviteShareContext(
        sessionVersion: activeSessionVersion,
        occurrenceId: expectedOccurrenceId,
      )) {
        return;
      }
      shareCodeStreamValue.addValue(null);
    } finally {
      final ownsShareCodeLoading =
          _shareCodeLoadingSessionVersion == activeSessionVersion;
      if (ownsShareCodeLoading) {
        _isShareCodeLoading = false;
        _shareCodeLoadingSessionVersion = null;
      }
      if (ownsShareCodeLoading &&
          _isCurrentInviteShareContext(
            sessionVersion: activeSessionVersion,
            occurrenceId: expectedOccurrenceId,
          )) {
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
      for (final invite in sentInvites) _sentInviteIdentityKey(invite): invite,
    };

    return friends
        .map(
          (friend) => InviteFriendResumeWithStatus(
            friend: friend,
            inviteStatus:
                inviteStatusMap[_inviteableIdentityKey(friend)]?.status,
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
    required List<ContactModel> availableContacts,
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

    return availableContacts
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
      await _hydrateImportedMatchesFromCache();
      if (_isDisposed) return;
    } catch (_) {
      if (_isDisposed) return;
    }
  }

  List<ContactModel> _availableContactsFromRepository() {
    final contacts =
        _contactsRepository.contactsStreamValue.value ?? const <ContactModel>[];

    return contacts
        .where(
          (contact) => contact.phones.isNotEmpty || contact.emails.isNotEmpty,
        )
        .toList(growable: false);
  }

  void _hydrateInviteTargetsFromRepositoryCache() {
    final inviteableRecipients = _currentInviteableRecipientsFromRepository();
    final importedMatches =
        _invitesRepository.importedContactMatchesStreamValue.value;
    if (inviteableRecipients == null && importedMatches == null) {
      return;
    }

    final shouldSuppressEmptyHydrationWhilePriming =
        _isPrimingCachedContactsForDisplay &&
            friendsSuggestionsStreamValue.value == null &&
            !(inviteableRecipients?.isNotEmpty ?? false) &&
            (importedMatches == null || importedMatches.isEmpty);

    _applyInviteTargetsFromRepositories(
      sentInvites: sentInvitesStreamValue.value,
      publishAppPane: !shouldSuppressEmptyHydrationWhilePriming &&
          _canHydrateAppPaneFromRepositoryCache(
            inviteableRecipients: inviteableRecipients,
            importedMatches: importedMatches,
          ),
      publishPhonePane:
          selectedPaneStreamValue.value == InviteSharePane.phone &&
              _hasLoadedPhoneContacts,
    );
  }

  void _publishPhonePaneFromRepositoryCacheIfAvailable() {
    if (!_hasLoadedPhoneContacts) {
      return;
    }
    final backendRecipients = _currentInviteableRecipientsFromRepository() ??
        const <InviteableRecipient>[];
    final importedMatches =
        _invitesRepository.importedContactMatchesStreamValue.value ??
            const <InviteContactMatch>[];

    externalContactShareTargetsStreamValue.addValue(
      _buildExternalShareTargets(
        importedMatches: importedMatches,
        backendRecipients: backendRecipients,
        availableContacts: _availableContactsFromRepository(),
      ),
    );
  }

  void _publishPhonePaneFallbackTargetsAfterImportFailure() {
    if (_hasLoadedPhoneContacts) {
      _publishPhonePaneFromRepositoryCacheIfAvailable();
      return;
    }
    if (externalContactShareTargetsStreamValue.value != null) {
      return;
    }
    externalContactShareTargetsStreamValue.addValue(
      const <InviteExternalContactShareTarget>[],
    );
  }

  bool _publishCurrentInviteTargetsFromRepositoryCache() {
    final hasInviteables =
        _currentInviteableRecipientsFromRepository()?.isNotEmpty ?? false;
    final hasImportedMatches = _invitesRepository
            .importedContactMatchesStreamValue.value?.isNotEmpty ??
        false;
    final hasCurrentSuggestions =
        friendsSuggestionsStreamValue.value?.isNotEmpty ?? false;

    if (!hasInviteables && !hasImportedMatches) {
      return hasCurrentSuggestions;
    }

    _applyInviteTargetsFromRepositories(
      sentInvites: _sentInvitesFromInviteableRecipients(),
      publishPhonePane:
          selectedPaneStreamValue.value == InviteSharePane.phone &&
              _hasLoadedPhoneContacts,
    );
    return true;
  }

  Future<void> _applyInviteTargetsFromRepositoriesWithStatus({
    bool publishAppPane = true,
    bool publishPhonePane = false,
  }) async {
    final sentInvites = _sentInvitesFromInviteableRecipients();
    if (_isDisposed) return;
    sentInvitesStreamValue.addValue(sentInvites);
    _applyInviteTargetsFromRepositories(
      sentInvites: sentInvites,
      publishAppPane: publishAppPane,
      publishPhonePane: publishPhonePane,
    );
  }

  Future<void> _refreshInviteableRecipientsForCurrentOccurrence({
    required int sessionVersion,
    required InvitesRepositoryContractPrimString? occurrenceId,
    required InvitesRepositoryContractPrimString? eventId,
  }) async {
    if (occurrenceId == null) {
      await _invitesRepository.refreshInviteableRecipients();
      if (_isCurrentInviteShareContext(
        sessionVersion: sessionVersion,
        occurrenceId: null,
      )) {
        sentInviteSummaryStreamValue.addValue(SentInviteSummary.empty());
      }
      return;
    }

    await _invitesRepository.refreshInviteableRecipientsForOccurrence(
      occurrenceId: occurrenceId,
      eventId: eventId,
    );
    if (!_isCurrentInviteShareContext(
      sessionVersion: sessionVersion,
      occurrenceId: occurrenceId,
    )) {
      return;
    }
    final summary =
        await _invitesRepository.refreshSentInviteSummaryForOccurrence(
      occurrenceId: occurrenceId,
      eventId: eventId,
    );
    if (_isCurrentInviteShareContext(
      sessionVersion: sessionVersion,
      occurrenceId: occurrenceId,
    )) {
      sentInviteSummaryStreamValue.addValue(summary);
    }
  }

  bool _isStillCurrentOccurrence(
    InvitesRepositoryContractPrimString? occurrenceId,
  ) {
    if (_isDisposed) return false;
    final currentOccurrenceId = _currentOccurrenceIdValue()?.value.trim();
    final expectedOccurrenceId = occurrenceId?.value.trim();
    if (expectedOccurrenceId == null || expectedOccurrenceId.isEmpty) {
      return currentOccurrenceId == null || currentOccurrenceId.isEmpty;
    }
    return currentOccurrenceId == expectedOccurrenceId;
  }

  List<SentInviteStatus> _sentInvitesFromInviteableRecipients() {
    final byKey = <String, SentInviteStatus>{
      for (final sentInvite in _cachedSentInvitesForCurrentOccurrence())
        _sentInviteIdentityKey(sentInvite): sentInvite,
    };

    for (final sentInvite in (_currentInviteableRecipientsFromRepository() ??
            const <InviteableRecipient>[])
        .map((recipient) => recipient.sentInviteStatus)
        .whereType<SentInviteStatus>()) {
      byKey[_sentInviteIdentityKey(sentInvite)] = sentInvite;
    }

    return byKey.values.toList(growable: false);
  }

  List<SentInviteStatus> _cachedSentInvitesForCurrentOccurrence() {
    final occurrenceId = _currentOccurrenceIdValue();
    return occurrenceId == null
        ? const <SentInviteStatus>[]
        : _cachedSentInvitesForOccurrence(occurrenceId);
  }

  List<InviteableRecipient>? _currentInviteableRecipientsFromRepository() {
    return _currentInviteableRecipientsStreamValue.value;
  }

  StreamValue<List<InviteableRecipient>?>
      get _currentInviteableRecipientsStreamValue {
    final occurrenceId = _currentOccurrenceIdValue();
    if (occurrenceId == null) {
      return _invitesRepository.inviteableRecipientsStreamValue;
    }

    return _invitesRepository
        .inviteableRecipientsStreamValueForOccurrence(occurrenceId);
  }

  SentInviteSummary _cachedSentInviteSummaryForCurrentOccurrence() {
    final occurrenceId = _currentOccurrenceIdValue()?.value.trim();
    if (occurrenceId == null || occurrenceId.isEmpty) {
      return SentInviteSummary.empty();
    }

    for (final entry in _invitesRepository
        .sentInviteSummariesByOccurrenceStreamValue.value.entries) {
      if (entry.key.value.trim() == occurrenceId) {
        return entry.value;
      }
    }

    return SentInviteSummary.empty();
  }

  List<SentInviteStatus> _cachedSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString occurrenceIdValue,
  ) {
    final occurrenceId = occurrenceIdValue.value.trim();
    if (occurrenceId.isEmpty) {
      return const <SentInviteStatus>[];
    }

    for (final entry in _invitesRepository
        .sentInvitesByOccurrenceStreamValue.value.entries) {
      if (entry.key.value.trim() == occurrenceId) {
        return entry.value;
      }
    }

    return const <SentInviteStatus>[];
  }

  void _applyInviteTargetsFromRepositories({
    required List<SentInviteStatus> sentInvites,
    bool publishAppPane = true,
    bool publishPhonePane = true,
  }) {
    final backendRecipients = _currentInviteableRecipientsFromRepository() ??
        const <InviteableRecipient>[];
    final importedMatches =
        _invitesRepository.importedContactMatchesStreamValue.value ??
            const <InviteContactMatch>[];
    final availableContacts = _availableContactsFromRepository();

    if (publishPhonePane && _hasLoadedPhoneContacts) {
      externalContactShareTargetsStreamValue.addValue(
        _buildExternalShareTargets(
          importedMatches: importedMatches,
          backendRecipients: backendRecipients,
          availableContacts: availableContacts,
        ),
      );
    }

    if (!publishAppPane) {
      return;
    }

    final localContactHashes = backendRecipients
        .map((recipient) => recipient.contactHash.trim())
        .where((hash) => hash.isNotEmpty)
        .toSet();
    final localContactDisplaysByHash = backendRecipients.isEmpty
        ? const <String, _LocalContactDisplay>{}
        : _localContactDisplaysByHash(
            availableContacts,
            localContactHashes,
          );
    final recipients = _mergeInviteableRecipients(
      backendRecipients: backendRecipients
          .map(
            (recipient) => _toInviteFriendResumeFromRecipient(
              recipient,
              localContactDisplaysByHash,
            ),
          )
          .toList(growable: false),
      importedMatches: importedMatches
          .map((match) => _toInviteFriendResume(match))
          .toList(growable: false),
    )..sort((left, right) => left.name.compareTo(right.name));

    friendsSuggestionsStreamValue.addValue(
      _mergeFriendsWithStatus(recipients, sentInvites),
    );
  }

  Map<String, _LocalContactDisplay> _localContactDisplaysByHash(
    List<ContactModel> availableContacts,
    Set<String> targetHashes,
  ) {
    if (targetHashes.isEmpty) {
      return const <String, _LocalContactDisplay>{};
    }

    final displaysByHash = <String, _LocalContactDisplay>{};

    for (final contact in availableContacts) {
      final display = _LocalContactDisplay(
        name: _displayNameCandidate(contact.displayName),
        phone: _firstNonEmpty(contact.phones.map((phone) => phone.value)),
      );

      if (!display.hasDisplayFallback) {
        continue;
      }

      final hashes = _localContactHashResolver(
        contact,
        regionCode: _contactRegionCodeValue?.value,
      );

      for (final hash in hashes) {
        if (!targetHashes.contains(hash)) {
          continue;
        }
        displaysByHash.putIfAbsent(hash, () => display);
      }

      if (displaysByHash.length == targetHashes.length) {
        break;
      }
    }

    return displaysByHash;
  }

  bool _canHydrateAppPaneFromRepositoryCache({
    required List<InviteableRecipient>? inviteableRecipients,
    required List<InviteContactMatch>? importedMatches,
  }) {
    if (inviteableRecipients != null) {
      return true;
    }

    return importedMatches != null && importedMatches.isNotEmpty;
  }

  Future<void> _hydrateImportedMatchesFromCache() async {
    final availableContacts = _availableContactsFromRepository();
    if (availableContacts.isEmpty) {
      return;
    }

    final contacts = InviteContacts(regionCodeValue: _contactRegionCodeValue);
    for (final availableContact in availableContacts) {
      contacts.add(availableContact);
    }
    await _invitesRepository.hydrateImportedContactMatchesFromCache(contacts);
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

  String _sentInviteIdentityKey(SentInviteStatus invite) {
    final accountProfileId = invite.friend.accountProfileId.trim();
    if (accountProfileId.isNotEmpty) {
      return 'account_profile:$accountProfileId';
    }

    return 'user:${invite.friend.id}';
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
    sentInviteSummaryStreamValue.dispose();
    inviteSendFailedStreamValue.dispose();
    shareCodeStreamValue.dispose();
    isShareCodeLoadingStreamValue.dispose();
    isPhoneContactsRefreshingStreamValue.dispose();
    isPhonePaneInitialLoadingStreamValue.dispose();
    phoneContactsRefreshFailedStreamValue.dispose();
    selectedInviteableReasonStreamValue.dispose();
    selectedPaneStreamValue.dispose();
    externalContactShareTargetsStreamValue.dispose();
    sendingInviteRecipientKeysStreamValue.dispose();
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
