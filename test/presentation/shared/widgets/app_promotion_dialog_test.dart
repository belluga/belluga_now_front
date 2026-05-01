import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
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

  test('buildTenantPromotionUri preserves event detail continuation intent',
      () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: '/agenda/evento/show-rock?occurrence=occ-1',
      shareCode: 'CODE123',
      platformTarget: 'android',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(
      result?.queryParameters['path'],
      '/agenda/evento/show-rock?occurrence=occ-1',
    );
    expect(result?.queryParameters.containsKey('code'), isFalse);
    expect(result?.queryParameters['platform_target'], 'android');
  });

  test('buildTenantPromotionUri preserves auth-owned app continuation path',
      () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: '/profile?tab=settings',
      platformTarget: 'ios',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(result?.queryParameters['path'], '/profile');
    expect(result?.queryParameters['platform_target'], 'ios');
  });

  test('buildTenantPromotionUri preserves invite sharing continuation path',
      () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: '/convites/compartilhar?event=evt-1',
      platformTarget: 'android',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(result?.queryParameters['path'], '/convites/compartilhar');
    expect(result?.queryParameters['platform_target'], 'android');
  });

  test('buildTenantPromotionUri unwraps web auth redirect for app continuation',
      () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: '/auth/login?redirect=%2Fprofile',
      platformTarget: 'android',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(result?.queryParameters['path'], '/profile');
    expect(result?.queryParameters['platform_target'], 'android');
  });

  test('buildTenantPromotionUri falls back for over-nested auth redirect', () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: _nestedAuthRedirect(depth: 8, terminal: '/profile'),
      platformTarget: 'android',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(result?.queryParameters['path'], '/');
    expect(result?.queryParameters['platform_target'], 'android');
  });

  test('buildTenantPromotionUri falls back for external redirect path', () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: 'https://evil.example/agenda/evento/show-rock',
      platformTarget: 'android',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(result?.queryParameters['path'], '/');
    expect(result?.queryParameters['platform_target'], 'android');
  });

  test('buildTenantPromotionUri falls back for external invite redirect path',
      () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: 'https://evil.example/invite?code=CODE123',
      platformTarget: 'android',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(result?.queryParameters['path'], '/');
    expect(result?.queryParameters.containsKey('code'), isFalse);
    expect(result?.queryParameters['platform_target'], 'android');
  });

  test('buildTenantPromotionUri keeps explicit platform target override', () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: '/profile',
      platformTarget: 'ios',
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(result?.queryParameters['path'], '/profile');
    expect(result?.queryParameters['platform_target'], 'ios');
  });

  test('buildTenantPromotionUri can request promotion fallback boundary', () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://tenant.example'),
      ),
    );

    final result = AppPromotionDialog.buildTenantPromotionUri(
      redirectPath: '/agenda/evento/show-rock?occurrence=occ-1',
      platformTarget: 'android',
      fallbackToPromotionBoundary: true,
    );

    expect(result, isNotNull);
    expect(result?.path, '/open-app');
    expect(
      result?.queryParameters['path'],
      '/agenda/evento/show-rock?occurrence=occ-1',
    );
    expect(result?.queryParameters['platform_target'], 'android');
    expect(result?.queryParameters['fallback'], 'promotion');
  });
}

String _nestedAuthRedirect({
  required int depth,
  required String terminal,
}) {
  var value = terminal;
  for (var index = 0; index < depth; index += 1) {
    value = Uri(
      path: '/auth/login',
      queryParameters: <String, String>{'redirect': value},
    ).toString();
  }
  return value;
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository({
    required Uri mainDomain,
  }) : _appData = _FakeAppData(mainDomain: mainDomain);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      StreamValue<DistanceInMetersValue>(
        defaultValue: DistanceInMetersValue.fromRaw(1000, defaultValue: 1000),
      );

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      DistanceInMetersValue.fromRaw(1000, defaultValue: 1000);

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
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {}

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}
}

class _FakeAppData extends Fake implements AppData {
  _FakeAppData({
    required Uri mainDomain,
  }) : _mainDomainValue = DomainValue(defaultValue: mainDomain);

  final DomainValue _mainDomainValue;

  @override
  DomainValue get mainDomainValue => _mainDomainValue;
}
