import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('init fails fast when backend is down (no bootstrap fallback)',
      () async {
    final backend = _ThrowingAppDataBackend(
      Exception('tenant backend unavailable'),
    );
    final repository = AppDataRepository(
      backend: backend,
      localInfoSource: _FakeAppDataLocalInfoSource(),
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

    expect(backend.fetchCount, 1);
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

class _FakeAppDataLocalInfoSource extends AppDataLocalInfoSource {
  @override
  Future<Map<String, dynamic>> getInfo() async {
    final platformTypeValue = PlatformTypeValue(defaultValue: AppType.web)
      ..parse(AppType.web.name);
    return {
      'platformType': platformTypeValue,
      'port': '',
      'hostname': 'tenant.example.test',
      'href': 'https://tenant.example.test',
      'device': 'test',
    };
  }
}
