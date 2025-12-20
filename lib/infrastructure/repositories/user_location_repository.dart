import 'dart:async';

import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stream_value/core/stream_value.dart';

class UserLocationRepository implements UserLocationRepositoryContract {
  UserLocationRepository() {
    _loadFuture = _loadLastKnownSnapshot();
    unawaited(_loadFuture);
  }

  static const _trackingMinUpdateInterval = Duration(seconds: 2);
  static const _trackingPersistMinInterval = Duration(seconds: 60);

  static const _keyLat = 'last_location_lat';
  static const _keyLng = 'last_location_lng';
  static const _keyCapturedAt = 'last_location_captured_at';
  static const _keyAddress = 'last_location_address';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  late final Future<void> _loadFuture;

  StreamSubscription<Position>? _trackingSubscription;
  DateTime? _lastTrackingUpdateAt;
  bool _hasLiveFix = false;

  DateTime? _lastPersistedAt;
  CityCoordinate? _lastPersistedCoordinate;

  @override
  final userLocationStreamValue = StreamValue<CityCoordinate?>();

  @override
  final lastKnownLocationStreamValue = StreamValue<CityCoordinate?>();

  @override
  final lastKnownCapturedAtStreamValue = StreamValue<DateTime?>();

  @override
  final lastKnownAddressStreamValue = StreamValue<String?>();

  @override
  Future<void> ensureLoaded() => _loadFuture;

  @override
  Future<bool> warmUpIfPermitted() async {
    await ensureLoaded();
    return refreshIfPermitted(minInterval: Duration.zero);
  }

  @override
  Future<bool> refreshIfPermitted({
    Duration minInterval = const Duration(seconds: 30),
  }) async {
    await ensureLoaded();

    final hasAnyCoordinate = userLocationStreamValue.value != null ||
        lastKnownLocationStreamValue.value != null;

    if (_hasLiveFix &&
        minInterval > Duration.zero &&
        _lastTrackingUpdateAt != null &&
        DateTime.now().difference(_lastTrackingUpdateAt!) < minInterval) {
      return true;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return hasAnyCoordinate;

    final permission = await Geolocator.checkPermission();
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!granted) return hasAnyCoordinate;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );

    await _applyLiveFix(
      position,
      shouldPersist: true,
    );
    return userLocationStreamValue.value != null ||
        lastKnownLocationStreamValue.value != null;
  }

  @override
  Future<void> setLastKnownAddress(String? address) async {
    if (address == null || address.trim().isEmpty) {
      lastKnownAddressStreamValue.addValue(null);
      await _storage.delete(key: _keyAddress);
      return;
    }
    final normalized = address.trim();
    lastKnownAddressStreamValue.addValue(normalized);
    await _storage.write(key: _keyAddress, value: normalized);
  }

  @override
  Future<String?> resolveUserLocation() async {
    await ensureLoaded();

    final _currentLocation = userLocationStreamValue.value;

    if (_currentLocation != null && _hasLiveFix) {
      return null;
    }

    return await _getCurrentUserLocation();
  }

  Future<String?> _getCurrentUserLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    if (!serviceEnabled) {
      return Future.value(
          'Ative os servicos de localizacao para ver sua posicao. Exibindo pontos padrao da cidade.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return Future.value(
          'Permita o acesso a localizacao para localizar pontos proximos. Exibindo pontos padrao da cidade.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );

    await _applyLiveFix(
      position,
      shouldPersist: true,
    );

    return null;
  }

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async {
    await ensureLoaded();

    if (_trackingSubscription != null) {
      return true;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return userLocationStreamValue.value != null ||
          lastKnownLocationStreamValue.value != null;
    }

    final permission = await Geolocator.checkPermission();
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!granted) {
      return userLocationStreamValue.value != null ||
          lastKnownLocationStreamValue.value != null;
    }

    final settings = switch (mode) {
      LocationTrackingMode.mapForeground => const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      LocationTrackingMode.lowPower => const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 150,
        ),
    };

    _trackingSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (pos) async {
        final now = DateTime.now();
        if (_lastTrackingUpdateAt != null &&
            now.difference(_lastTrackingUpdateAt!) < _trackingMinUpdateInterval) {
          return;
        }
        _lastTrackingUpdateAt = now;

        final shouldPersist = _shouldPersistNow(now);
        await _applyLiveFix(
          pos,
          shouldPersist: shouldPersist,
        );
      },
      onError: (_) {
        // Non-fatal: keep last known snapshot.
      },
    );

    return true;
  }

  @override
  Future<void> stopTracking() async {
    final sub = _trackingSubscription;
    _trackingSubscription = null;
    await sub?.cancel();
  }

  Future<void> _applyLiveFix(
    Position position, {
    required bool shouldPersist,
  }) async {
    final coordinate = CityCoordinate(
      latitudeValue: LatitudeValue()..parse(position.latitude.toString()),
      longitudeValue: LongitudeValue()..parse(position.longitude.toString()),
    );

    _hasLiveFix = true;
    userLocationStreamValue.addValue(coordinate);

    if (shouldPersist) {
      await _persistLastKnownLocation(coordinate);
    }
  }

  Future<void> _persistLastKnownLocation(CityCoordinate coordinate) async {
    lastKnownLocationStreamValue.addValue(coordinate);
    final now = DateTime.now();
    lastKnownCapturedAtStreamValue.addValue(now);

    _lastPersistedAt = now;
    _lastPersistedCoordinate = coordinate;

    await Future.wait([
      _storage.write(key: _keyLat, value: coordinate.latitude.toString()),
      _storage.write(key: _keyLng, value: coordinate.longitude.toString()),
      _storage.write(key: _keyCapturedAt, value: now.toIso8601String()),
    ]);
  }

  Future<void> _loadLastKnownSnapshot() async {
    try {
      final values = await Future.wait([
        _storage.read(key: _keyLat),
        _storage.read(key: _keyLng),
        _storage.read(key: _keyCapturedAt),
        _storage.read(key: _keyAddress),
      ]);
      final lat = double.tryParse(values[0] ?? '');
      final lng = double.tryParse(values[1] ?? '');
      if (lat == null || lng == null) {
        return;
      }

      final coordinate = CityCoordinate(
        latitudeValue: LatitudeValue()..parse(lat.toString()),
        longitudeValue: LongitudeValue()..parse(lng.toString()),
      );

      lastKnownLocationStreamValue.addValue(coordinate);
      final capturedAtRaw = values[2];
      final capturedAt =
          capturedAtRaw != null ? DateTime.tryParse(capturedAtRaw) : null;
      lastKnownCapturedAtStreamValue.addValue(capturedAt);

      final address = values[3];
      lastKnownAddressStreamValue.addValue(address);

      // Provide a best-effort default for consumers that use only `userLocationStreamValue`.
      userLocationStreamValue.addValue(coordinate);
      _hasLiveFix = false;
      _lastPersistedAt = capturedAt;
      _lastPersistedCoordinate = coordinate;
    } catch (_) {
      // Ignore cache load failures.
    }
  }

  bool _shouldPersistNow(DateTime now) {
    final lastAt = _lastPersistedAt;
    if (lastAt == null) {
      return true;
    }
    if (now.difference(lastAt) >= _trackingPersistMinInterval) {
      return true;
    }

    final lastCoordinate = _lastPersistedCoordinate;
    final current = userLocationStreamValue.value;
    if (lastCoordinate == null || current == null) {
      return true;
    }

    final deltaLat = (lastCoordinate.latitude - current.latitude).abs();
    final deltaLng = (lastCoordinate.longitude - current.longitude).abs();
    // Fast approximation: ~111km per degree.
    final approxMeters = ((deltaLat + deltaLng) * 111000.0);
    return approxMeters >= 100;
  }
}
