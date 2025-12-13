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

  static const _keyLat = 'last_location_lat';
  static const _keyLng = 'last_location_lng';
  static const _keyCapturedAt = 'last_location_captured_at';
  static const _keyAddress = 'last_location_address';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  late final Future<void> _loadFuture;

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
    final current = userLocationStreamValue.value;
    if (current != null) return true;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!granted) return false;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );

    final coordinate = CityCoordinate(
      latitudeValue: LatitudeValue()..parse(position.latitude.toString()),
      longitudeValue: LongitudeValue()..parse(position.longitude.toString()),
    );
    userLocationStreamValue.addValue(coordinate);
    await _persistLastKnownLocation(coordinate);
    return true;
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

    final _currentLocation = userLocationStreamValue.value;

    if(_currentLocation != null){
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

    final coordinate = CityCoordinate(
      latitudeValue: LatitudeValue()..parse(position.latitude.toString()),
      longitudeValue: LongitudeValue()..parse(position.longitude.toString()),
    );

    userLocationStreamValue.addValue(coordinate);
    await _persistLastKnownLocation(coordinate);

    return null;
  }

  Future<void> _persistLastKnownLocation(CityCoordinate coordinate) async {
    lastKnownLocationStreamValue.addValue(coordinate);
    final now = DateTime.now();
    lastKnownCapturedAtStreamValue.addValue(now);

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
    } catch (_) {
      // Ignore cache load failures.
    }
  }
}
