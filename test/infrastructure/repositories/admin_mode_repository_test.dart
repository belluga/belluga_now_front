import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/admin_mode_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('defaults to user mode when storage is empty', () async {
    final repository = AdminModeRepository();
    await repository.init();

    expect(repository.mode, AdminMode.user);
    expect(repository.isLandlordMode, isFalse);
  });

  test('persists landlord mode and restores on init', () async {
    final repository = AdminModeRepository();
    await repository.init();
    await repository.setLandlordMode();

    final stored = await AdminModeRepository.storage.read(
      key: 'active_mode',
    );
    expect(stored, 'landlord');

    final rehydrated = AdminModeRepository();
    await rehydrated.init();
    expect(rehydrated.mode, AdminMode.landlord);
    expect(rehydrated.isLandlordMode, isTrue);
  });
}
