import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
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
    final upcomingEvent = VenueEventResume(
      id: '1',
      slug: 'slug-1',
      titleValue: TitleValue()..parse('Upcoming Event Title Long Enough'),
      imageUriValue: ThumbUriValue(defaultValue: Uri.parse('http://example.com/img.jpg')),
      startDateTimeValue: DateTimeValue(defaultValue: now.add(const Duration(hours: 1))),
      locationValue: DescriptionValue()..parse('Valid Location Name Long Enough'),
      artists: [],
      tags: [],
    );
    final pastEvent = VenueEventResume(
      id: '2',
      slug: 'slug-2',
      titleValue: TitleValue()..parse('Past Event Title Long Enough'),
      imageUriValue: ThumbUriValue(defaultValue: Uri.parse('http://example.com/img.jpg')),
      startDateTimeValue: DateTimeValue(defaultValue: now.subtract(const Duration(days: 1))),
      locationValue: DescriptionValue()..parse('Valid Location Name Long Enough'),
      artists: [],
      tags: [],
    );

    userEventsRepository.setEvents([upcomingEvent, pastEvent]);
    await controller.init();
    
    expect(
      controller.myEventsFilteredStreamValue.value.map((e) => e.id),
      contains('1'),
    );
     expect(
      controller.myEventsFilteredStreamValue.value.map((e) => e.id),
      isNot(contains('2')),
    );
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
  return AppData.fromInitialization(remoteData: remoteData, localInfo: localInfo);
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  _FakeUserEventsRepository({List<VenueEventResume>? events})
      : _events = events ?? [];

  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: {});
  List<VenueEventResume> _events;
  int fetchMyEventsCallCount = 0;

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
  Future<void> confirmEventAttendance(String eventId) async {}

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {}

  @override
  bool isEventConfirmed(String eventId) =>
      confirmedEventIdsStream.value.contains(eventId);
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
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
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(String? address) async {
    lastKnownAddressStreamValue.addValue(address);
  }

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({Duration minInterval = const Duration(seconds: 30)}) async =>
      false;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<bool> startTracking({LocationTrackingMode mode = LocationTrackingMode.mapForeground}) async =>
      false;

  @override
  Future<void> stopTracking() async {}
}
