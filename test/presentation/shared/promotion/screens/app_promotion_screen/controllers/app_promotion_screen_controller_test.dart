import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_publication_settings.dart';
import 'package:belluga_now/domain/app_data/value_object/app_publication_store_url_value.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test(
    'launchPromotionUri invokes the iOS handoff before pending async work completes',
    () async {
      final steps = <String>[];
      final seedCompleter = Completer<bool>();
      final telemetryCompleter = Completer<void>();
      final launchedUris = <Uri>[];
      String? seededPayload;
      addTearDown(() {
        if (!seedCompleter.isCompleted) {
          seedCompleter.complete(true);
        }
        if (!telemetryCompleter.isCompleted) {
          telemetryCompleter.complete();
        }
      });
      final controller = AppPromotionScreenController(
        appDataRepository: _FakeAppDataRepository(
          publicationSettings: _publicationSettings(
            androidEnabled: true,
            iosEnabled: true,
          ),
        ),
        preferredStorePlatformResolver: () => AppPromotionStorePlatform.ios,
        telemetryTracker: (platformTarget) async {
          steps.add('telemetry');
          await telemetryCompleter.future;
        },
        iosDeferredPayloadSeeder: (payload) async {
          steps.add('seed');
          seededPayload = payload;
          return seedCompleter.future;
        },
        uriLauncher: (uri) async {
          steps.add('launch');
          launchedUris.add(uri);
          return true;
        },
      );

      final launchFuture = controller.launchPromotionUri(
        uri: Uri.parse(
          'https://tenant.example/open-app'
          '?path=%2Finvite&code=ABCD1234&store_channel=web&platform_target=ios',
        ),
        platform: AppPromotionStorePlatform.ios,
      );
      await Future<void>.delayed(Duration.zero);

      expect(steps, <String>['seed', 'launch', 'telemetry']);
      expect(seededPayload, isNotNull);
      final query = Uri.splitQueryString(seededPayload!);
      expect(query['store_channel'], 'web');
      expect(query['code'], 'ABCD1234');
      expect(query['target_path'], '/invite?code=ABCD1234');

      seedCompleter.complete(true);
      telemetryCompleter.complete();
      await launchFuture;

      expect(steps, <String>['seed', 'launch', 'telemetry']);
      expect(launchedUris, hasLength(1));
    },
  );

  test('launchPromotionUri does not seed clipboard for android', () async {
    var seeded = false;
    final launchedUris = <Uri>[];
    final controller = AppPromotionScreenController(
      appDataRepository: _FakeAppDataRepository(
        publicationSettings: _publicationSettings(
          androidEnabled: true,
          iosEnabled: true,
        ),
      ),
      preferredStorePlatformResolver: () => AppPromotionStorePlatform.android,
      iosDeferredPayloadSeeder: (payload) async {
        seeded = true;
        return true;
      },
      uriLauncher: (uri) async {
        launchedUris.add(uri);
        return true;
      },
    );

    await controller.launchPromotionUri(
      uri: Uri.parse(
        'https://tenant.example/open-app'
        '?path=%2Fprofile&store_channel=web&platform_target=android',
      ),
      platform: AppPromotionStorePlatform.android,
    );

    expect(launchedUris, hasLength(1));
    expect(seeded, isFalse);
  });

  test('launchPromotionUri still launches when telemetry throws', () async {
    final launchedUris = <Uri>[];
    final controller = AppPromotionScreenController(
      appDataRepository: _FakeAppDataRepository(
        publicationSettings: _publicationSettings(
          androidEnabled: true,
          iosEnabled: true,
        ),
      ),
      preferredStorePlatformResolver: () => AppPromotionStorePlatform.ios,
      telemetryTracker: (platformTarget) async {
        throw StateError('telemetry unavailable');
      },
      iosDeferredPayloadSeeder: (payload) async => true,
      uriLauncher: (uri) async {
        launchedUris.add(uri);
        return true;
      },
    );

    await controller.launchPromotionUri(
      uri: Uri.parse(
        'https://tenant.example/open-app'
        '?path=%2Finvite&code=ABCD1234&store_channel=web&platform_target=ios',
      ),
      platform: AppPromotionStorePlatform.ios,
    );

    expect(launchedUris, hasLength(1));
  });
}

AppPublicationSettings _publicationSettings({
  required bool androidEnabled,
  required bool iosEnabled,
}) {
  return AppPublicationSettings(
    hasExplicitConfigValue: _publicationBool(true),
    android: AppPublicationPlatformSettings(
      enabledValue: _publicationBool(androidEnabled),
      storeUrlValue: _publicationStoreUrl(
        androidEnabled
            ? 'https://play.google.com/store/apps/details?id=app'
            : null,
      ),
    ),
    ios: AppPublicationPlatformSettings(
      enabledValue: _publicationBool(iosEnabled),
      storeUrlValue: _publicationStoreUrl(
        iosEnabled ? 'https://apps.apple.com/br/app/id123' : null,
      ),
    ),
  );
}

DomainBooleanValue _publicationBool(bool raw) {
  final value = DomainBooleanValue();
  value.parse(raw.toString());
  return value;
}

AppPublicationStoreUrlValue _publicationStoreUrl(String? raw) {
  final value = AppPublicationStoreUrlValue();
  value.parse(raw);
  return value;
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository({required AppPublicationSettings publicationSettings})
    : _appData = _FakeAppData(publicationSettings: publicationSettings);

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
  _FakeAppData({required AppPublicationSettings publicationSettings})
    : _mainDomainValue = DomainValue(
        defaultValue: Uri.parse('https://tenant.example'),
      ),
      _nameValue = EnvironmentNameValue()..parse('Booora'),
      _mainIconLightUrl = IconUrlValue(
        defaultValue: Uri.parse('https://tenant.example/icon-light.png'),
      ),
      _mainIconDarkUrl = IconUrlValue(
        defaultValue: Uri.parse('https://tenant.example/icon-dark.png'),
      ),
      _settings = publicationSettings;

  final DomainValue _mainDomainValue;
  final EnvironmentNameValue _nameValue;
  final IconUrlValue _mainIconLightUrl;
  final IconUrlValue _mainIconDarkUrl;
  final AppPublicationSettings _settings;

  @override
  DomainValue get mainDomainValue => _mainDomainValue;

  @override
  EnvironmentNameValue get nameValue => _nameValue;

  @override
  IconUrlValue get mainIconLightUrl => _mainIconLightUrl;

  @override
  IconUrlValue get mainIconDarkUrl => _mainIconDarkUrl;

  @override
  AppPublicationSettings get publicationSettings => _settings;
}
