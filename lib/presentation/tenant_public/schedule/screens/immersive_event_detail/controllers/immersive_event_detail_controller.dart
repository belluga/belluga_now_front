import 'dart:async';

import 'package:belluga_now/domain/gamification/mission_resume.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_completion_value.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_progress_value.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_reward_value.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_total_required_value.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
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
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

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
    unawaited(_refreshConfirmationState(resolvedEvent.id.value));
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

  // New state for Immersive Screen
  final missionStreamValue = StreamValue<MissionResume?>();

  // Delegate to repository for single source of truth
  StreamValue<Map<InvitesRepositoryContractPrimString, List<SentInviteStatus>>>
      get sentInvitesByEventStreamValue =>
          _invitesRepository.sentInvitesByEventStreamValue;

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
    _pendingInvitesSubscription = null;

    final isConfirmedLocally = _userEventsRepository.isEventConfirmed(
      userEventsRepoString(
        event.id.value,
        defaultValue: '',
        isRequired: true,
      ),
    );
    isConfirmedStreamValue
        .addValue(isConfirmedLocally.value || event.isConfirmedValue.value);

    _updateReceivedInvites(
      _invitesRepository.pendingInvitesStreamValue.value,
      event.id.value,
    );

    _pendingInvitesSubscription = _invitesRepository
        .pendingInvitesStreamValue.stream
        .listen((invites) => _updateReceivedInvites(invites, event.id.value));
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
      dateTimeEnd: event.dateTimeEnd,
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

  Future<void> _refreshConfirmationState(String eventId) async {
    await _userEventsRepository.refreshConfirmedEventIds();
    final isConfirmedFromBackend = _userEventsRepository.isEventConfirmed(
      userEventsRepoString(
        eventId,
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

  void _updateReceivedInvites(List<InviteModel> invites, String eventId) {
    final filtered = invites
        .where((invite) => invite.eventIdValue.value == eventId)
        .toList();
    _invitesRepository.setImmersiveReceivedInvites(filtered);
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

    isLoadingStreamValue.addValue(true);

    try {
      await _userEventsRepository.confirmEventAttendance(
        userEventsRepoString(
          event.id.value,
          defaultValue: '',
          isRequired: true,
        ),
      );
      await _refreshConfirmationState(event.id.value);

      // Activate mission upon confirmation.
      missionStreamValue.addValue(MissionResume(
        titleValue: TitleValue(defaultValue: 'Missao VIP Ativa!')
          ..parse('Missao VIP Ativa!'),
        descriptionValue: DescriptionValue(
            defaultValue: 'Traga 3 amigos para ganhar 1 drink.')
          ..parse('Traga 3 amigos para ganhar 1 drink.'),
        progressValue: const MissionProgressValue(0),
        totalRequiredValue: const MissionTotalRequiredValue(3),
        rewardValue: const MissionRewardValue('#DRINK123'),
        isCompletedValue: const MissionCompletionValue(false),
      ));
      return AttendanceConfirmationResult.confirmed;
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  Future<InviteAcceptResult> acceptInvite(String inviteId) async {
    final eventId = eventStreamValue.value?.id.value;
    isLoadingStreamValue.addValue(true);
    try {
      final result = await _invitesRepository.acceptInvite(
        invitesRepoString(
          inviteId,
          defaultValue: '',
          isRequired: true,
        ),
      );
      if (result.status == 'accepted' &&
          eventId != null &&
          eventId.isNotEmpty) {
        await _refreshConfirmationState(eventId);
      }
      return result;
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  Future<InviteDeclineResult> declineInvite(String inviteId) async {
    isLoadingStreamValue.addValue(true);
    try {
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
    _favoriteProfileIdsSubscription?.cancel();
    _invitesRepository.clearImmersiveDetailState();
    isConfirmedStreamValue.dispose();
    isLoadingStreamValue.dispose();
    missionStreamValue.dispose();
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
