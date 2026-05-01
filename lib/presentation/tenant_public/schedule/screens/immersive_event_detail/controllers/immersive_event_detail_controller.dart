import 'dart:async';

import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_share_session_context.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_decline_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_declined_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_has_other_pending_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';

import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class ImmersiveEventDetailController implements Disposable {
  ImmersiveEventDetailController({
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
    AuthRepositoryContract? authRepository,
    AppDataRepositoryContract? appDataRepository,
    AccountProfilesRepositoryContract? accountProfilesRepository,
  })  : _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null),
        _appDataRepository = appDataRepository ??
            (GetIt.I.isRegistered<AppDataRepositoryContract>()
                ? GetIt.I.get<AppDataRepositoryContract>()
                : null),
        _accountProfilesRepository = accountProfilesRepository ??
            (GetIt.I.isRegistered<AccountProfilesRepositoryContract>()
                ? GetIt.I.get<AccountProfilesRepositoryContract>()
                : null);

  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;
  final AuthRepositoryContract? _authRepository;
  final AppDataRepositoryContract? _appDataRepository;
  final AccountProfilesRepositoryContract? _accountProfilesRepository;
  static final Uri _localEventPlaceholderUri =
      Uri.parse('asset://event-placeholder');

  final scrollController = ScrollController();
  StreamSubscription<List<InviteModel>>? _pendingInvitesSubscription;
  StreamSubscription<InviteShareSessionContext?>?
      _shareSessionContextSubscription;
  StreamSubscription<Set<AccountProfilesRepositoryContractPrimString>>?
      _favoriteProfileIdsSubscription;
  StreamValue<EventModel?> get eventStreamValue =>
      _invitesRepository.immersiveSelectedEventStreamValue;
  StreamValue<List<InviteModel>> get receivedInvitesStreamValue =>
      _invitesRepository.immersiveReceivedInvitesStreamValue;
  final favoriteAccountProfileIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const <String>{});

  void init(EventModel event) {
    final resolvedEvent = _alignEventToSelectedOccurrence(event);
    _invitesRepository.setImmersiveSelectedEvent(resolvedEvent);
    _hydrateState(resolvedEvent);
    _bindFavoriteAccountProfileState();
    final occurrenceId = resolvedEvent.selectedOccurrenceId?.trim();
    if (occurrenceId != null && occurrenceId.isNotEmpty) {
      unawaited(_refreshConfirmationState(occurrenceId));
    }
  }

  void selectOccurrence(EventModel event, EventOccurrenceOption occurrence) {
    final occurrenceId = occurrence.occurrenceId.trim();
    if (occurrenceId.isEmpty || occurrence.isSelected) {
      return;
    }
    final selectedEvent = _eventWithSelectedOccurrence(event, occurrenceId);
    _invitesRepository.setImmersiveSelectedEvent(selectedEvent);
    _hydrateState(selectedEvent);
  }

  // Reactive state
  final isConfirmedStreamValue = StreamValue<bool>(defaultValue: false);

  // Delegate to repository for single source of truth
  StreamValue<Map<InvitesRepositoryContractPrimString, List<SentInviteStatus>>>
      get sentInvitesByOccurrenceStreamValue =>
          _invitesRepository.sentInvitesByOccurrenceStreamValue;

  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);

  Uri get defaultEventImageUri {
    final configured = _appDataRepository?.appData.mainLogoDarkUrl.value;
    if (configured != null && configured.toString().trim().isNotEmpty) {
      return configured;
    }
    return _localEventPlaceholderUri;
  }

  ProfileTypeRegistry? get profileTypeRegistry =>
      _appDataRepository?.appData.profileTypeRegistry;

  String profileTypePluralLabelFor(
    String profileType, {
    String fallback = '',
  }) {
    final normalized = profileType.trim();
    if (normalized.isEmpty) {
      return fallback;
    }
    final registry = profileTypeRegistry;
    if (registry == null) {
      return fallback.isNotEmpty ? fallback : normalized;
    }
    return registry.pluralLabelForType(ProfileTypeKeyValue(normalized));
  }

  bool get _isAuthorized => _authRepository?.isAuthorized ?? true;

  bool get isAuthorized => _isAuthorized;

  bool isLinkedProfileFavoritable(String profileType) {
    final normalized = profileType.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final registry = profileTypeRegistry;
    if (registry == null || registry.isEmpty) {
      return false;
    }
    return registry.isFavoritableFor(ProfileTypeKeyValue(normalized));
  }

  bool isLinkedProfileFavorite(String accountProfileId) {
    final normalized = accountProfileId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return favoriteAccountProfileIdsStreamValue.value.contains(normalized);
  }

  LinkedProfileFavoriteToggleOutcome toggleLinkedProfileFavorite(
    String accountProfileId,
  ) {
    final repository = _accountProfilesRepository;
    if (repository == null) {
      return LinkedProfileFavoriteToggleOutcome.unavailable;
    }
    repository.toggleFavorite(
      AccountProfilesRepositoryContractPrimString.fromRaw(accountProfileId),
    );
    return LinkedProfileFavoriteToggleOutcome.toggled;
  }

  void _hydrateState(EventModel event) {
    unawaited(_pendingInvitesSubscription?.cancel());
    unawaited(_shareSessionContextSubscription?.cancel());
    _pendingInvitesSubscription = null;
    _shareSessionContextSubscription = null;

    final occurrenceId = event.selectedOccurrenceId?.trim();
    final isConfirmedLocally = _userEventsRepository.isOccurrenceConfirmed(
      userEventsRepoString(
        occurrenceId ?? '',
        defaultValue: '',
        isRequired: true,
      ),
    );
    isConfirmedStreamValue
        .addValue(isConfirmedLocally.value || event.isConfirmedValue.value);

    _refreshReceivedInvitesFor(event);

    _pendingInvitesSubscription = _invitesRepository
        .pendingInvitesStreamValue.stream
        .listen((_) => _refreshReceivedInvitesFor(event));
    _shareSessionContextSubscription = _invitesRepository
        .shareCodeSessionContextStreamValue.stream
        .listen((_) => _refreshReceivedInvitesFor(event));
  }

  EventModel _eventWithSelectedOccurrence(
    EventModel event,
    String occurrenceId,
  ) {
    EventOccurrenceOption? selectedOccurrence;
    for (final occurrence in event.occurrences) {
      if (occurrence.occurrenceId == occurrenceId) {
        selectedOccurrence = occurrence;
        break;
      }
    }
    if (selectedOccurrence == null) {
      return event;
    }
    final updatedOccurrences = event.occurrences
        .map(
          (occurrence) => EventOccurrenceOption(
            occurrenceIdValue: occurrence.occurrenceIdValue,
            occurrenceSlugValue: occurrence.occurrenceSlugValue,
            dateTimeStartValue: occurrence.dateTimeStartValue,
            dateTimeEndValue: occurrence.dateTimeEndValue,
            isSelectedValue: EventOccurrenceFlagValue()
              ..parse((occurrence.occurrenceId == occurrenceId).toString()),
            hasLocationOverrideValue: occurrence.hasLocationOverrideValue,
            programmingCountValue: occurrence.programmingCountValue,
            programmingItems: occurrence.programmingItems,
          ),
        )
        .toList(growable: false);

    return EventModel(
      id: event.id,
      slugValue: event.slugValue,
      type: event.type,
      title: event.title,
      content: event.content,
      location: event.location,
      venue: event.venue,
      thumb: event.thumb,
      dateTimeStart: selectedOccurrence.dateTimeStartValue,
      dateTimeEnd: _dateTimeEndForSelectedOccurrence(selectedOccurrence),
      linkedAccountProfiles: event.linkedAccountProfiles,
      occurrences: updatedOccurrences,
      programmingItems: selectedOccurrence.programmingItems,
      coordinate: event.coordinate,
      tags: event.tags,
      isConfirmedValue: event.isConfirmedValue,
      confirmedAtValue: event.confirmedAtValue,
      receivedInvites: event.receivedInvites,
      sentInvites: event.sentInvites,
      friendsGoing: event.friendsGoing,
      totalConfirmedValue: event.totalConfirmedValue,
    );
  }

  DateTimeValue? _dateTimeEndForSelectedOccurrence(
    EventOccurrenceOption selectedOccurrence,
  ) {
    final end = selectedOccurrence.dateTimeEnd;
    if (end == null) {
      return null;
    }

    return DateTimeValue()..parse(end.toIso8601String());
  }

  EventModel _alignEventToSelectedOccurrence(EventModel event) {
    if (event.programmingItems.isNotEmpty) {
      return event;
    }
    final occurrenceId = event.selectedOccurrenceId?.trim();
    if (occurrenceId == null || occurrenceId.isEmpty) {
      return event;
    }
    return _eventWithSelectedOccurrence(event, occurrenceId);
  }

  Future<void> _refreshConfirmationState(String occurrenceId) async {
    await _userEventsRepository.refreshConfirmedOccurrenceIds();
    final isConfirmedFromBackend = _userEventsRepository.isOccurrenceConfirmed(
      userEventsRepoString(
        occurrenceId,
        defaultValue: '',
        isRequired: true,
      ),
    );
    final eventConfirmed =
        eventStreamValue.value?.isConfirmedValue.value ?? false;
    isConfirmedStreamValue.addValue(
      isConfirmedFromBackend.value || eventConfirmed,
    );
  }

  void _refreshReceivedInvitesFor(EventModel event) {
    _updateReceivedInvites(
      _invitesRepository.pendingInvitesStreamValue.value,
      event,
      _invitesRepository.shareCodeSessionContextStreamValue.value,
    );
  }

  void _updateReceivedInvites(
    List<InviteModel> invites,
    EventModel event,
    InviteShareSessionContext? shareSessionContext,
  ) {
    final occurrenceId = event.selectedOccurrenceId?.trim();
    final filtered = invites
        .where((invite) =>
            invite.eventIdValue.value == event.id.value &&
            (occurrenceId == null ||
                occurrenceId.isEmpty ||
                invite.occurrenceIdValue.value == occurrenceId))
        .toList();
    final sessionInvite =
        _matchingShareSessionContextInvite(event, shareSessionContext);
    if (sessionInvite != null &&
        !_hasInviteForSameOccurrence(filtered, sessionInvite)) {
      filtered.add(sessionInvite);
    }
    _invitesRepository.setImmersiveReceivedInvites(filtered);
  }

  InviteModel? _matchingShareSessionContextInvite(
    EventModel event,
    InviteShareSessionContext? shareSessionContext,
  ) {
    if (shareSessionContext == null) {
      return null;
    }
    final invite = shareSessionContext.invite;
    if (invite.eventIdValue.value != event.id.value) {
      return null;
    }
    final occurrenceId = event.selectedOccurrenceId?.trim();
    if (occurrenceId != null &&
        occurrenceId.isNotEmpty &&
        invite.occurrenceIdValue.value != occurrenceId) {
      return null;
    }
    return invite;
  }

  bool _hasInviteForSameOccurrence(
    List<InviteModel> invites,
    InviteModel candidate,
  ) {
    return invites.any((invite) =>
        invite.id == candidate.id ||
        (invite.eventIdValue.value == candidate.eventIdValue.value &&
            invite.occurrenceIdValue.value ==
                candidate.occurrenceIdValue.value));
  }

  InviteShareSessionContext? _shareSessionContextForInviteId(
    String inviteId,
  ) {
    final current = _invitesRepository.shareCodeSessionContextStreamValue.value;
    if (current == null) {
      return null;
    }
    final inviteIdValue = InviteIdValue();
    try {
      inviteIdValue.parse(inviteId);
    } catch (_) {
      return null;
    }
    if (!current.matchesInviteId(inviteIdValue)) {
      return null;
    }
    return current;
  }

  String? shareCodeForInvite(InviteModel invite) {
    final direct = _shareSessionContextForInviteId(invite.id)?.shareCode;
    if (direct != null && direct.trim().isNotEmpty) {
      return direct;
    }

    final primaryInviteId = invite.primaryInviteId?.trim();
    if (primaryInviteId != null && primaryInviteId.isNotEmpty) {
      final primary =
          _shareSessionContextForInviteId(primaryInviteId)?.shareCode.trim();
      if (primary != null && primary.isNotEmpty) {
        return primary;
      }
    }

    for (final inviter in invite.inviters) {
      final inviteId = inviter.inviteId.trim();
      if (inviteId.isEmpty) {
        continue;
      }
      final shareCode =
          _shareSessionContextForInviteId(inviteId)?.shareCode.trim();
      if (shareCode != null && shareCode.isNotEmpty) {
        return shareCode;
      }
    }
    return null;
  }

  String? shareCodeForSelectedEvent() {
    final event = eventStreamValue.value;
    if (event == null) {
      return null;
    }
    final shareSessionContext =
        _invitesRepository.shareCodeSessionContextStreamValue.value;
    if (_matchingShareSessionContextInvite(event, shareSessionContext) ==
        null) {
      return null;
    }
    final shareCode = shareSessionContext?.shareCode.trim();
    return shareCode == null || shareCode.isEmpty ? null : shareCode;
  }

  void _bindFavoriteAccountProfileState() {
    final repository = _accountProfilesRepository;
    if (repository == null) {
      favoriteAccountProfileIdsStreamValue.addValue(const <String>{});
      return;
    }

    favoriteAccountProfileIdsStreamValue.addValue(
      repository.favoriteAccountProfileIdsStreamValue.value
          .map((entry) => entry.value)
          .toSet(),
    );

    _favoriteProfileIdsSubscription ??=
        repository.favoriteAccountProfileIdsStreamValue.stream.listen((ids) {
      favoriteAccountProfileIdsStreamValue.addValue(
        ids.map((entry) => entry.value).toSet(),
      );
    });

    unawaited(repository.init());
  }

  /// Confirm attendance at this event
  Future<AttendanceConfirmationResult> confirmAttendance() async {
    if (!_isAuthorized) {
      return AttendanceConfirmationResult.requiresAuthentication;
    }

    final event = eventStreamValue.value;
    if (event == null) {
      return AttendanceConfirmationResult.skipped;
    }
    final occurrenceId = event.selectedOccurrenceId?.trim();
    if (occurrenceId == null || occurrenceId.isEmpty) {
      return AttendanceConfirmationResult.skipped;
    }

    isLoadingStreamValue.addValue(true);

    try {
      await _userEventsRepository.confirmEventAttendance(
        userEventsRepoString(
          event.id.value,
          defaultValue: '',
          isRequired: true,
        ),
        occurrenceId: userEventsRepoString(
          occurrenceId,
          defaultValue: '',
          isRequired: true,
        ),
      );
      await _refreshConfirmationState(occurrenceId);
      return AttendanceConfirmationResult.confirmed;
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  Future<InviteAcceptResult> acceptInvite(String inviteId) async {
    isLoadingStreamValue.addValue(true);
    try {
      final shareSessionContext = _shareSessionContextForInviteId(inviteId);
      final result = shareSessionContext == null
          ? await _invitesRepository.acceptInvite(
              invitesRepoString(
                inviteId,
                defaultValue: '',
                isRequired: true,
              ),
            )
          : await _invitesRepository.acceptInviteByCode(
              invitesRepoString(
                shareSessionContext.shareCode,
                defaultValue: '',
                isRequired: true,
              ),
            );
      final occurrenceId = eventStreamValue.value?.selectedOccurrenceId?.trim();
      if (result.status == 'accepted' &&
          occurrenceId != null &&
          occurrenceId.isNotEmpty) {
        await _refreshConfirmationState(occurrenceId);
      }
      return result;
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  Future<InviteDeclineResult> declineInvite(String inviteId) async {
    isLoadingStreamValue.addValue(true);
    try {
      final shareSessionContext = _shareSessionContextForInviteId(inviteId);
      if (shareSessionContext != null) {
        _invitesRepository.clearShareCodeSessionContext(
          code: invitesRepoString(
            shareSessionContext.shareCode,
            defaultValue: '',
            isRequired: true,
          ),
        );
        return InviteDeclineResult(
          inviteIdValue: InviteIdValue()..parse(inviteId),
          statusValue: const InviteDeclineStatusValue('declined'),
          groupHasOtherPendingValue: const InviteHasOtherPendingValue(false),
          declinedAtValue: InviteDeclinedAtValue(DateTime.now()),
        );
      }
      return await _invitesRepository.declineInvite(
        invitesRepoString(
          inviteId,
          defaultValue: '',
          isRequired: true,
        ),
      );
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  @override
  void onDispose() {
    _pendingInvitesSubscription?.cancel();
    _shareSessionContextSubscription?.cancel();
    _favoriteProfileIdsSubscription?.cancel();
    _invitesRepository.clearImmersiveDetailState();
    isConfirmedStreamValue.dispose();
    isLoadingStreamValue.dispose();
    favoriteAccountProfileIdsStreamValue.dispose();
    scrollController.dispose();
  }
}

enum AttendanceConfirmationResult {
  confirmed,
  requiresAuthentication,
  skipped,
}

enum LinkedProfileFavoriteToggleOutcome {
  toggled,
  requiresAuthentication,
  unavailable,
}
