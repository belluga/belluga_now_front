import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/presentation/shared/promotion/support/web_installed_app_handoff.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('web installed-app handoff uses the canonical web origin', () {
    final result = buildWebInstalledAppHandoffUri(
      redirectPath: '/agenda/evento/show-rock?occurrence=occ-1',
      platformTarget: 'android',
      canonicalWebOriginUri: Uri.parse(
        'https://guarappari.belluga.space/descobrir',
      ),
    );

    expect(result, isNotNull);
    expect(result!.origin, 'https://guarappari.belluga.space');
    expect(result.path, '/open-app');
    expect(
      result.queryParameters['path'],
      '/agenda/evento/show-rock?occurrence=occ-1',
    );
    expect(result.queryParameters['platform_target'], 'android');
    expect(result.queryParameters['fallback'], 'promotion');
  });

  test('web installed-app handoff derives canonical origin from AppData',
      () {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(
        mainDomain: Uri.parse('https://belluga.space'),
        href: 'https://guarappari.belluga.space/descobrir',
      ),
    );

    final result = buildWebInstalledAppHandoffUri(
      redirectPath: '/parceiro/profile-slug',
      platformTarget: 'android',
    );

    expect(result, isNotNull);
    expect(result!.origin, 'https://belluga.space');
    expect(result.path, '/open-app');
    expect(result.queryParameters['path'], '/parceiro/profile-slug');
    expect(result.queryParameters['platform_target'], 'android');
  });
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository({
    required Uri mainDomain,
    required String href,
  }) : _appData = _FakeAppData(mainDomain: mainDomain, href: href);

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
    required String href,
  })  : _mainDomainValue = DomainValue(defaultValue: mainDomain),
        _href = href;

  final DomainValue _mainDomainValue;
  final String _href;

  @override
  DomainValue get mainDomainValue => _mainDomainValue;

  @override
  String get href => _href;
}
