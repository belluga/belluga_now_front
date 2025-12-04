import 'dart:async';

import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
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

  static const int _pageSize = 10;

  final searchController = TextEditingController();
  final focusNode = FocusNode();
  final scrollController = ScrollController();

  final displayedEventsStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const []);
  final isInitialLoadingStreamValue = StreamValue<bool>(defaultValue: true);
  final isPageLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final hasMoreStreamValue = StreamValue<bool>(defaultValue: true);
  final showHistoryStreamValue = StreamValue<bool>(defaultValue: false);
  final searchActiveStreamValue = StreamValue<bool>(defaultValue: false);
  final inviteFilterStreamValue =
      StreamValue<InviteFilter>(defaultValue: InviteFilter.none);

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _pendingInvitesSubscription;
  final List<EventModel> _fetchedEvents = [];
  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMore = true;

  Future<void> init() async {
    await _invitesRepository.init();
    _attachScrollListener();
    _listenForStatusChanges();
    await _refresh();
  }

  void _attachScrollListener() {
    scrollController.addListener(() {
      if (!_hasMore ||
          _isFetching ||
          isInitialLoadingStreamValue.value ||
          !hasMoreStreamValue.value) {
        return;
      }

      final position = scrollController.position;
      const threshold = 320.0;
      if (position.pixels + threshold >= position.maxScrollExtent) {
        loadNextPage();
      }
    });
  }

  Future<void> _refresh() async {
    await _waitForOngoingFetch();
    _currentPage = 1;
    _hasMore = true;
    hasMoreStreamValue.addValue(true);
    _fetchedEvents.clear();
    displayedEventsStreamValue.addValue(const []);
    isInitialLoadingStreamValue.addValue(true);
    await _fetchPage(page: 1);
    isInitialLoadingStreamValue.addValue(false);
  }

  Future<void> _waitForOngoingFetch() async {
    while (_isFetching) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> loadNextPage() async {
    if (!_hasMore || _isFetching) return;
    await _fetchPage(page: _currentPage + 1);
  }

  Future<void> _fetchPage({required int page}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (page > 1) {
      isPageLoadingStreamValue.addValue(true);
    }

    try {
      final result = await _scheduleRepository.getEventsPage(
        page: page,
        pageSize: _pageSize,
        showPastOnly: showHistoryStreamValue.value,
        searchQuery: searchController.text,
      );

      if (page == 1) {
        _fetchedEvents
          ..clear()
          ..addAll(result.events);
      } else {
        _fetchedEvents.addAll(result.events);
      }

      _hasMore = result.hasMore;
      hasMoreStreamValue.addValue(_hasMore);
      _currentPage = page;
      _applyInviteFilterAndPublish();
    } finally {
      _isFetching = false;
      isPageLoadingStreamValue.addValue(false);
    }
  }

  void toggleHistory() {
    final currentValue = showHistoryStreamValue.value;
    showHistoryStreamValue.addValue(!currentValue);
    _refresh();
  }

  void setInviteFilter(InviteFilter filter) {
    inviteFilterStreamValue.addValue(filter);
    _applyInviteFilterAndPublish();
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
    }
  }

  void toggleSearchMode() {
    setSearchActive(!searchActiveStreamValue.value);
  }

  Future<void> searchEvents(String query) async {
    await _refresh();
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

  void _applyInviteFilterAndPublish() {
    displayedEventsStreamValue.addValue(_applyInviteFilter(_fetchedEvents));
  }

  bool isEventConfirmed(String eventId) =>
      _userEventsRepository.isEventConfirmed(eventId);

  int pendingInviteCount(String eventId) =>
      _invitesRepository.pendingInvitesStreamValue.value
          .where((invite) => invite.eventId == eventId)
          .length;

  bool hasPendingInvite(String eventId) => pendingInviteCount(eventId) > 0;

  void _listenForStatusChanges() {
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();

    _confirmedEventsSubscription =
        _userEventsRepository.confirmedEventIdsStream.stream.listen((_) {
      _applyInviteFilterAndPublish();
    });
    _pendingInvitesSubscription =
        _invitesRepository.pendingInvitesStreamValue.stream.listen((_) {
      _applyInviteFilterAndPublish();
    });
  }

  @override
  void onDispose() {
    displayedEventsStreamValue.dispose();
    isInitialLoadingStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    hasMoreStreamValue.dispose();
    showHistoryStreamValue.dispose();
    searchActiveStreamValue.dispose();
    inviteFilterStreamValue.dispose();
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();
    focusNode.dispose();
    searchController.dispose();
    scrollController.dispose();
  }
}
