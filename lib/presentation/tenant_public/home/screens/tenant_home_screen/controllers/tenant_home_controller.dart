import 'dart:async';

import 'package:belluga_now/domain/app_data/location_origin_settings.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/presentation/shared/location_permission/location_origin_message_resolver.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/models/home_location_status_state.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantHomeController implements Disposable {
  TenantHomeController({
    UserEventsRepositoryContract? userEventsRepository,
    UserLocationRepositoryContract? userLocationRepository,
    AppDataRepositoryContract? appDataRepository,
    LocationOriginServiceContract? locationOriginService,
  })  : _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _locationOriginService = locationOriginService ??
            GetIt.I.get<LocationOriginServiceContract>();

  static const Duration _assumedEventDuration = Duration(hours: 3);

  final UserEventsRepositoryContract _userEventsRepository;
  final AppDataRepositoryContract _appDataRepository;
  final LocationOriginServiceContract _locationOriginService;
  final AppData _appData = GetIt.I.get<AppData>();
  final ScrollController _scrollController = ScrollController();

  final StreamValue<HomeLocationStatusState?> homeLocationStatusStreamValue =
      StreamValue<HomeLocationStatusState?>(defaultValue: null);
  final StreamValue<List<VenueEventResume>> myEventsFilteredStreamValue =
      StreamValue<List<VenueEventResume>>(defaultValue: const []);

  ScrollController get scrollController => _scrollController;

  StreamValue<Set<UserEventsRepositoryContractPrimString>>
      get confirmedIdsStreamValue =>
          _userEventsRepository.confirmedOccurrenceIdsStream;
  AppData get appData => _appData;

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _homeLocationStatusSubscription;
  bool _isDisposed = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _userEventsRepository.refreshConfirmedOccurrenceIds();
    } catch (error) {
      debugPrint('TenantHomeController.init confirmed ids failed: $error');
    }
    await loadMyEvents();
    _listenLocationOrigin();
    _listenConfirmedEvents();
  }

  Future<void> loadMyEvents() async {
    final previousValue = myEventsFilteredStreamValue.value;
    try {
      final events = await _userEventsRepository.fetchMyEvents();
      if (_isDisposed) return;
      _updateMyEvents(events);
    } catch (_) {
      if (_isDisposed) return;
      myEventsFilteredStreamValue.addValue(previousValue);
    }
  }

  void _listenConfirmedEvents() {
    _confirmedEventsSubscription?.cancel();
    _confirmedEventsSubscription =
        _userEventsRepository.confirmedOccurrenceIdsStream.stream.listen((_) {
      unawaited(loadMyEvents());
    });
  }

  void _updateMyEvents(List<VenueEventResume> events) {
    if (_isDisposed) return;
    myEventsFilteredStreamValue.addValue(_filterConfirmedUpcoming(events));
  }

  void _listenLocationOrigin() {
    _publishHomeLocationStatus(_appDataRepository.locationOriginSettings);
    _homeLocationStatusSubscription?.cancel();
    _homeLocationStatusSubscription = _appDataRepository
        .locationOriginSettingsStreamValue.stream
        .listen(_publishHomeLocationStatus);
  }

  List<VenueEventResume> _filterConfirmedUpcoming(
    List<VenueEventResume> events,
  ) {
    final now = DateTime.now();
    return events.where((event) {
      final start = event.startDateTime;
      if (start.isAfter(now)) {
        return true;
      }
      final end = event.endDateTime ?? start.add(_assumedEventDuration);
      return now.isBefore(end) || now.isAtSameMomentAs(end);
    }).toList();
  }

  String? firstMyEventSlug() {
    final events = myEventsFilteredStreamValue.value;
    if (events.isEmpty) return null;
    return events.first.slug;
  }

  String? distanceLabelForMyEvent(VenueEventResume event) {
    if (_isDisposed) return null;
    final userCoordinate = _resolveHomeDistanceReferenceCoordinate();
    final eventCoordinate = event.coordinate;
    if (userCoordinate == null || eventCoordinate == null) {
      return null;
    }
    final distanceMeters = haversineDistanceMeters(
      coordinateA: userCoordinate,
      coordinateB: eventCoordinate,
    );
    return _formatDistanceLabel(distanceMeters.value);
  }

  void _publishHomeLocationStatus(LocationOriginSettings? settings) {
    if (_isDisposed) return;
    if (settings == null) {
      homeLocationStatusStreamValue.addValue(null);
      return;
    }
    homeLocationStatusStreamValue.addValue(
      HomeLocationStatusState(
        statusText: settings.usesUserLiveLocation
            ? 'Usando sua localização.'
            : 'Usando localização fixa.',
        dialogTitle: settings.usesUserLiveLocation
            ? 'Usando sua localização'
            : 'Usando localização fixa',
        dialogMessage: _dialogMessageForLocationOrigin(settings),
      ),
    );
  }

  String _dialogMessageForLocationOrigin(
    LocationOriginSettings settings,
  ) {
    return LocationOriginMessageResolver.fromSettings(
      settings: settings,
      appName: _appData.nameValue.value,
    );
  }

  String _formatDistanceLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  CityCoordinate? _resolveHomeDistanceReferenceCoordinate() {
    return _locationOriginService.resolveCached().effectiveCoordinate;
  }

  @override
  void onDispose() {
    _isDisposed = true;
    _confirmedEventsSubscription?.cancel();
    _homeLocationStatusSubscription?.cancel();
    _scrollController.dispose();
    homeLocationStatusStreamValue.dispose();
    myEventsFilteredStreamValue.dispose();
  }
}
