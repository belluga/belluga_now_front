import 'dart:async';

import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantHomeAgendaController implements Disposable, AgendaAppBarController {
  TenantHomeAgendaController({
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
    UserLocationRepositoryContract? userLocationRepository,
    AppDataRepositoryContract? appDataRepository,
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
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>();

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;
  final UserLocationRepositoryContract? _userLocationRepository;
  final AppDataRepositoryContract _appDataRepository;

  static const int _pageSize = 10;
  static const double _fallbackRadiusMeters = 50000.0;

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
      StreamValue<double>(defaultValue: _fallbackRadiusMeters);

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _appDataRepository.maxRadiusMetersStreamValue;

  @override
  double get minRadiusMeters => _resolveMinRadiusMeters();

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _pendingInvitesSubscription;
  StreamSubscription? _userLocationSubscription;
  StreamSubscription? _radiusSubscription;
  final List<EventModel> _fetchedEvents = [];
  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMore = true;
  bool _isDisposed = false;
  double? _effectiveOriginLat;
  double? _effectiveOriginLng;

  void _setValue<T>(StreamValue<T> stream, T value) {
    if (_isDisposed) return;
    stream.addValue(value);
  }

  Future<void> init({bool startWithHistory = false}) async {
    await _invitesRepository.init();
    await _userEventsRepository.refreshConfirmedEventIds();
    _setValue(showHistoryStreamValue, startWithHistory);
    _setValue(radiusMetersStreamValue, _resolveDefaultRadiusMeters());
    _listenForStatusChanges();
    _listenForLocationChanges();
    _listenForRadiusChanges();
    await _resolveEffectiveOrigin(warmUpIfPossible: true);
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
    try {
      await _resolveEffectiveOrigin(warmUpIfPossible: true);
      if (!_hasEffectiveOrigin) {
        _hasMore = false;
        _setValue(hasMoreStreamValue, false);
        _setValue(displayedEventsStreamValue, const <EventModel>[]);
        return;
      }

      _hasMore = true;
      _setValue(hasMoreStreamValue, true);
      await _fetchPage(page: 1);
    } catch (error) {
      debugPrint('TenantHomeAgendaController._refresh failed: $error');
    } finally {
      _setValue(isInitialLoadingStreamValue, false);
    }
  }

  Future<void> _waitForOngoingFetch() async {
    while (_isFetching) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> loadNextPage() async {
    if (!_hasEffectiveOrigin || !_hasMore || _isFetching) return;
    await _fetchPage(page: _currentPage + 1);
  }

  Future<void> _fetchPage({required int page}) async {
    if (_isFetching || !_hasEffectiveOrigin) return;
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
        confirmedOnly:
            inviteFilterStreamValue.value == InviteFilter.confirmedOnly,
        originLat: _effectiveOriginLat,
        originLng: _effectiveOriginLng,
        maxDistanceMeters: radiusMetersStreamValue.value,
      );

      if (page == 1) {
        _fetchedEvents
          ..clear()
          ..addAll(result.events);
      } else {
        _fetchedEvents.addAll(result.events);
      }

      _hasMore = result.hasMore && result.events.length >= _pageSize;
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
    _setValue(radiusMetersStreamValue, _clampRadiusMeters(meters));
    unawaited(_refresh());
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

  void _applyFiltersAndPublish() {
    final inviteFiltered = _applyInviteFilter(_fetchedEvents);
    _setValue(displayedEventsStreamValue, inviteFiltered);
  }

  bool isEventConfirmed(String eventId) =>
      _userEventsRepository.isEventConfirmed(eventId);

  int pendingInviteCount(String eventId) =>
      _invitesRepository.pendingInvitesStreamValue.value
          .where((invite) => invite.eventId == eventId)
          .length;

  String? distanceLabelFor(VenueEventResume event) {
    final userCoordinate =
        _userLocationRepository?.userLocationStreamValue.value ??
            _userLocationRepository?.lastKnownLocationStreamValue.value;
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
      unawaited(_handleLocationUpdate());
    });
  }

  void _listenForRadiusChanges() {
    _radiusSubscription?.cancel();
    _radiusSubscription =
        _appDataRepository.maxRadiusMetersStreamValue.stream.listen((_) {
      final current = radiusMetersStreamValue.value;
      final clamped = _clampRadiusMeters(current);
      _setValue(radiusMetersStreamValue, clamped);
      unawaited(_refresh());
    });
  }

  bool get _hasEffectiveOrigin =>
      _effectiveOriginLat != null && _effectiveOriginLng != null;

  Future<void> _handleLocationUpdate() async {
    final changed = await _resolveEffectiveOrigin(warmUpIfPossible: false);
    if (!changed) {
      return;
    }
    await _refresh();
  }

  Future<bool> _resolveEffectiveOrigin({
    required bool warmUpIfPossible,
  }) async {
    final currentLat = _effectiveOriginLat;
    final currentLng = _effectiveOriginLng;

    final userCoordinate = await _resolveUserCoordinate(
      warmUpIfPossible: warmUpIfPossible,
    );
    if (userCoordinate != null) {
      _effectiveOriginLat = userCoordinate.latitude;
      _effectiveOriginLng = userCoordinate.longitude;
      return _effectiveOriginLat != currentLat ||
          _effectiveOriginLng != currentLng;
    }

    final tenantDefaultOrigin = _resolveTenantDefaultOriginCoordinate();
    if (tenantDefaultOrigin != null) {
      _effectiveOriginLat = tenantDefaultOrigin.latitude;
      _effectiveOriginLng = tenantDefaultOrigin.longitude;
      return _effectiveOriginLat != currentLat ||
          _effectiveOriginLng != currentLng;
    }

    _effectiveOriginLat = null;
    _effectiveOriginLng = null;
    return currentLat != null || currentLng != null;
  }

  Future<CityCoordinate?> _resolveUserCoordinate({
    required bool warmUpIfPossible,
  }) async {
    final repository = _userLocationRepository;
    if (repository == null) {
      return null;
    }

    if (warmUpIfPossible) {
      try {
        await repository.warmUpIfPermitted();
      } on Object {
        // Best-effort warm up.
      }
    }

    return repository.userLocationStreamValue.value ??
        repository.lastKnownLocationStreamValue.value;
  }

  CityCoordinate? _resolveTenantDefaultOriginCoordinate() {
    try {
      return _appDataRepository.appData.tenantDefaultOrigin;
    } on Object {
      return null;
    }
  }

  double _resolveMinRadiusMeters() {
    final configured = _configuredMinRadiusMeters();
    return configured > 0 ? configured : 1000;
  }

  double _resolveDefaultRadiusMeters() {
    final configured = _configuredDefaultRadiusMeters();
    if (configured > 0) {
      return _clampRadiusMeters(configured);
    }
    return _clampRadiusMeters(_appDataRepository.maxRadiusMeters);
  }

  double _configuredMinRadiusMeters() {
    try {
      return _appDataRepository.appData.mapRadiusMinMeters;
    } on Object {
      return 1000;
    }
  }

  double _configuredDefaultRadiusMeters() {
    try {
      return _appDataRepository.appData.mapRadiusDefaultMeters;
    } on Object {
      return _appDataRepository.maxRadiusMeters;
    }
  }

  double _clampRadiusMeters(double meters) {
    final min = _resolveMinRadiusMeters();
    final max = _appDataRepository.maxRadiusMeters;
    final effectiveMax = max < min ? min : max;
    return meters.clamp(min, effectiveMax).toDouble();
  }

  @override
  void onDispose() {
    _isDisposed = true;
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();
    _userLocationSubscription?.cancel();
    _radiusSubscription?.cancel();
    displayedEventsStreamValue.dispose();
    isInitialLoadingStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    hasMoreStreamValue.dispose();
    showHistoryStreamValue.dispose();
    searchActiveStreamValue.dispose();
    inviteFilterStreamValue.dispose();
    radiusMetersStreamValue.dispose();
    focusNode.dispose();
    searchController.dispose();
  }
}
