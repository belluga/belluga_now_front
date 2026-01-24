import 'dart:async';

import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantHomeAgendaController
    implements Disposable, AgendaAppBarController {
  TenantHomeAgendaController({
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
            appDataRepository ?? GetIt.I.get<AppDataRepository>();

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;
  final UserLocationRepositoryContract? _userLocationRepository;
  final AppDataRepository _appDataRepository;

  static const int _pageSize = 10;
  static const double _defaultRadiusMeters = 50000.0;

  @override
  final searchController = TextEditingController();
  @override
  final focusNode = FocusNode();

  final displayedEventsStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const []);
  final isInitialLoadingStreamValue = StreamValue<bool>(defaultValue: true);
  final isPageLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final hasMoreStreamValue = StreamValue<bool>(defaultValue: true);
  @override
  final showHistoryStreamValue = StreamValue<bool>(defaultValue: false);
  @override
  final searchActiveStreamValue = StreamValue<bool>(defaultValue: false);
  @override
  final inviteFilterStreamValue =
      StreamValue<InviteFilter>(defaultValue: InviteFilter.none);
  @override
  final radiusMetersStreamValue =
      StreamValue<double>(defaultValue: _defaultRadiusMeters);

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _appDataRepository.maxRadiusMetersStreamValue;

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _pendingInvitesSubscription;
  StreamSubscription? _userLocationSubscription;
  StreamSubscription? _radiusSubscription;
  final List<EventModel> _fetchedEvents = [];
  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMore = true;
  bool _isAutoPaging = false;
  bool _isDisposed = false;

  void _setValue<T>(StreamValue<T> stream, T value) {
    if (_isDisposed) return;
    stream.addValue(value);
  }

  Future<void> init({bool startWithHistory = false}) async {
    await _invitesRepository.init();
    _setValue(showHistoryStreamValue, startWithHistory);
    final maxRadius = _appDataRepository.maxRadiusMeters;
    _setValue(radiusMetersStreamValue, maxRadius);
    _listenForStatusChanges();
    _listenForLocationChanges();
    _listenForRadiusChanges();
    await _refresh();
  }

  Future<void> _refresh() async {
    await _waitForOngoingFetch();
    _currentPage = 1;
    _hasMore = true;
    _setValue(hasMoreStreamValue, true);
    _fetchedEvents.clear();
    _setValue(displayedEventsStreamValue, const <EventModel>[]);
    _setValue(isInitialLoadingStreamValue, true);
    await _fetchPage(page: 1);
    _setValue(isInitialLoadingStreamValue, false);
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
      _setValue(isPageLoadingStreamValue, true);
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
      _setValue(hasMoreStreamValue, _hasMore);
      _currentPage = page;
      _applyFiltersAndPublish();
    } finally {
      _isFetching = false;
      _setValue(isPageLoadingStreamValue, false);
    }
  }

  @override
  void toggleHistory() {
    final currentValue = showHistoryStreamValue.value;
    _setValue(showHistoryStreamValue, !currentValue);
    _refresh();
  }

  void setInviteFilter(InviteFilter filter) {
    _setValue(inviteFilterStreamValue, filter);
    _applyFiltersAndPublish();
  }

  @override
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
    _setValue(searchActiveStreamValue, active);
    if (active) {
      focusNode.requestFocus();
    } else {
      focusNode.unfocus();
    }
  }

  @override
  void toggleSearchMode() {
    setSearchActive(!searchActiveStreamValue.value);
  }

  @override
  void setRadiusMeters(double meters) {
    if (meters <= 0) return;
    _setValue(radiusMetersStreamValue, meters);
    _applyFiltersAndPublish();
  }

  void setInitialSearchQuery(String? query) {
    final normalized = query?.trim() ?? '';
    if (normalized.isEmpty) return;
    searchController.text = normalized;
    searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: normalized.length));
    _refresh();
  }

  @override
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
    final inviteFiltered = _applyInviteFilter(_fetchedEvents);
    final radiusFiltered = _applyRadiusFilter(inviteFiltered);
    _setValue(displayedEventsStreamValue, radiusFiltered);
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
      _setValue(radiusMetersStreamValue, clamped);
      _applyFiltersAndPublish();
    });
  }

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
  }
}
