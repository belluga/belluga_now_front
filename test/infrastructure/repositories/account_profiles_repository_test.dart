import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/repositories/account_profiles_repository.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(_NoopTelemetry());
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('fetchAllAccountProfiles returns items when registry enables type', () async {
    final validId = _generateMongoId();
    final backend = _StubAccountProfilesBackend(
      accountProfiles: [
        AccountProfileModel.fromPrimitives(
          id: validId,
          name: 'Artist One',
          slug: 'artist-one',
          type: 'artist',
        ),
      ],
    );
    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteAccountProfileIds: const {},
    );

    final profiles = await repository.fetchAllAccountProfiles();

    expect(profiles, hasLength(1));
    expect(profiles.first.type, 'artist');
  });
}

class _StubAccountProfilesBackend implements AccountProfilesBackendContract {
  _StubAccountProfilesBackend({required this.accountProfiles});

  final List<AccountProfileModel> accountProfiles;

  @override
  Future<List<AccountProfileModel>> fetchAccountProfiles() async =>
      accountProfiles;

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) async =>
      accountProfiles.firstWhere((profile) => profile.slug == slug);

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async =>
      accountProfiles;
}

class _NoopTelemetry implements TelemetryRepositoryContract {
  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async =>
      true;

  @override
  Future<bool> flushTimedEvents() async => true;

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      true;

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      null;

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
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
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
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

String _generateMongoId() {
  // 24-char hex string to satisfy MongoIDValue validation in AccountProfileModel.
  return DateTime.now().microsecondsSinceEpoch
      .toRadixString(16)
      .padLeft(24, '0')
      .substring(0, 24);
}
