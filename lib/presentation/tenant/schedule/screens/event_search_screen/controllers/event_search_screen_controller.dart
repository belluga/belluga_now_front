import 'dart:async';

import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class EventSearchScreenController implements Disposable, AgendaAppBarController {
  EventSearchScreenController({
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
    UserLocationRepositoryContract? userLocationRepository,
    AppDataRepository? appDataRepository,
  })  : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _userLocationRepository = userLocationRepository ??
            (GetIt.I.isRegistered<UserLocationRepositoryContract>()
                ? GetIt.I.get<UserLocationRepositoryContract>()
                : null),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepository>() {
    _initializeStateHolders();
  }

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;
  final UserLocationRepositoryContract? _userLocationRepository;
  final AppDataRepository _appDataRepository;

  static const int _pageSize = 10;
  static const double _defaultRadiusMeters = 50000.0;

  late TextEditingController searchController;
  late FocusNode focusNode;
  late ScrollController scrollController;

  late StreamValue<List<EventModel>> displayedEventsStreamValue;
  late StreamValue<bool> isInitialLoadingStreamValue;
  late StreamValue<bool> isPageLoadingStreamValue;
  late StreamValue<bool> hasMoreStreamValue;
  late StreamValue<bool> showHistoryStreamValue;
  late StreamValue<bool> searchActiveStreamValue;
  late StreamValue<InviteFilter> inviteFilterStreamValue;
  late StreamValue<double> radiusMetersStreamValue;

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _pendingInvitesSubscription;
  StreamSubscription? _userLocationSubscription;
  StreamSubscription? _radiusSubscription;
  final List<EventModel> _fetchedEvents = [];
  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMore = true;
  bool _isScrollListenerAttached = false;
  bool _isDisposed = false;
  bool _isAutoPaging = false;

  void _initializeStateHolders() {
    searchController = TextEditingController();
    focusNode = FocusNode();
    scrollController = ScrollController();
    displayedEventsStreamValue =
        StreamValue<List<EventModel>>(defaultValue: const []);
    isInitialLoadingStreamValue = StreamValue<bool>(defaultValue: true);
    isPageLoadingStreamValue = StreamValue<bool>(defaultValue: false);
    hasMoreStreamValue = StreamValue<bool>(defaultValue: true);
    showHistoryStreamValue = StreamValue<bool>(defaultValue: false);
    searchActiveStreamValue = StreamValue<bool>(defaultValue: false);
    inviteFilterStreamValue =
        StreamValue<InviteFilter>(defaultValue: InviteFilter.none);
    radiusMetersStreamValue =
        StreamValue<double>(defaultValue: _defaultRadiusMeters);
    _isScrollListenerAttached = false;
  }

  void _resetInternalState() {
    _fetchedEvents.clear();
    _currentPage = 1;
    _isFetching = false;
    _hasMore = true;
  }

  Future<void> init({bool startWithHistory = false}) async {
    if (_isDisposed) {
      _initializeStateHolders();
      _isDisposed = false;
    }
    await _invitesRepository.init();
    _resetInternalState();
    showHistoryStreamValue.addValue(startWithHistory);
    final maxRadius = _appDataRepository.maxRadiusMeters;
    radiusMetersStreamValue.addValue(maxRadius);
    _attachScrollListener();
    _listenForStatusChanges();
    _listenForLocationChanges();
    _listenForRadiusChanges();
    await _refresh();
  }

  void _attachScrollListener() {
    if (_isScrollListenerAttached) return;
    _isScrollListenerAttached = true;
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
    if (page > 1 && !_isDisposed) {
      isPageLoadingStreamValue.addValue(true);
    }

    try {
      final result = await _scheduleRepository.getEventsPage(
        page: page,
        pageSize: _pageSize,
        showPastOnly: showHistoryStreamValue.value,
        searchQuery: searchController.text,
      );

      if (_isDisposed) return;
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
      _applyFiltersAndPublish();
    } finally {
      _isFetching = false;
      if (!_isDisposed) {
        isPageLoadingStreamValue.addValue(false);
      }
    }
  }

  void toggleHistory() {
    final currentValue = showHistoryStreamValue.value;
    showHistoryStreamValue.addValue(!currentValue);
    _refresh();
  }

  void setInviteFilter(InviteFilter filter) {
    inviteFilterStreamValue.addValue(filter);
    _applyFiltersAndPublish();
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

  void setRadiusMeters(double meters) {
    if (meters <= 0) return;
    radiusMetersStreamValue.addValue(meters);
    _applyFiltersAndPublish();
  }

  void setInitialSearchQuery(String? query) {
    final normalized = query?.trim() ?? '';
    if (normalized.isEmpty) return;
    searchController.text = normalized;
    searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: normalized.length));
    unawaited(_refresh());
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

  List<EventModel> _applyRadiusFilter(List<EventModel> events) {
    final userCoordinate = _userLocationRepository?.userLocationStreamValue.value;
    if (userCoordinate == null) return events;
    final radiusMeters = radiusMetersStreamValue.value;
    return events.where((event) {
      final eventCoordinate = event.coordinate;
      if (eventCoordinate == null) return false;
      final distanceMeters = haversineDistanceMeters(
        lat1: userCoordinate.latitude,
        lon1: userCoordinate.longitude,
        lat2: eventCoordinate.latitude,
        lon2: eventCoordinate.longitude,
      );
      return distanceMeters <= radiusMeters;
    }).toList();
  }

  void _applyFiltersAndPublish() {
    if (_isDisposed) return;
    final inviteFiltered = _applyInviteFilter(_fetchedEvents);
    final radiusFiltered = _applyRadiusFilter(inviteFiltered);
    displayedEventsStreamValue.addValue(radiusFiltered);
    _maybeAutoPage(radiusFiltered);
  }

  void _maybeAutoPage(List<EventModel> filtered) {
    if (filtered.isNotEmpty || !_hasMore || _isAutoPaging) {
      return;
    }
    unawaited(_autoPageToFirstMatch());
  }

  Future<void> _autoPageToFirstMatch() async {
    _isAutoPaging = true;
    try {
      while (_hasMore) {
        await _waitForOngoingFetch();
        if (!_hasMore) {
          break;
        }
        await _fetchPage(page: _currentPage + 1);
        if (displayedEventsStreamValue.value.isNotEmpty || !_hasMore) {
          break;
        }
      }
    } finally {
      _isAutoPaging = false;
    }
  }

  bool isEventConfirmed(String eventId) =>
      _userEventsRepository.isEventConfirmed(eventId);

  int pendingInviteCount(String eventId) =>
      _invitesRepository.pendingInvitesStreamValue.value
          .where((invite) => invite.eventId == eventId)
          .length;

  bool hasPendingInvite(String eventId) => pendingInviteCount(eventId) > 0;

  String? distanceLabelFor(VenueEventResume event) {
    final userCoordinate = _userLocationRepository?.userLocationStreamValue.value;
    final eventCoordinate = event.coordinate;
    if (userCoordinate == null || eventCoordinate == null) {
      return null;
    }
    final distanceMeters = haversineDistanceMeters(
      lat1: userCoordinate.latitude,
      lon1: userCoordinate.longitude,
      lat2: eventCoordinate.latitude,
      lon2: eventCoordinate.longitude,
    );
    return _formatDistanceLabel(distanceMeters);
  }

  String _formatDistanceLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _listenForStatusChanges() {
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();

    _confirmedEventsSubscription =
        _userEventsRepository.confirmedEventIdsStream.stream.listen((_) {
      _applyFiltersAndPublish();
    });
    _pendingInvitesSubscription =
        _invitesRepository.pendingInvitesStreamValue.stream.listen((_) {
      _applyFiltersAndPublish();
    });
  }

  void _listenForLocationChanges() {
    final repo = _userLocationRepository;
    if (repo == null) return;
    _userLocationSubscription?.cancel();
    _userLocationSubscription = repo.userLocationStreamValue.stream.listen((_) {
      _applyFiltersAndPublish();
    });
  }

  void _listenForRadiusChanges() {
    _radiusSubscription?.cancel();
    _radiusSubscription =
        _appDataRepository.maxRadiusMetersStreamValue.stream.listen((meters) {
      final current = radiusMetersStreamValue.value;
      final clamped = current > meters ? meters : current;
      radiusMetersStreamValue.addValue(clamped);
      _applyFiltersAndPublish();
    });
  }

  StreamValue<double> get maxRadiusMetersStreamValue =>
      _appDataRepository.maxRadiusMetersStreamValue;

  @override
  void onDispose() {
    _isDisposed = true;
    displayedEventsStreamValue.dispose();
    isInitialLoadingStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    hasMoreStreamValue.dispose();
    showHistoryStreamValue.dispose();
    searchActiveStreamValue.dispose();
    inviteFilterStreamValue.dispose();
    radiusMetersStreamValue.dispose();
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();
    _userLocationSubscription?.cancel();
    _radiusSubscription?.cancel();
    focusNode.dispose();
    searchController.dispose();
    scrollController.dispose();
  }
}
