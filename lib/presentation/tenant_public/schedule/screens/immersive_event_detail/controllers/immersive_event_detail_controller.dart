import 'dart:async';

import 'package:belluga_now/domain/gamification/mission_resume.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_completion_value.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_progress_value.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_reward_value.dart';
import 'package:belluga_now/domain/gamification/value_objects/mission_total_required_value.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';

import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ImmersiveEventDetailController implements Disposable {
  ImmersiveEventDetailController({
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
    AuthRepositoryContract? authRepository,
    AppDataRepositoryContract? appDataRepository,
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
                : null);

  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;
  final AuthRepositoryContract? _authRepository;
  final AppDataRepositoryContract? _appDataRepository;
  static final Uri _localEventPlaceholderUri =
      Uri.parse('asset://event-placeholder');

  final scrollController = ScrollController();
  StreamSubscription<List<InviteModel>>? _pendingInvitesSubscription;

  void init(EventModel event) {
    eventStreamValue.addValue(event);
    _hydrateState(event);
    unawaited(_refreshConfirmationState(event.id.value));
  }

  // Reactive state
  StreamValue<EventModel?> get eventStreamValue =>
      _invitesRepository.immersiveSelectedEventStreamValue;
  final isConfirmedStreamValue = StreamValue<bool>(defaultValue: false);
  StreamValue<List<InviteModel>> get receivedInvitesStreamValue =>
      _invitesRepository.immersiveReceivedInvitesStreamValue;

  // New state for Immersive Screen
  final missionStreamValue = StreamValue<MissionResume?>();

  // Delegate to repository for single source of truth
  StreamValue<Map<String, List<SentInviteStatus>>>
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

  bool get _isAuthorized => _authRepository?.isAuthorized ?? true;

  void _hydrateState(EventModel event) {
    final isConfirmedLocally =
        _userEventsRepository.isEventConfirmed(event.id.value);
    isConfirmedStreamValue
        .addValue(isConfirmedLocally || event.isConfirmedValue.value);

    _updateReceivedInvites(
      _invitesRepository.pendingInvitesStreamValue.value,
      event.id.value,
    );

    _pendingInvitesSubscription = _invitesRepository
        .pendingInvitesStreamValue.stream
        .listen((invites) => _updateReceivedInvites(invites, event.id.value));
  }

  Future<void> _refreshConfirmationState(String eventId) async {
    await _userEventsRepository.refreshConfirmedEventIds();
    final isConfirmedFromBackend =
        _userEventsRepository.isEventConfirmed(eventId);
    final eventConfirmed =
        eventStreamValue.value?.isConfirmedValue.value ?? false;
    isConfirmedStreamValue.addValue(isConfirmedFromBackend || eventConfirmed);
  }

  void _updateReceivedInvites(List<InviteModel> invites, String eventId) {
    final filtered = invites
        .where((invite) => invite.eventIdValue.value == eventId)
        .toList();
    receivedInvitesStreamValue.addValue(filtered);
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
      await _userEventsRepository.confirmEventAttendance(event.id.value);
      await _refreshConfirmationState(event.id.value);

      // Activate mission upon confirmation.
      missionStreamValue.addValue(MissionResume(
        titleValue: TitleValue(defaultValue: 'Missao VIP Ativa!')
          ..parse('Missao VIP Ativa!'),
        descriptionValue:
            DescriptionValue(defaultValue: 'Traga 3 amigos para ganhar 1 drink.')
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
      final result = await _invitesRepository.acceptInvite(inviteId);
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
      return await _invitesRepository.declineInvite(inviteId);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  @override
  void onDispose() {
    _pendingInvitesSubscription?.cancel();
    isConfirmedStreamValue.dispose();
    isLoadingStreamValue.dispose();
    missionStreamValue.dispose();
    scrollController.dispose();
  }
}

enum AttendanceConfirmationResult {
  confirmed,
  requiresAuthentication,
  skipped,
}
