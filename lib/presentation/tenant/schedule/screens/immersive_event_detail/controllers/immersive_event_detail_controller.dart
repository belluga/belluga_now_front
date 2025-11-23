import 'dart:async';

import 'package:belluga_now/domain/gamification/mission_resume.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';

import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ImmersiveEventDetailController implements Disposable {
  ImmersiveEventDetailController({
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
  })  : _userEventsRepository = userEventsRepository ??
            (() {
              if (!GetIt.I.isRegistered<UserEventsRepositoryContract>()) {
                GetIt.I.registerLazySingleton<UserEventsRepositoryContract>(
                  () => UserEventsRepository(),
                );
              }
              return GetIt.I.get<UserEventsRepositoryContract>();
            }()),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>();

  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;

  final scrollController = ScrollController();

  void init(EventModel event) {
    eventStreamValue.addValue(event);
  }

  // Reactive state
  final eventStreamValue = StreamValue<EventModel?>();
  final isConfirmedStreamValue = StreamValue<bool>(defaultValue: false);
  final receivedInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const []);

  // New state for Immersive Screen
  final activeTabStreamValue = StreamValue<int>(defaultValue: 0);
  final missionStreamValue = StreamValue<MissionResume?>();

  // Delegate to repository for single source of truth
  StreamValue<Map<String, List<SentInviteStatus>>>
      get sentInvitesByEventStreamValue =>
          _invitesRepository.sentInvitesByEventStreamValue;

  final friendsGoingStreamValue =
      StreamValue<List<EventFriendResume>>(defaultValue: const []);
  final totalConfirmedStreamValue = StreamValue<int>(defaultValue: 0);
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);

  /// Confirm attendance at this event
  Future<void> confirmAttendance() async {
    final event = eventStreamValue.value;
    if (event == null) return;

    isLoadingStreamValue.addValue(true);

    try {
      await _userEventsRepository.confirmEventAttendance(event.id.value);
      isConfirmedStreamValue.addValue(true);

      final newTotal = totalConfirmedStreamValue.value + 1;
      totalConfirmedStreamValue.addValue(newTotal);
      receivedInvitesStreamValue.addValue(const []);

      // Activate mission upon confirmation
      missionStreamValue.addValue(MissionResume(
        title: 'Missão VIP Ativa!',
        description: 'Traga 3 amigos para ganhar 1 Drink 🍹',
        progress: 0,
        totalRequired: 3,
        reward: '#DRINK123',
        isCompleted: false,
      ));
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  void updateActiveTab(int index) {
    activeTabStreamValue.addValue(index);
  }

  @override
  void onDispose() {
    eventStreamValue.dispose();
    isConfirmedStreamValue.dispose();
    receivedInvitesStreamValue.dispose();
    friendsGoingStreamValue.dispose();
    totalConfirmedStreamValue.dispose();
    isLoadingStreamValue.dispose();
    activeTabStreamValue.dispose();
    missionStreamValue.dispose();
    scrollController.dispose();
  }
}
