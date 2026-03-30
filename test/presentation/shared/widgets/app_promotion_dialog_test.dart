import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/app_promotion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  setUp(() {
    GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('buildTenantPromotionUri uses /open-app invite context with code', () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: '/invite?code=CODE123',
      shareCode: '  CODE123  ',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(result?.queryParameters['path'], '/invite');
    expect(result?.queryParameters['code'], 'CODE123');
    expect(result?.queryParameters['store_channel'], 'web');
  });

  test('buildTenantPromotionUri uses /open-app home fallback without code', () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: '/agenda',
      shareCode: '   ',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(result?.queryParameters['path'], '/');
    expect(result?.queryParameters.containsKey('code'), isFalse);
    expect(result?.queryParameters['store_channel'], 'web');
  });

  test(
      'buildTenantPromotionUri ignores explicit share code for non-invite path',
      () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: '/events/123',
      shareCode: 'CODE123',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(result?.queryParameters['path'], '/');
    expect(result?.queryParameters.containsKey('code'), isFalse);
  });
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository({
    required Uri mainDomain,
  }) : _appData = _FakeAppData(mainDomain: mainDomain);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      StreamValue<double>(defaultValue: 1000);

  @override
  double get maxRadiusMeters => 1000;

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  ThemeMode get themeMode => ThemeMode.dark;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.dark);

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(double meters) async {}

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
}

class _FakeAppData extends Fake implements AppData {
  _FakeAppData({
    required Uri mainDomain,
  }) : _mainDomainValue = DomainValue(defaultValue: mainDomain);

  final DomainValue _mainDomainValue;

  @override
  DomainValue get mainDomainValue => _mainDomainValue;
}
