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
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_summary.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_tag_value.dart';
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
    ProximityPreferencesRepositoryContract? proximityPreferencesRepository,
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
                : null),
        _proximityPreferencesRepository = proximityPreferencesRepository ??
            (GetIt.I.isRegistered<ProximityPreferencesRepositoryContract>()
                ? GetIt.I.get<ProximityPreferencesRepositoryContract>()
                : null);

  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;
  final AuthRepositoryContract? _authRepository;
  final AppDataRepositoryContract? _appDataRepository;
  final AccountProfilesRepositoryContract? _accountProfilesRepository;
  final ProximityPreferencesRepositoryContract? _proximityPreferencesRepository;
  static final Uri _localEventPlaceholderUri =
      Uri.parse('asset://event-placeholder');

  final scrollController = ScrollController();
  StreamSubscription<List<InviteModel>>? _pendingInvitesSubscription;
  StreamSubscription<InviteShareSessionContext?>?
      _shareSessionContextSubscription;
  StreamSubscription<Set<UserEventsRepositoryContractPrimString>>?
      _confirmedOccurrenceIdsSubscription;
  StreamSubscription<Set<AccountProfilesRepositoryContractPrimString>>?
      _favoriteProfileIdsSubscription;
  String? _pendingWarmOccurrenceRouteId;
  StreamValue<EventModel?> get eventStreamValue =>
      _invitesRepository.immersiveSelectedEventStreamValue;
  StreamValue<List<InviteModel>> get receivedInvitesStreamValue =>
      _invitesRepository.immersiveReceivedInvitesStreamValue;
  final favoriteAccountProfileIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const <String>{});

  void init(EventModel event) {
    final resolvedEvent = _alignEventToSelectedOccurrence(event);
    final currentEvent = eventStreamValue.value;
    final hasSameProjection = _hasSameSelectedOccurrenceProjection(
      currentEvent,
      resolvedEvent,
    );
    final isPendingWarmRouteDuplicate =
        _isPendingWarmOccurrenceRoute(currentEvent, resolvedEvent);
    if (!hasSameProjection) {
      _invitesRepository.setImmersiveSelectedEvent(resolvedEvent);
    }
    if (isPendingWarmRouteDuplicate) {
      _pendingWarmOccurrenceRouteId = null;
    } else if (_pendingWarmOccurrenceRouteId != null &&
        _pendingWarmOccurrenceRouteId != resolvedEvent.selectedOccurrenceId) {
      _pendingWarmOccurrenceRouteId = null;
    }
    _hydrateState(hasSameProjection && currentEvent != null
        ? currentEvent
        : resolvedEvent);
    _bindFavoriteAccountProfileState();
  }

  void selectOccurrence(EventModel event, EventOccurrenceOption occurrence) {
    final occurrenceId = occurrence.occurrenceId.trim();
    if (occurrenceId.isEmpty || occurrence.isSelected) {
      return;
    }
    final selectedEvent = _eventWithSelectedOccurrence(event, occurrenceId);
    _pendingWarmOccurrenceRouteId = occurrenceId;
    _invitesRepository.setImmersiveSelectedEvent(selectedEvent);
    _hydrateState(selectedEvent);
  }

  // Reactive state
  final isConfirmedStreamValue = StreamValue<bool>(defaultValue: false);
  final isConfirmationStateLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);

  // Delegate to repository for single source of truth
  StreamValue<Map<InvitesRepositoryContractPrimString, List<SentInviteStatus>>>
      get sentInvitesByOccurrenceStreamValue =>
          _invitesRepository.sentInvitesByOccurrenceStreamValue;
  StreamValue<Map<InvitesRepositoryContractPrimString, SentInviteSummary>>
      get sentInviteSummariesByOccurrenceStreamValue =>
          _invitesRepository.sentInviteSummariesByOccurrenceStreamValue;

  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final isShareActionLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  bool _confirmAttendanceInFlight = false;

  Uri get defaultEventImageUri {
    final configured = _appDataRepository?.appData.mainLogoDarkUrl.value;
    if (configured != null && configured.toString().trim().isNotEmpty) {
      return configured;
    }
    return _localEventPlaceholderUri;
  }

  ProfileTypeRegistry? get profileTypeRegistry =>
      _appDataRepository?.appData.profileTypeRegistry;

  Uri? buildTenantPublicUriFromPath(String? rawPath) {
    final normalizedPath = rawPath?.trim();
    if (normalizedPath == null || normalizedPath.isEmpty) {
      return null;
    }
    return _appDataRepository?.appData.mainDomainValue.value.resolve(
      normalizedPath,
    );
  }

  ProximityPreference? get proximityPreference =>
      _proximityPreferencesRepository?.proximityPreference;

  Future<void> setRouteReferencePointPolicy(bool? useReferencePoint) async {
    final repository = _proximityPreferencesRepository;
    if (repository == null) {
      return;
    }
    await repository.setRouteReferencePointPolicy(
      RouteReferencePointPolicyValue(useReferencePoint),
    );
  }

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

  bool get _isAuthorized => _authRepository?.isAuthorized ?? false;

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
    if (!_isAuthorized) {
      return LinkedProfileFavoriteToggleOutcome.requiresAuthentication;
    }
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
    unawaited(_confirmedOccurrenceIdsSubscription?.cancel());
    _pendingInvitesSubscription = null;
    _shareSessionContextSubscription = null;
    _confirmedOccurrenceIdsSubscription = null;

    final occurrenceId = event.selectedOccurrenceId?.trim();
    final isConfirmedLocally = _userEventsRepository.isOccurrenceConfirmed(
      userEventsRepoString(
        occurrenceId ?? '',
        defaultValue: '',
        isRequired: true,
      ),
    );
    final eventConfirmed = event.isConfirmedValue.value;
    isConfirmationStateLoadingStreamValue.addValue(false);
    isConfirmedStreamValue.addValue(isConfirmedLocally.value || eventConfirmed);

    _pendingInvitesSubscription = _invitesRepository
        .pendingInvitesStreamValue.stream
        .listen((_) => _refreshReceivedInvitesFor(event));
    _shareSessionContextSubscription = _invitesRepository
        .shareCodeSessionContextStreamValue.stream
        .listen((_) => _refreshReceivedInvitesFor(event));
    _confirmedOccurrenceIdsSubscription =
        _userEventsRepository.confirmedOccurrenceIdsStream.stream.listen((_) {
      final current = eventStreamValue.value;
      final currentOccurrenceId = current?.selectedOccurrenceId?.trim();
      if (current == null ||
          currentOccurrenceId == null ||
          currentOccurrenceId.isEmpty) {
        return;
      }
      _applyConfirmationState(currentOccurrenceId);
      _refreshReceivedInvitesFor(current);
    });

    _refreshReceivedInvitesFor(event);
    unawaited(_refreshSentInvitesFor(event));
  }

  Future<void> _refreshSentInvitesFor(EventModel event) async {
    if (!_isAuthorized) {
      return;
    }
    final eventId = event.id.value.trim();
    final occurrenceId = event.selectedOccurrenceId?.trim();
    if (eventId.isEmpty || occurrenceId == null || occurrenceId.isEmpty) {
      return;
    }

    try {
      await _invitesRepository.refreshSentInviteSummaryForOccurrence(
        occurrenceId: invitesRepoString(
          occurrenceId,
          defaultValue: '',
          isRequired: true,
        ),
        eventId: invitesRepoString(
          eventId,
          defaultValue: '',
          isRequired: true,
        ),
      );
    } catch (_) {
      // Sent-status hydration is opportunistic; the invite screen retries.
    }
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
    final preservesCurrentSelectedProgramming =
        (event.selectedOccurrenceId?.trim() ?? '') == occurrenceId &&
            selectedOccurrence.programmingItems.isEmpty;
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
            profileGroups: occurrence.profileGroups,
            tags: occurrence.tags,
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
      profileGroups: event.profileGroups,
      occurrences: updatedOccurrences,
      programmingItems: preservesCurrentSelectedProgramming
          ? event.programmingItems
          : selectedOccurrence.programmingItems,
      coordinate: event.coordinate,
      tags: selectedOccurrence.tags.isNotEmpty
          ? selectedOccurrence.tags
          : event.tags,
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
    final occurrenceId = event.selectedOccurrenceId?.trim();
    if (occurrenceId == null || occurrenceId.isEmpty) {
      return event;
    }
    final selectedOccurrence = event.selectedOccurrence;
    if (selectedOccurrence == null) {
      return event;
    }
    final expectedEnd = _dateTimeEndForSelectedOccurrence(selectedOccurrence);
    final hasMatchingSchedule = _dateTimeSignature(event.dateTimeStart) ==
            _dateTimeSignature(selectedOccurrence.dateTimeStartValue) &&
        _dateTimeSignature(event.dateTimeEnd) ==
            _dateTimeSignature(expectedEnd);
    final hasMatchingProgramming =
        _programmingSignature(event.programmingItems) ==
            _programmingSignature(selectedOccurrence.programmingItems);
    final hasMatchingTags =
        _tagSignature(event.tags) == _tagSignature(selectedOccurrence.tags);
    if (hasMatchingSchedule && hasMatchingProgramming && hasMatchingTags) {
      return event;
    }
    return _eventWithSelectedOccurrence(event, occurrenceId);
  }

  bool _hasSameSelectedOccurrenceProjection(
      EventModel? left, EventModel right) {
    if (left == null) {
      return false;
    }
    return left.id.value == right.id.value &&
        left.selectedOccurrenceId == right.selectedOccurrenceId &&
        _dateTimeSignature(left.dateTimeStart) ==
            _dateTimeSignature(right.dateTimeStart) &&
        _dateTimeSignature(left.dateTimeEnd) ==
            _dateTimeSignature(right.dateTimeEnd) &&
        _profileGroupSignature(left.profileGroups) ==
            _profileGroupSignature(right.profileGroups) &&
        _occurrenceSignature(left.occurrences) ==
            _occurrenceSignature(right.occurrences) &&
        _programmingSignature(left.programmingItems) ==
            _programmingSignature(right.programmingItems);
  }

  bool _isPendingWarmOccurrenceRoute(EventModel? current, EventModel resolved) {
    final pendingOccurrenceId = _pendingWarmOccurrenceRouteId?.trim();
    if (current == null ||
        pendingOccurrenceId == null ||
        pendingOccurrenceId.isEmpty) {
      return false;
    }
    return current.id.value == resolved.id.value &&
        current.selectedOccurrenceId == pendingOccurrenceId &&
        resolved.selectedOccurrenceId == pendingOccurrenceId;
  }

  String _profileGroupSignature(List<EventProfileGroup> groups) {
    return groups.map((group) {
      final profileIds = group.profiles
          .map((profile) => profile.id.trim())
          .where((id) => id.isNotEmpty)
          .join(',');
      final memberIds = group.accountProfileIdValues
          .map((profileId) => profileId.value)
          .join(',');
      return [
        group.id,
        group.label,
        group.order,
        profileIds,
        memberIds,
      ].join(':');
    }).join('|');
  }

  String _occurrenceSignature(List<EventOccurrenceOption> occurrences) {
    return occurrences.map((occurrence) {
      return [
        occurrence.occurrenceId.trim(),
        occurrence.occurrenceSlug.trim(),
        occurrence.isSelected,
        _dateTimeSignature(occurrence.dateTimeStartValue),
        _dateTimeSignature(
          occurrence.dateTimeEnd == null
              ? null
              : (DateTimeValue()
                ..parse(occurrence.dateTimeEnd!.toIso8601String())),
        ),
        occurrence.programmingCount,
        _profileGroupSignature(occurrence.profileGroups),
        _programmingSignature(occurrence.programmingItems),
      ].join(':');
    }).join('|');
  }

  String _dateTimeSignature(DateTimeValue? value) {
    return value?.value?.toIso8601String() ?? '';
  }

  String _programmingSignature(List<EventProgrammingItem> items) {
    return items.map((item) {
      final profileIds = item.linkedAccountProfiles
          .map((profile) => profile.id.trim())
          .where((id) => id.isNotEmpty)
          .join(',');
      return [
        item.time,
        item.endTime ?? '',
        item.title ?? '',
        profileIds,
        item.locationProfile?.id.trim() ?? '',
      ].join(':');
    }).join('|');
  }

  String _tagSignature(Iterable<dynamic> tags) {
    return tags
        .map((tag) => tag is VenueEventTagValue
            ? tag.value.trim()
            : tag.toString().trim())
        .where((tag) => tag.isNotEmpty)
        .join('|');
  }

  void _applyConfirmationState(String occurrenceId) {
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
    if (_isSelectedOccurrenceConfirmed(occurrenceId)) {
      _invitesRepository.setImmersiveReceivedInvites(const <InviteModel>[]);
      return;
    }

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

  bool _isSelectedOccurrenceConfirmed(String? occurrenceId) {
    final normalized = occurrenceId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }
    if (isConfirmedStreamValue.value) {
      return true;
    }
    final repositoryState = _userEventsRepository.isOccurrenceConfirmed(
      userEventsRepoString(
        normalized,
        defaultValue: '',
        isRequired: true,
      ),
    );
    return repositoryState.value ||
        (eventStreamValue.value?.isConfirmedValue.value ?? false);
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

  Future<Uri?> createShareUriForSelectedEvent() async {
    if (isShareActionLoadingStreamValue.value) {
      return null;
    }

    final event = eventStreamValue.value;
    final eventId = event?.id.value.trim() ?? '';
    final occurrenceId = event?.selectedOccurrenceId?.trim() ?? '';
    if (event == null || eventId.isEmpty || occurrenceId.isEmpty) {
      return null;
    }

    isShareActionLoadingStreamValue.addValue(true);
    try {
      final result = await _invitesRepository.createShareCode(
        eventId: invitesRepoString(
          eventId,
          defaultValue: '',
          isRequired: true,
        ),
        occurrenceId: invitesRepoString(
          occurrenceId,
          defaultValue: '',
          isRequired: true,
        ),
      );
      return buildShareUri(result);
    } finally {
      isShareActionLoadingStreamValue.addValue(false);
    }
  }

  Uri? buildShareUri(InviteShareCodeResult? shareCode) {
    if (shareCode == null || shareCode.code.trim().isEmpty) {
      return null;
    }

    final origin = _appDataRepository?.appData.mainDomainValue.value.origin;
    if (origin == null) {
      return null;
    }

    final base = origin.toString().replaceFirst(RegExp(r'/$'), '');
    return Uri.parse(
      '$base/invite?code=${Uri.encodeQueryComponent(shareCode.code)}',
    );
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
    if (_confirmAttendanceInFlight) {
      return AttendanceConfirmationResult.skipped;
    }
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

    _confirmAttendanceInFlight = true;
    isLoadingStreamValue.addValue(true);
    isConfirmationStateLoadingStreamValue.addValue(true);

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
      return AttendanceConfirmationResult.confirmed;
    } finally {
      _confirmAttendanceInFlight = false;
      isLoadingStreamValue.addValue(false);
      isConfirmationStateLoadingStreamValue.addValue(false);
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
    _confirmedOccurrenceIdsSubscription?.cancel();
    _favoriteProfileIdsSubscription?.cancel();
    _invitesRepository.clearImmersiveDetailState();
    isConfirmedStreamValue.dispose();
    isConfirmationStateLoadingStreamValue.dispose();
    isLoadingStreamValue.dispose();
    isShareActionLoadingStreamValue.dispose();
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
