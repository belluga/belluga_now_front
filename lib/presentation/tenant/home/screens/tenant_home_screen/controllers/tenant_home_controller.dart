import 'dart:async';

import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantHomeController implements Disposable {
  TenantHomeController({
    UserEventsRepositoryContract? userEventsRepository,
    UserLocationRepositoryContract? userLocationRepository,
  })  : _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _userLocationRepository = userLocationRepository ??
            (GetIt.I.isRegistered<UserLocationRepositoryContract>()
                ? GetIt.I.get<UserLocationRepositoryContract>()
                : null);

  static const Duration _assumedEventDuration = Duration(hours: 3);

  final UserEventsRepositoryContract _userEventsRepository;
  final UserLocationRepositoryContract? _userLocationRepository;
  final ScrollController _scrollController = ScrollController();

  final StreamValue<String?> userAddressStreamValue = StreamValue<String?>();
  final StreamValue<List<VenueEventResume>> myEventsFilteredStreamValue =
      StreamValue<List<VenueEventResume>>(defaultValue: const []);

  ScrollController get scrollController => _scrollController;

  StreamValue<Set<String>> get confirmedIdsStreamValue =>
      _userEventsRepository.confirmedEventIdsStream;

  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _userLocationSubscription;
  bool _isDisposed = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await loadMyEvents();

    await _userLocationRepository?.warmUpIfPermitted();
    _listenUserLocation();
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
        _userEventsRepository.confirmedEventIdsStream.stream.listen((_) {
      unawaited(loadMyEvents());
    });
  }

  void _updateMyEvents(List<VenueEventResume> events) {
    if (_isDisposed) return;
    myEventsFilteredStreamValue.addValue(_filterConfirmedUpcoming(events));
  }

  void _listenUserLocation() {
    final repo = _userLocationRepository;
    if (repo == null) return;

    final cachedAddress = repo.lastKnownAddressStreamValue.value;
    if (cachedAddress != null && cachedAddress.trim().isNotEmpty) {
      if (_isDisposed) return;
      userAddressStreamValue.addValue(cachedAddress);
    }

    unawaited(_updateUserAddress(repo.userLocationStreamValue.value));

    _userLocationSubscription?.cancel();
    _userLocationSubscription = repo.userLocationStreamValue.stream.listen(
      (coordinate) {
        unawaited(_updateUserAddress(coordinate));
      },
    );
  }

  Future<void> _updateUserAddress(CityCoordinate? coordinate) async {
    if (_isDisposed) return;
    if (coordinate == null) {
      if (_isDisposed) return;
      userAddressStreamValue.addValue(null);
      return;
    }

    try {
      final geocoderPresent = await isPresent();
      if (!geocoderPresent) {
        if (_isDisposed) return;
        userAddressStreamValue.addValue('Localizacao detectada');
        return;
      }

      try {
        await setLocaleIdentifier('pt_BR');
      } catch (_) {
        // Non-fatal: platform may ignore locale overrides.
      }

      final placemarks = await placemarkFromCoordinates(
        coordinate.latitude,
        coordinate.longitude,
      );
      final first = placemarks.isNotEmpty ? placemarks.first : null;
      final streetParts = <String>[
        if ((first?.thoroughfare ?? '').trim().isNotEmpty) first!.thoroughfare!,
        if ((first?.subThoroughfare ?? '').trim().isNotEmpty)
          first!.subThoroughfare!,
      ];
      final streetLabel =
          streetParts.isNotEmpty ? streetParts.join(', ') : null;

      final parts = <String>[
        if ((streetLabel ?? '').trim().isNotEmpty) streetLabel!,
        if ((first?.subLocality ?? '').trim().isNotEmpty) first!.subLocality!,
        if ((first?.locality ?? '').trim().isNotEmpty) first!.locality!,
        if ((first?.administrativeArea ?? '').trim().isNotEmpty)
          first!.administrativeArea!,
      ];
      final label = parts.isNotEmpty ? parts.join(', ') : null;
      await _userLocationRepository?.setLastKnownAddress(label);
      if (_isDisposed) return;
      userAddressStreamValue.addValue(
        (label == null || label.trim().isEmpty)
            ? 'Localizacao detectada'
            : label,
      );
    } catch (e, stackTrace) {
      debugPrint('[TenantHomeController] reverse geocode failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      final previous = userAddressStreamValue.value;
      if (previous != null && previous.trim().isNotEmpty) {
        return;
      }
      await _userLocationRepository?.setLastKnownAddress('Localizacao detectada');
      if (_isDisposed) return;
      userAddressStreamValue.addValue('Localizacao detectada');
    }
  }

  List<VenueEventResume> _filterConfirmedUpcoming(
    List<VenueEventResume> events,
  ) {
    final now = DateTime.now();
    return events.where((event) {
      final start = event.startDateTime;
      if (!start.isAfter(now)) {
        final end = start.add(_assumedEventDuration);
        return now.isBefore(end);
      }
      return true;
    }).toList();
  }

  String? firstMyEventSlug() {
    final events = myEventsFilteredStreamValue.value;
    if (events.isEmpty) return null;
    return events.first.slug;
  }

  String? distanceLabelForMyEvent(VenueEventResume event) {
    if (_isDisposed) return null;
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

  @override
  void onDispose() {
    _isDisposed = true;
    _confirmedEventsSubscription?.cancel();
    _userLocationSubscription?.cancel();
    _scrollController.dispose();
    myEventsFilteredStreamValue.dispose();
    userAddressStreamValue.dispose();
  }
}
