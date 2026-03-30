import 'dart:async';

import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  late TenantHomeController controller;
  late _FakeUserEventsRepository userEventsRepository;
  late _FakeUserLocationRepository userLocationRepository;

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());
    userEventsRepository = _FakeUserEventsRepository();
    userLocationRepository = _FakeUserLocationRepository();
    controller = TenantHomeController(
      userEventsRepository: userEventsRepository,
      userLocationRepository: userLocationRepository,
    );
  });

  tearDown(() async {
    controller.onDispose();
    await GetIt.I.reset();
  });

  test('init initializes dependencies', () async {
    await controller.init();

    expect(userEventsRepository.fetchMyEventsCallCount, 1);
  });

  test('filters my events to confirmed and upcoming', () async {
    final now = DateTime.now();
    const upcomingId = '507f1f77bcf86cd799439011';
    const pastId = '507f1f77bcf86cd799439012';
    final upcomingEvent = buildVenueEventResume(
      id: upcomingId,
      slug: 'slug-1',
      title: 'Upcoming Event Title Long Enough',
      imageUri: Uri.parse('http://example.com/img.jpg'),
      startDateTime: now.add(const Duration(hours: 1)),
      location: 'Valid Location Name Long Enough',
    );
    final pastEvent = buildVenueEventResume(
      id: pastId,
      slug: 'slug-2',
      title: 'Past Event Title Long Enough',
      imageUri: Uri.parse('http://example.com/img.jpg'),
      startDateTime: now.subtract(const Duration(days: 1)),
      location: 'Valid Location Name Long Enough',
    );

    userEventsRepository.setEvents([upcomingEvent, pastEvent]);
    await controller.init();

    expect(
      controller.myEventsFilteredStreamValue.value.map((e) => e.id),
      contains(upcomingId),
    );
    expect(
      controller.myEventsFilteredStreamValue.value.map((e) => e.id),
      isNot(contains(pastId)),
    );
  });

  test('init does not hang when location warm-up stalls', () async {
    controller.onDispose();
    userLocationRepository.neverCompleteWarmUp = true;
    controller = TenantHomeController(
      userEventsRepository: userEventsRepository,
      userLocationRepository: userLocationRepository,
      locationWarmUpTimeout: const Duration(milliseconds: 20),
    );

    await controller.init();

    expect(userEventsRepository.fetchMyEventsCallCount, 1);
  });

  test('init continues when confirmed ids refresh fails', () async {
    controller.onDispose();
    userEventsRepository.throwOnRefreshConfirmedIds = true;
    controller = TenantHomeController(
      userEventsRepository: userEventsRepository,
      userLocationRepository: userLocationRepository,
    );

    await controller.init();

    expect(userEventsRepository.fetchMyEventsCallCount, 1);
  });
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': const [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
      },
    ],
    'domains': const ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': const {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
      remoteData: remoteData, localInfo: localInfo);
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  _FakeUserEventsRepository({List<VenueEventResume>? events})
      : _events = events ?? [];

  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
          defaultValue: {});
  List<VenueEventResume> _events;
  int fetchMyEventsCallCount = 0;
  bool throwOnRefreshConfirmedIds = false;

  void setEvents(List<VenueEventResume> events) {
    _events = events;
  }

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async {
    fetchMyEventsCallCount += 1;
    return _events;
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<void> confirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}

  @override
  Future<void> unconfirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}

  @override
  Future<void> refreshConfirmedEventIds() async {
    if (throwOnRefreshConfirmedIds) {
      throw Exception('forced confirmed ids failure');
    }
  }

  @override
  UserEventsRepositoryContractPrimBool isEventConfirmed(
          UserEventsRepositoryContractPrimString eventId) =>
      userEventsRepoBool(
        confirmedEventIdsStream.value.contains(eventId),
        defaultValue: false,
        isRequired: true,
      );
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  bool neverCompleteWarmUp = false;

  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>(defaultValue: null);

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>(defaultValue: null);

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(Object? address) async {
    lastKnownAddressStreamValue.addValue(address as dynamic);
  }

  @override
  Future<bool> warmUpIfPermitted() async {
    if (neverCompleteWarmUp) {
      return Completer<bool>().future;
    }
    return false;
  }

  @override
  Future<bool> refreshIfPermitted({Object? minInterval}) async => false;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<bool> startTracking(
          {LocationTrackingMode mode =
              LocationTrackingMode.mapForeground}) async =>
      false;

  @override
  Future<void> stopTracking() async {}
}
