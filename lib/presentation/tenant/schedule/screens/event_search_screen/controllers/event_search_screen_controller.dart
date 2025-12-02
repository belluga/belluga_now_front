import 'dart:async';

import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class EventSearchScreenController implements Disposable {
  EventSearchScreenController({
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
  })  : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>();

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;

  final searchController = TextEditingController();
  final focusNode = FocusNode();

  final allEventsStreamValue = StreamValue<List<EventModel>?>();
  final availableEventsStreamValue = StreamValue<List<EventModel>?>();
  final searchResultsStreamValue = StreamValue<List<EventModel>?>();
  final showHistoryStreamValue = StreamValue<bool>(defaultValue: false);
  final searchActiveStreamValue = StreamValue<bool>(defaultValue: false);
  final inviteFilterStreamValue =
      StreamValue<InviteFilter>(defaultValue: InviteFilter.none);
  final Duration defaultEventDuration = const Duration(hours: 3);

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _pendingInvitesSubscription;

  Future<void> init() async {
    await _invitesRepository.init();
    await _populateAllEvents();
    _updateAvailableEvents();
    _listenForStatusChanges();
  }

  Future<void> _populateAllEvents() async {
    final List<EventModel> _allEvents =
        await _scheduleRepository.getAllEvents();
    _allEvents.sort(
        (a, b) => a.dateTimeStart.value!.compareTo(b.dateTimeStart.value!));
    allEventsStreamValue.addValue(_allEvents);
  }

  void toggleHistory() {
    // When true, show only past events; when false, show upcoming/ongoing
    final currentValue = showHistoryStreamValue.value;
    showHistoryStreamValue.addValue(!currentValue);
    _updateAvailableEvents();
  }

  void setInviteFilter(InviteFilter filter) {
    inviteFilterStreamValue.addValue(filter);
    _updateAvailableEvents();
  }

  void cycleInviteFilter() {
    final current = inviteFilterStreamValue.value;
    switch (current) {
      case InviteFilter.none:
        setInviteFilter(InviteFilter.invitesAndConfirmed);
        break;
      case InviteFilter.invitesAndConfirmed:
        setInviteFilter(InviteFilter.confirmedOnly);
        break;
      case InviteFilter.confirmedOnly:
        setInviteFilter(InviteFilter.none);
        break;
    }
  }

  void setSearchActive(bool active) {
    searchActiveStreamValue.addValue(active);
    if (active) {
      focusNode.requestFocus();
    } else {
      focusNode.unfocus();
      if (searchController.text.isEmpty) {
        searchResultsStreamValue.addValue(availableEventsStreamValue.value);
      }
    }
  }

  void toggleSearchMode() {
    setSearchActive(!searchActiveStreamValue.value);
  }

  void _updateAvailableEvents() {
    final showPastOnly = showHistoryStreamValue.value;
    _rebuildAvailableEvents(showPastOnly);

    final filtered =
        _applyInviteFilter(availableEventsStreamValue.value ?? const []);

    if (searchController.text.isNotEmpty) {
      _performSearch(filteredEvents: filtered);
    } else {
      searchResultsStreamValue.addValue(filtered);
    }
  }

  void _rebuildAvailableEvents(bool showPastOnly) {
    final now = DateTime.now();
    final all = allEventsStreamValue.value ?? const <EventModel>[];
    Iterable<EventModel> filtered = all;

    bool isHappeningNow(EventModel event) {
      final start = event.dateTimeStart.value;
      if (start == null) return false;
      final end = start.add(defaultEventDuration);
      return (start.isBefore(now) || start.isAtSameMomentAs(now)) &&
          (now.isBefore(end) || now.isAtSameMomentAs(end));
    }

    filtered = filtered.where((event) {
      final start = event.dateTimeStart.value;
      if (start == null) return false;
      final happeningNow = isHappeningNow(event);

      if (showPastOnly) {
        return start.isBefore(now) && !happeningNow;
      }

      // Upcoming bucket includes ongoing events
      return happeningNow ||
          start.isAfter(now) ||
          start.isAtSameMomentAs(now);
    });

    final sorted = filtered.toList()
      ..sort((a, b) {
        final aStart = a.dateTimeStart.value!;
        final bStart = b.dateTimeStart.value!;
        return showPastOnly
            ? bStart.compareTo(aStart)
            : aStart.compareTo(bStart);
      });

    availableEventsStreamValue.addValue(sorted);
  }

  void searchEvents(String query) {
    if (query.isEmpty) {
      searchResultsStreamValue.addValue(
        _applyInviteFilter(availableEventsStreamValue.value ?? const []),
      );
      return;
    }

    _performSearch();
  }

  void _performSearch({List<EventModel>? filteredEvents}) {
    final _availableEvents =
        filteredEvents ?? _applyInviteFilter(availableEventsStreamValue.value ?? const []);

    final lowercaseQuery = searchController.text.toLowerCase();

    final filtered = _availableEvents.where((event) {
      final titleMatch =
          event.title.value.toLowerCase().contains(lowercaseQuery);
      final contentMatch =
          (event.content.value ?? "").toLowerCase().contains(lowercaseQuery);
      final artistMatch = event.artists.any(
        (artist) => artist.displayName.toLowerCase().contains(lowercaseQuery),
      );

      return titleMatch || contentMatch || artistMatch;
    }).toList();

    searchResultsStreamValue.addValue(filtered);
  }

  List<EventModel> _applyInviteFilter(List<EventModel> events) {
    final filter = inviteFilterStreamValue.value;
    if (filter == InviteFilter.none) return events;

    final confirmedIds = _userEventsRepository.confirmedEventIdsStream.value;
    final pendingIds = _invitesRepository.pendingInvitesStreamValue.value
        .map((invite) => invite.eventId)
        .toSet();

    bool isConfirmed(String id) => confirmedIds.contains(id);
    bool hasPending(String id) => pendingIds.contains(id);

    return events.where((event) {
      final id = event.id.value;
      switch (filter) {
        case InviteFilter.none:
          return true;
        case InviteFilter.invitesAndConfirmed:
          return isConfirmed(id) || hasPending(id);
        case InviteFilter.confirmedOnly:
          return isConfirmed(id);
      }
    }).toList();
  }

  bool isEventConfirmed(String eventId) =>
      _userEventsRepository.isEventConfirmed(eventId);

  bool hasPendingInvite(String eventId) =>
      _invitesRepository.pendingInvitesStreamValue.value
          .any((invite) => invite.eventId == eventId);

  void _listenForStatusChanges() {
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();

    _confirmedEventsSubscription =
        _userEventsRepository.confirmedEventIdsStream.stream.listen((_) {
      _updateAvailableEvents();
    });
    _pendingInvitesSubscription =
        _invitesRepository.pendingInvitesStreamValue.stream.listen((_) {
      _updateAvailableEvents();
    });
  }

  @override
  void onDispose() {
    allEventsStreamValue.dispose();
    availableEventsStreamValue.dispose();
    searchResultsStreamValue.dispose();
    showHistoryStreamValue.dispose();
    searchActiveStreamValue.dispose();
    inviteFilterStreamValue.dispose();
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();
    focusNode.dispose();
    searchController.dispose();
  }
}
