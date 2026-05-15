import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(() {
    if (GetIt.I.isRegistered<AppData>()) {
      GetIt.I.unregister<AppData>();
    }
  });

  test(
      'init retries bootstrap fetches before failing without bootstrap fallback',
      () async {
    final backend = _ThrowingAppDataBackend(
      Exception('tenant backend unavailable'),
    );
    final repository = AppDataRepository(
      backend: backend,
      localInfoSource: _FakeAppDataLocalInfoSource(),
      bootstrapRetryDelays: const [
        Duration.zero,
        Duration.zero,
        Duration.zero,
      ],
    );

    await expectLater(
      repository.init(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('tenant backend unavailable'),
        ),
      ),
    );

    expect(backend.fetchCount, 4);
    expect(
      () => repository.appData,
      throwsA(
        isA<Error>().having(
          (error) => error.toString(),
          'message',
          contains('LateInitializationError'),
        ),
      ),
      reason:
          'Fail-fast bootstrap must not seed a fallback AppData when backend fetch fails.',
    );
  });

  test('init recovers when a transient bootstrap failure later succeeds',
      () async {
    final backend = _FlakyAppDataBackend(
      failuresBeforeSuccess: 2,
      errorFactory: () => Exception('tenant backend temporarily unavailable'),
    );
    final repository = AppDataRepository(
      backend: backend,
      localInfoSource: _FakeAppDataLocalInfoSource(),
      bootstrapRetryDelays: const [
        Duration.zero,
        Duration.zero,
        Duration.zero,
      ],
    );

    await repository.init();

    expect(backend.fetchCount, 3);
    expect(repository.appData.nameValue.value, 'Tenant Test');
    expect(repository.appData.hostname, 'tenant.example.test');
    expect(GetIt.I.get<AppData>().nameValue.value, 'Tenant Test');
  });

  test('init retries transient invalid bootstrap payloads before succeeding',
      () async {
    final backend = _InvalidThenValidAppDataBackend(
      invalidResponsesBeforeSuccess: 2,
    );
    final repository = AppDataRepository(
      backend: backend,
      localInfoSource: _FakeAppDataLocalInfoSource(),
      bootstrapRetryDelays: const [
        Duration.zero,
        Duration.zero,
        Duration.zero,
      ],
    );

    await repository.init();

    expect(backend.fetchCount, 3);
    expect(repository.appData.mainDomainValue.value.host, 'tenant.test');
  });

  test('init tolerates startup storage warmup failures after bootstrap',
      () async {
    final repository = AppDataRepository(
      backend: _FlakyAppDataBackend(
        failuresBeforeSuccess: 0,
        errorFactory: () => Exception('unused'),
      ),
      localInfoSource: _FakeAppDataLocalInfoSource(),
      bootstrapRetryDelays: const [Duration.zero],
      storage: _ThrowingSecureStorage(),
    );

    await repository.init();

    expect(repository.appData.nameValue.value, 'Tenant Test');
    expect(GetIt.I.get<AppData>().nameValue.value, 'Tenant Test');
  });
}

class _ThrowingAppDataBackend implements AppDataBackendContract {
  _ThrowingAppDataBackend(this.error);

  final Exception error;
  int fetchCount = 0;

  @override
  Future<AppDataDTO> fetch() async {
    fetchCount += 1;
    throw error;
  }
}

class _FlakyAppDataBackend implements AppDataBackendContract {
  _FlakyAppDataBackend({
    required int failuresBeforeSuccess,
    required this.errorFactory,
  }) : _remainingFailures = failuresBeforeSuccess;

  final Exception Function() errorFactory;
  int _remainingFailures;
  int fetchCount = 0;

  @override
  Future<AppDataDTO> fetch() async {
    fetchCount += 1;
    if (_remainingFailures > 0) {
      _remainingFailures -= 1;
      throw errorFactory();
    }
    return _buildAppDataDto();
  }
}

class _FakeAppDataLocalInfoSource extends AppDataLocalInfoSource {
  @override
  Future<AppDataLocalInfoDTO> getInfo() async {
    final platformTypeValue = PlatformTypeValue(defaultValue: AppType.web)
      ..parse(AppType.web.name);
    return AppDataLocalInfoDTO(
      platformTypeValue: platformTypeValue,
      port: '',
      hostname: 'tenant.example.test',
      href: 'https://tenant.example.test',
      device: 'test',
    );
  }
}

class _InvalidThenValidAppDataBackend implements AppDataBackendContract {
  _InvalidThenValidAppDataBackend({
    required this.invalidResponsesBeforeSuccess,
  });

  final int invalidResponsesBeforeSuccess;
  int fetchCount = 0;

  @override
  Future<AppDataDTO> fetch() async {
    fetchCount += 1;
    if (fetchCount <= invalidResponsesBeforeSuccess) {
      return AppDataDTO.fromJson({
        'name': 'Tenant Test',
        'type': 'tenant',
        'main_domain': '',
        'profile_types': const [],
        'domains': const [],
        'app_domains': const [],
        'theme_data_settings': const {
          'brightness_default': 'dark',
          'primary_seed_color': '#112233',
          'secondary_seed_color': '#445566',
        },
      });
    }
    return _buildAppDataDto();
  }
}

class _ThrowingSecureStorage extends FlutterSecureStorage {
  const _ThrowingSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) {
    throw StateError('secure storage read failed');
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) {
    throw StateError('secure storage write failed');
  }
}

AppDataDTO _buildAppDataDto() {
  return AppDataDTO.fromJson({
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
          'is_poi_enabled': true,
        },
      },
    ],
    'domains': const ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': const {
      'brightness_default': 'dark',
      'primary_seed_color': '#112233',
      'secondary_seed_color': '#445566',
    },
    'main_color': '#112233',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
    'settings': {
      'map_ui': {
        'radius': {
          'min_km': 1,
          'default_km': 5,
          'max_km': 50,
        },
      },
    },
  });
}
