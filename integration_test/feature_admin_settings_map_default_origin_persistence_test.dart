import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/landlord_auth_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_tenants_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_selected_tenant_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_settings_repository.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  const adminEmailDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_EMAIL',
    defaultValue: 'admin@bellugasolutions.com.br',
  );
  const adminPasswordDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_PASSWORD',
    defaultValue: '765432e1',
  );
  const tenantDomainDefine = String.fromEnvironment(
    'TENANT_ADMIN_TEST_DOMAIN',
    defaultValue: 'guarappari.belluga.space',
  );

  String requireDefine(String key, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      fail('Missing --dart-define=$key for integration test execution.');
    }
    return normalized;
  }

  Uri requireOriginUri(String raw) {
    final trimmed = raw.trim();
    final uri =
        Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri == null || uri.host.trim().isEmpty) {
      fail('Invalid origin/domain value: "$raw"');
    }
    return Uri(
      scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
      host: uri.host.trim().toLowerCase(),
      port: uri.hasPort ? uri.port : null,
    );
  }

  String normalizeHost(String raw) => requireOriginUri(raw).host;

  String deriveLandlordOriginFromTenantHost(String tenantHost) {
    final labels = tenantHost.trim().toLowerCase().split('.');
    if (labels.length < 2) {
      fail('Invalid tenant host for landlord derivation: "$tenantHost"');
    }
    final landlordHost =
        labels.length >= 3 ? labels.sublist(1).join('.') : labels.join('.');
    return 'https://$landlordHost';
  }

  LandlordTenantOption resolveTenantByDomain(
    List<LandlordTenantOption> tenants,
    String expectedHost,
  ) {
    for (final tenant in tenants) {
      if (normalizeHost(tenant.mainDomain) == expectedHost) {
        return tenant;
      }
    }
    fail(
      'Tenant "$expectedHost" not found in landlord listing. '
      'Available: ${tenants.map((tenant) => tenant.mainDomain).join(', ')}',
    );
  }

  String mutateLabel(String? current) {
    final base = (current == null || current.trim().isEmpty)
        ? 'Praia do Morro'
        : current.trim();
    return '$base [IT]';
  }

  ({double lat, double lng, String label}) mutateOrigin(
    TenantAdminMapDefaultOrigin? current,
  ) {
    final baseLat = current?.lat ?? -20.611121;
    final baseLng = current?.lng ?? -40.498617;
    return (
      lat: double.parse((baseLat + 0.000321).toStringAsFixed(6)),
      lng: double.parse((baseLng + 0.000654).toStringAsFixed(6)),
      label: mutateLabel(current?.label),
    );
  }

  Future<TenantAdminMapUiSettings> waitForMapUiOrigin({
    required TenantAdminSettingsRepository repository,
    required bool Function(TenantAdminMapUiSettings value) predicate,
    required String expectationLabel,
    Duration timeout = const Duration(seconds: 40),
    Duration step = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    TenantAdminMapUiSettings? lastRead;

    while (DateTime.now().isBefore(deadline)) {
      final current = await repository.fetchMapUiSettings();
      lastRead = current;
      if (predicate(current)) {
        return current;
      }
      await Future<void>.delayed(step);
    }

    throw TestFailure(
      'Timed out waiting for $expectationLabel. '
      'Last read: ${lastRead?.defaultOrigin?.toJson()}',
    );
  }

  Future<Map<String, dynamic>> fetchEnvironment({
    required Uri tenantOrigin,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: tenantOrigin.toString(),
      ),
    );
    final response = await dio.get(
      '/api/v1/environment',
      queryParameters: {
        '_ts': DateTime.now().microsecondsSinceEpoch.toString(),
      },
      options: Options(headers: const {'Accept': 'application/json'}),
    );
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return raw;
    }
    throw TestFailure('Unexpected environment response shape.');
  }

  TenantAdminMapDefaultOrigin? parseEnvironmentDefaultOrigin(
    Map<String, dynamic> payload,
  ) {
    final settings = payload['settings'];
    if (settings is! Map) {
      return null;
    }
    final mapUi = settings['map_ui'];
    if (mapUi is! Map) {
      return null;
    }
    final defaultOrigin = mapUi['default_origin'];
    if (defaultOrigin is! Map) {
      return null;
    }

    double? parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value.trim());
      return null;
    }

    final lat = parseDouble(defaultOrigin['lat']);
    final lng = parseDouble(defaultOrigin['lng']);
    if (lat == null || lng == null) {
      return null;
    }
    final label = defaultOrigin['label']?.toString().trim();
    return TenantAdminMapDefaultOrigin(
      lat: LatitudeValue()..parse(lat.toString()),
      lng: LongitudeValue()..parse(lng.toString()),
      label: label == null || label.isEmpty
          ? null
          : (TenantAdminOptionalTextValue()..parse(label)),
    );
  }

  Future<TenantAdminMapDefaultOrigin?> waitForEnvironmentDefaultOrigin({
    required Uri tenantOrigin,
    required bool Function(TenantAdminMapDefaultOrigin? value) predicate,
    required String expectationLabel,
    Duration timeout = const Duration(seconds: 40),
    Duration step = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    TenantAdminMapDefaultOrigin? lastRead;

    while (DateTime.now().isBefore(deadline)) {
      final payload = await fetchEnvironment(tenantOrigin: tenantOrigin);
      final current = parseEnvironmentDefaultOrigin(payload);
      lastRead = current;
      if (predicate(current)) {
        return current;
      }
      await Future<void>.delayed(step);
    }

    throw TestFailure(
      'Timed out waiting for $expectationLabel. '
      'Last read: ${lastRead?.toJson()}',
    );
  }

  bool sameOrigin(
    TenantAdminMapDefaultOrigin? value, {
    required double lat,
    required double lng,
    required String label,
  }) {
    if (value == null) {
      return false;
    }
    return (value.lat - lat).abs() < 0.000001 &&
        (value.lng - lng).abs() < 0.000001 &&
        (value.label ?? '') == label;
  }

  testWidgets(
    'tenant admin map default origin persists and is reflected by environment',
    (tester) async {
      await GetIt.I.reset(dispose: true);

      final adminEmail =
          requireDefine('LANDLORD_ADMIN_EMAIL', adminEmailDefine);
      final adminPassword =
          requireDefine('LANDLORD_ADMIN_PASSWORD', adminPasswordDefine);
      final expectedTenantHost = normalizeHost(tenantDomainDefine);
      final tenantOrigin = requireOriginUri(tenantDomainDefine);
      final landlordOrigin =
          deriveLandlordOriginFromTenantHost(expectedTenantHost);

      final authRepository = LandlordAuthRepository(
        dio: Dio(
          BaseOptions(
            baseUrl: '$landlordOrigin/admin/api',
          ),
        ),
      );
      GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(authRepository);

      final appDataRepository = _FakeAppDataRepository(
        _buildAppData(mainDomain: tenantOrigin.toString()),
      );
      final locationSelectionService = TenantAdminLocationSelectionService();

      TenantAdminMapDefaultOrigin? originalOrigin;
      var mutationApplied = false;

      try {
        await authRepository.init();
        await authRepository.loginWithEmailPassword(
          landlordAuthRepoString(adminEmail),
          landlordAuthRepoString(adminPassword),
        );
        expect(authRepository.hasValidSession, isTrue);

        final tenantsRepository = LandlordTenantsRepository(
          landlordAuthRepository: authRepository,
          landlordOriginOverride: landlordOrigin,
        );
        final tenants = await tenantsRepository.fetchTenants();
        expect(tenants, isNotEmpty);

        final tenantOption = resolveTenantByDomain(tenants, expectedTenantHost);
        final tenantScopeRepository = TenantAdminSelectedTenantRepository();
        tenantScopeRepository.setAvailableTenants(tenants);
        tenantScopeRepository.selectTenant(tenantOption);

        final settingsRepository = TenantAdminSettingsRepository(
          tenantScope: tenantScopeRepository,
        );
        final controller = TenantAdminSettingsController(
          appDataRepository: appDataRepository,
          settingsRepository: settingsRepository,
          tenantScope: tenantScopeRepository,
          locationSelectionService: locationSelectionService,
        );

        await controller.loadMapUiSettings();
        final initialSettings = controller.mapUiSettingsStreamValue.value;
        originalOrigin = initialSettings.defaultOrigin;

        final mutated = mutateOrigin(originalOrigin);
        controller.mapDefaultOriginLatitudeController.text =
            mutated.lat.toStringAsFixed(6);
        controller.mapDefaultOriginLongitudeController.text =
            mutated.lng.toStringAsFixed(6);
        controller.mapDefaultOriginLabelController.text = mutated.label;

        await controller.saveMapUiSettings();
        mutationApplied = true;

        expect(controller.remoteErrorStreamValue.value, isNull);
        expect(
          controller.remoteSuccessStreamValue.value,
          'Origem padrão atualizada com sucesso.',
        );

        final persistedSettings = await waitForMapUiOrigin(
          repository: settingsRepository,
          expectationLabel: 'map_ui persistence',
          predicate: (value) => sameOrigin(
            value.defaultOrigin,
            lat: mutated.lat,
            lng: mutated.lng,
            label: mutated.label,
          ),
        );
        expect(
          sameOrigin(
            persistedSettings.defaultOrigin,
            lat: mutated.lat,
            lng: mutated.lng,
            label: mutated.label,
          ),
          isTrue,
        );

        await controller.loadMapUiSettings();
        expect(
          controller.mapDefaultOriginLatitudeController.text,
          mutated.lat.toStringAsFixed(6),
        );
        expect(
          controller.mapDefaultOriginLongitudeController.text,
          mutated.lng.toStringAsFixed(6),
        );
        expect(
          controller.mapDefaultOriginLabelController.text,
          mutated.label,
        );

        final environmentOrigin = await waitForEnvironmentDefaultOrigin(
          tenantOrigin: tenantOrigin,
          expectationLabel: 'environment default origin propagation',
          predicate: (value) => sameOrigin(
            value,
            lat: mutated.lat,
            lng: mutated.lng,
            label: mutated.label,
          ),
        );

        expect(
          sameOrigin(
            environmentOrigin,
            lat: mutated.lat,
            lng: mutated.lng,
            label: mutated.label,
          ),
          isTrue,
        );

        controller.onDispose();
      } finally {
        if (mutationApplied) {
          final tenantsRepository = LandlordTenantsRepository(
            landlordAuthRepository: authRepository,
            landlordOriginOverride: landlordOrigin,
          );
          final tenants = await tenantsRepository.fetchTenants();
          final tenantOption =
              resolveTenantByDomain(tenants, expectedTenantHost);
          final tenantScopeRepository = TenantAdminSelectedTenantRepository();
          tenantScopeRepository.setAvailableTenants(tenants);
          tenantScopeRepository.selectTenant(tenantOption);
          final restoreRepository = TenantAdminSettingsRepository(
            tenantScope: tenantScopeRepository,
          );

          final current = await restoreRepository.fetchMapUiSettings();
          await restoreRepository.updateMapUiSettings(
            settings: current.applyDefaultOrigin(originalOrigin),
          );

          await waitForMapUiOrigin(
            repository: restoreRepository,
            expectationLabel: 'map_ui restoration',
            predicate: (value) {
              final restored = value.defaultOrigin;
              if (originalOrigin == null) {
                return restored == null;
              }
              return sameOrigin(
                restored,
                lat: originalOrigin.lat,
                lng: originalOrigin.lng,
                label: originalOrigin.label ?? '',
              );
            },
          );

          await waitForEnvironmentDefaultOrigin(
            tenantOrigin: tenantOrigin,
            expectationLabel: 'environment default origin restoration',
            predicate: (value) {
              if (originalOrigin == null) {
                return value == null;
              }
              return sameOrigin(
                value,
                lat: originalOrigin.lat,
                lng: originalOrigin.lng,
                label: originalOrigin.label ?? '',
              );
            },
          );
        }

        await authRepository.logout();
        await GetIt.I.reset(dispose: true);
      }
    },
  );
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData);

  final AppData _appData;
  final StreamValue<double> _maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: 50000);
  final StreamValue<ThemeMode?> _themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;

  @override
  double get maxRadiusMeters => _maxRadiusMetersStreamValue.value;

  @override
  Future<void> setMaxRadiusMeters(Object meters) async {
    _maxRadiusMetersStreamValue.addValue(meters is num ? meters.toDouble() : (meters as dynamic).value as double);
  }

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _themeModeStreamValue;

  @override
  ThemeMode get themeMode => _themeModeStreamValue.value ?? ThemeMode.system;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeModeStreamValue.addValue(mode);
  }
}

AppData _buildAppData({
  required String mainDomain,
}) {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'profile_types': const [],
    'domains': [mainDomain],
    'app_domains': const ['com.guarappari.app'],
    'theme_data_settings': const {
      'brightness_default': 'light',
      'primary_seed_color': '#009688',
      'secondary_seed_color': '#673AB7',
    },
    'main_color': '#009688',
    'main_domain': mainDomain,
    'tenant_id': 'tenant-1',
    'telemetry': const {
      'trackers': [],
    },
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': const {
      'apiKey': 'apikey',
      'appId': 'appid',
      'projectId': 'project-test',
      'messagingSenderId': 'sender',
      'storageBucket': 'bucket',
    },
    'push': const {
      'enabled': true,
      'types': ['event'],
      'throttles': {'max_per_hour': 20},
    },
  };

  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': requireOriginForBuild(mainDomain).host,
    'href': requireOriginForBuild(mainDomain).toString(),
    'port': requireOriginForBuild(mainDomain).hasPort
        ? requireOriginForBuild(mainDomain).port.toString()
        : null,
    'device': 'integration-test-device',
  };

  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

Uri requireOriginForBuild(String raw) {
  final trimmed = raw.trim();
  final uri =
      Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
  if (uri == null || uri.host.trim().isEmpty) {
    throw ArgumentError('Invalid mainDomain for AppData builder: "$raw"');
  }
  return Uri(
    scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
    host: uri.host.trim().toLowerCase(),
    port: uri.hasPort ? uri.port : null,
  );
}
