import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/testing/tenant_admin_app_links_settings_builder.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/observability/sentry_error_reporter.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_discovery_filter_rule_catalog_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_by_taxonomy_id.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_discovery_filters_settings_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_map_filter_rule_values.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_positive_int_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_discovery_filter_rule_catalog_repository.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/controllers/tenant_admin_discovery_filters_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_item.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_items.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_query.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filters_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/screens/tenant_admin_discovery_filter_surface_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/tenant_admin_discovery_filters_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/models/tenant_admin_settings_integration_section.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_environment_snapshot_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_domains_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_local_preferences_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_technical_integrations_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_visual_identity_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_map_filter_rule_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_map_filter_visual_sheet.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_icon_catalog.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_map_marker_icon_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';

TenantAdminRequiredTextValue _requiredText(String raw) {
  final value = TenantAdminRequiredTextValue();
  value.parse(raw);
  return value;
}

TenantAdminHexColorValue _hexColor(String raw) {
  final value = TenantAdminHexColorValue();
  value.parse(raw);
  return value;
}

TenantAdminOptionalUrlValue _optionalUrl(String raw) {
  final value = TenantAdminOptionalUrlValue();
  value.parse(raw);
  return value;
}

TenantAdminPositiveIntValue _positiveInt(int raw) {
  final value = TenantAdminPositiveIntValue();
  value.parse(raw.toString());
  return value;
}

TenantAdminLowercaseTokenValue _token(String raw) {
  final value = TenantAdminLowercaseTokenValue();
  value.parse(raw);
  return value;
}

LatitudeValue _lat(double raw) {
  final value = LatitudeValue();
  value.parse(raw.toString());
  return value;
}

LongitudeValue _lng(double raw) {
  final value = LongitudeValue();
  value.parse(raw.toString());
  return value;
}

TenantAdminOptionalTextValue _optionalText(String raw) {
  final value = TenantAdminOptionalTextValue();
  value.parse(raw);
  return value;
}

TenantAdminBooleanValue _booleanValue(bool raw) {
  final value = TenantAdminBooleanValue();
  value.parse(raw.toString());
  return value;
}

TenantAdminDomainStatusValue _domainStatus(String raw) {
  final value = TenantAdminDomainStatusValue();
  value.parse(raw);
  return value;
}

TenantAdminTaxonomyDefinition _taxonomyDefinition({
  required String id,
  required String slug,
  required String name,
  required List<String> appliesTo,
}) {
  return TenantAdminTaxonomyDefinition(
    idValue: _requiredText(id),
    slugValue: _requiredText(slug),
    nameValue: _requiredText(name),
    appliesToValue: TenantAdminTrimmedStringListValue(appliesTo),
    iconValue: TenantAdminOptionalTextValue(),
    colorValue: TenantAdminOptionalTextValue(),
  );
}

TenantAdminTaxonomyTermDefinition _taxonomyTermDefinition({
  required String id,
  required String taxonomyId,
  required String slug,
  required String name,
}) {
  return TenantAdminTaxonomyTermDefinition(
    idValue: _requiredText(id),
    taxonomyIdValue: _requiredText(taxonomyId),
    slugValue: _requiredText(slug),
    nameValue: _requiredText(name),
  );
}

TenantAdminDomainEntry _domainEntry({
  required String id,
  required String path,
  String status = TenantAdminDomainStatusValue.active,
}) {
  return TenantAdminDomainEntry(
    idValue: _requiredText(id),
    pathValue: _requiredText(path),
    typeValue: _requiredText('web'),
    statusValue: _domainStatus(status),
  );
}

TenantAdminResendEmailRecipients _resendRecipients(Iterable<String> values) {
  return TenantAdminResendEmailRecipients(
    values.map(_emailAddressValue),
  );
}

List<String> _recipientStrings(TenantAdminResendEmailRecipients values) {
  return values.values.map((entry) => entry.value).toList(growable: false);
}

EmailAddressValue _emailAddressValue(String raw) {
  final value = EmailAddressValue();
  value.parse(raw);
  return value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<TenantAdminLocationSelectionContract>(
      TenantAdminLocationSelectionService(),
    );
  });

  tearDown(() async {
    SentryErrorReporter.resetForTesting();
    await GetIt.I.reset();
  });

  testWidgets('renders hub hierarchy with stable keys', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsScreen()),
    );

    expect(find.byKey(TenantAdminSettingsKeys.hubList), findsOneWidget);
    expect(
      find.byKey(TenantAdminSettingsKeys.hubCardPreferences),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubCardVisualIdentity),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubCardDomains),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubActionPreferences),
      findsNothing,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubActionVisualIdentity),
      findsNothing,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubActionDomains),
      findsNothing,
    );
    expect(
      find.text('Toque para editar preferências locais e origem do mapa'),
      findsOneWidget,
    );
    expect(find.text('Toque para editar identidade visual'), findsOneWidget);
    expect(
      find.text('Toque para gerenciar domínios web ativos'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(TenantAdminSettingsKeys.hubCardTechnicalIntegrations),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(TenantAdminSettingsKeys.hubCardTechnicalIntegrations),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubActionTechnicalIntegrations),
      findsNothing,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubIntegrationFirebase),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubIntegrationResend),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubIntegrationOutbound),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubIntegrationAppLinks),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubIntegrationPush),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubIntegrationTelemetry),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(TenantAdminSettingsKeys.hubCardEnvironmentSnapshot),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(TenantAdminSettingsKeys.hubCardEnvironmentSnapshot),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubActionEnvironmentSnapshot),
      findsNothing,
    );
    expect(find.text('Configurar'), findsNothing);
  });

  testWidgets('renders environment snapshot details', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsEnvironmentSnapshotScreen()),
    );

    expect(
      find.byKey(TenantAdminSettingsKeys.environmentSnapshotScreen),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.environmentSnapshotScopedAppBar),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.environmentSnapshotBackButton),
      findsOneWidget,
    );
    expect(find.text('Runtime do tenant'), findsOneWidget);
    expect(find.text('Tenant Test'), findsOneWidget);
    expect(find.text('guarappari.test'), findsWidgets);
    expect(find.text('project-test'), findsOneWidget);
  });

  testWidgets('renders domains screen with active-domain actions',
      (tester) async {
    final repository = _FakeAppDataRepository(
      _buildAppData(mainDomain: 'https://current.example.com'),
    );
    final settingsRepository = _FakeTenantAdminSettingsRepository(
      initialDomains: [
        _domainEntry(id: 'domain-current', path: 'current.example.com'),
        _domainEntry(id: 'domain-extra', path: 'extra.example.com'),
      ],
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminTenantScopeContract>(
      _FakeTenantScope('current.example.com'),
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsDomainsScreen()),
    );

    expect(find.byKey(TenantAdminSettingsKeys.domainsScreen), findsOneWidget);
    expect(
      find.byKey(TenantAdminSettingsKeys.domainsScopedAppBar),
      findsOneWidget,
    );
    expect(find.text('current.example.com'), findsOneWidget);
    expect(find.text('extra.example.com'), findsOneWidget);
    expect(find.text('Ativo'), findsNWidgets(2));

    final currentDeleteButton = tester.widget<OutlinedButton>(
      find.byKey(TenantAdminSettingsKeys.domainsDeleteButton(0)),
    );
    final extraDeleteButton = tester.widget<OutlinedButton>(
      find.byKey(TenantAdminSettingsKeys.domainsDeleteButton(1)),
    );

    expect(currentDeleteButton.onPressed, isNull);
    expect(extraDeleteButton.onPressed, isNotNull);
  });

  testWidgets(
      'domains screen adds and deletes active domains through widget actions',
      (tester) async {
    final repository = _FakeAppDataRepository(
      _buildAppData(mainDomain: 'https://current.example.com'),
    );
    final settingsRepository = _FakeTenantAdminSettingsRepository(
      initialDomains: [
        _domainEntry(id: 'domain-current', path: 'current.example.com'),
        _domainEntry(id: 'domain-extra', path: 'extra.example.com'),
      ],
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminTenantScopeContract>(
      _FakeTenantScope('current.example.com'),
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsDomainsScreen()),
    );

    await tester.enterText(
      find.byKey(TenantAdminSettingsKeys.domainsPathField),
      'NEW-DOMAIN.EXAMPLE.COM',
    );
    await tester.tap(find.byKey(TenantAdminSettingsKeys.domainsAddButton));
    await tester.pumpAndSettle();

    expect(settingsRepository.createdDomainPaths, ['new-domain.example.com']);
    expect(find.text('new-domain.example.com'), findsOneWidget);

    await tester
        .tap(find.byKey(TenantAdminSettingsKeys.domainsDeleteButton(0)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();

    expect(settingsRepository.deletedDomainIds, ['domain-created-1']);
    expect(find.text('new-domain.example.com'), findsNothing);
  });

  testWidgets(
      'domains screen surfaces duplicate-domain errors through widget flow',
      (tester) async {
    final repository = _FakeAppDataRepository(
      _buildAppData(mainDomain: 'https://current.example.com'),
    );
    final settingsRepository = _FakeTenantAdminSettingsRepository(
      createDomainError: StateError('Another tenant already uses this domain.'),
      initialDomains: [
        _domainEntry(id: 'domain-current', path: 'current.example.com'),
      ],
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminTenantScopeContract>(
      _FakeTenantScope('current.example.com'),
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsDomainsScreen()),
    );

    await tester.enterText(
      find.byKey(TenantAdminSettingsKeys.domainsPathField),
      'shared.example.com',
    );
    await tester.tap(find.byKey(TenantAdminSettingsKeys.domainsAddButton));
    await tester.pumpAndSettle();

    expect(settingsRepository.createdDomainPaths, ['shared.example.com']);
    expect(
      find.textContaining('Another tenant already uses this domain.'),
      findsOneWidget,
    );
    expect(find.text('current.example.com'), findsOneWidget);
    expect(find.byKey(TenantAdminSettingsKeys.domainsRow(0)), findsOneWidget);
    expect(find.byKey(TenantAdminSettingsKeys.domainsRow(1)), findsNothing);
  });

  test('controller paginates and mutates active domains list', () async {
    final repository = _FakeAppDataRepository(
      _buildAppData(mainDomain: 'https://current.example.com'),
    );
    final settingsRepository = _FakeTenantAdminSettingsRepository(
      initialDomains: List<TenantAdminDomainEntry>.generate(
        16,
        (index) => _domainEntry(
          id: 'domain-$index',
          path:
              index == 0 ? 'current.example.com' : 'domain-$index.example.com',
        ),
      ),
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminTenantScopeContract>(
      _FakeTenantScope('current.example.com'),
    );
    final controller = TenantAdminSettingsController();

    await controller.loadDomains();
    expect(controller.domainsStreamValue.value, hasLength(15));
    expect(controller.hasMoreDomainsStreamValue.value, isTrue);

    await controller.loadNextDomainsPage();
    expect(controller.domainsStreamValue.value, hasLength(16));
    expect(controller.hasMoreDomainsStreamValue.value, isFalse);

    controller.domainPathController.text = 'NEW-DOMAIN.EXAMPLE.COM';
    await controller.createDomain();
    expect(settingsRepository.createdDomainPaths, ['new-domain.example.com']);
    expect(
      controller.domainsStreamValue.value.first.path,
      'new-domain.example.com',
    );

    final deletable = controller.domainsStreamValue.value.firstWhere(
      (domain) => domain.path == 'domain-1.example.com',
    );
    await controller.deleteDomain(deletable);
    expect(settingsRepository.deletedDomainIds, contains(deletable.id));
    expect(
      controller.domainsStreamValue.value.any(
        (domain) => domain.id == deletable.id,
      ),
      isFalse,
    );
  });

  test('controller preserves duplicate-domain validation errors', () async {
    final repository = _FakeAppDataRepository(
      _buildAppData(mainDomain: 'https://current.example.com'),
    );
    final settingsRepository = _FakeTenantAdminSettingsRepository(
      createDomainError: StateError(
        'Another tenant already uses this domain.',
      ),
      initialDomains: [
        _domainEntry(id: 'domain-current', path: 'current.example.com'),
      ],
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminTenantScopeContract>(
      _FakeTenantScope('current.example.com'),
    );
    final controller = TenantAdminSettingsController();

    await controller.loadDomains();
    controller.domainPathController.text = 'shared.example.com';
    await controller.createDomain();

    expect(
      controller.remoteErrorStreamValue.value,
      contains('Another tenant already uses this domain.'),
    );
    expect(settingsRepository.createdDomainPaths, ['shared.example.com']);
    expect(controller.domainsStreamValue.value, hasLength(1));
    expect(
      controller.domainsStreamValue.value.single.path,
      'current.example.com',
    );
  });

  testWidgets('updates theme mode via segmented control', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsLocalPreferencesScreen()),
    );

    expect(
      find.byKey(TenantAdminSettingsKeys.localPreferencesScreen),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.localPreferencesScopedAppBar),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.localPreferencesBackButton),
      findsOneWidget,
    );

    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    expect(repository.themeMode, ThemeMode.dark);
  });

  testWidgets('saves default origin via local preferences map_ui flow',
      (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsLocalPreferencesScreen()),
    );

    await tester.enterText(
      find.byKey(TenantAdminSettingsKeys.localPreferencesDefaultOriginLatField),
      '-20.673600',
    );
    await tester.enterText(
      find.byKey(TenantAdminSettingsKeys.localPreferencesDefaultOriginLngField),
      '-40.497600',
    );
    await tester.enterText(
      find.byKey(
        TenantAdminSettingsKeys.localPreferencesDefaultOriginLabelField,
      ),
      'Centro',
    );
    await tester.scrollUntilVisible(
      find.byKey(TenantAdminSettingsKeys.localPreferencesSaveOriginButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(TenantAdminSettingsKeys.localPreferencesSaveOriginButton),
    );
    await tester.pumpAndSettle();

    expect(settingsRepository.updatedMapUiSettings, isNotNull);
    expect(
      settingsRepository.updatedMapUiSettings!.defaultOrigin,
      isNotNull,
    );
    expect(
      settingsRepository.updatedMapUiSettings!.defaultOrigin!.lat,
      closeTo(-20.6736, 0.000001),
    );
    expect(
      settingsRepository.updatedMapUiSettings!.defaultOrigin!.lng,
      closeTo(-40.4976, 0.000001),
    );
    expect(
      settingsRepository.updatedMapUiSettings!.defaultOrigin!.label,
      'Centro',
    );
    expect(repository.initCallCount, 1);
  });

  testWidgets('local preferences owns map filter configuration only',
      (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsLocalPreferencesScreen()),
    );

    expect(find.text('Filtros do mapa'), findsOneWidget);
    expect(
      find.byKey(TenantAdminSettingsKeys.localPreferencesMapFiltersCard),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.localPreferencesAddMapFilterButton),
      findsOneWidget,
    );
    expect(find.text('Filtros públicos'), findsNothing);
  });

  test(
    'discovery filters controller ignores load completion after disposal',
    () async {
      final fetchCompleter =
          Completer<TenantAdminDiscoveryFiltersSettingsValue>();
      final settingsRepository = _SlowDiscoveryFiltersSettingsRepository(
        fetchCompleter: fetchCompleter,
      );
      final controller = TenantAdminDiscoveryFiltersController(
        settingsRepository: settingsRepository,
        ruleCatalogRepository: _EmptyDiscoveryFilterRuleCatalogRepository(),
      );

      final loadFuture = controller.loadSettings();
      expect(settingsRepository.fetchCount, 1);

      await controller.onDispose();
      fetchCompleter.complete(TenantAdminDiscoveryFiltersSettingsValue());

      await loadFuture;
      await controller.onDispose();
    },
  );

  test('discovery filters controller init keeps already loaded settings',
      () async {
    final fetchCompleter = Completer<TenantAdminDiscoveryFiltersSettingsValue>()
      ..complete(
        TenantAdminDiscoveryFiltersSettingsValue(
          TenantAdminDynamicMapValue({
            'surfaces': {
              'public_map.primary': {
                'target': 'map_poi',
                'filters': [
                  {
                    'key': 'assets',
                    'label': 'Assets',
                    'image_uri': 'https://tenant.test/filter.png',
                  },
                ],
              },
            },
          }),
        ),
      );
    final settingsRepository = _SlowDiscoveryFiltersSettingsRepository(
      fetchCompleter: fetchCompleter,
    );
    final controller = TenantAdminDiscoveryFiltersController(
      settingsRepository: settingsRepository,
      ruleCatalogRepository: _EmptyDiscoveryFilterRuleCatalogRepository(),
    );

    await controller.init();
    await controller.init();

    expect(settingsRepository.fetchCount, 1);
    expect(
      controller
          .filtersForSurface(TenantAdminDiscoveryFilterSurfaceDefinition.map)
          .single
          .imageUri,
      'https://tenant.test/filter.png',
    );

    await controller.onDispose();
  });

  test(
    'discovery filters rule catalog fetches taxonomy terms in one batch',
    () async {
      final taxonomiesRepository = _FakeDiscoveryFilterTaxonomiesRepository();
      final controller = TenantAdminDiscoveryFiltersController(
        settingsRepository: _FakeTenantAdminSettingsRepository(),
        ruleCatalogRepository: TenantAdminDiscoveryFilterRuleCatalogRepository(
          accountProfilesRepository:
              _FakeDiscoveryFilterAccountProfilesRepository(),
          staticAssetsRepository: _FakeDiscoveryFilterStaticAssetsRepository(),
          taxonomiesRepository: taxonomiesRepository,
          eventsRepository: _FakeDiscoveryFilterEventsRepository(
            allowedTaxonomies: ['genre', 'cuisine'],
          ),
        ),
      );

      await controller.loadRuleCatalog();

      expect(taxonomiesRepository.loadAllTermsCallCount, 0);
      expect(taxonomiesRepository.batchTermsCallCount, 1);
      expect(taxonomiesRepository.batchTaxonomyIdGroups, hasLength(1));
      expect(taxonomiesRepository.batchTermLimits, <int>[200]);
      expect(
        taxonomiesRepository.lastBatchTaxonomyIds,
        containsAll(<String>['genre-id', 'cuisine-id']),
      );
      expect(
        controller.ruleCatalogStreamValue.value
            .taxonomyForSource(TenantAdminMapFilterSource.event)
            .map((term) => term.token)
            .toSet(),
        containsAll(<String>['genre:rock', 'cuisine:pizza']),
      );

      await controller.onDispose();
    },
  );

  test(
    'discovery filters rule catalog bounds taxonomy term batch requests',
    () async {
      final taxonomiesRepository = _FakeDiscoveryFilterTaxonomiesRepository(
        generatedTaxonomyCount: 101,
      );
      final allowedTaxonomies = List<String>.generate(
        101,
        (index) => 'generated_${index.toString().padLeft(3, '0')}',
      );
      final controller = TenantAdminDiscoveryFiltersController(
        settingsRepository: _FakeTenantAdminSettingsRepository(),
        ruleCatalogRepository: TenantAdminDiscoveryFilterRuleCatalogRepository(
          accountProfilesRepository:
              _FakeDiscoveryFilterAccountProfilesRepository(),
          staticAssetsRepository: _FakeDiscoveryFilterStaticAssetsRepository(),
          taxonomiesRepository: taxonomiesRepository,
          eventsRepository: _FakeDiscoveryFilterEventsRepository(
            allowedTaxonomies: allowedTaxonomies,
          ),
        ),
      );

      await controller.loadRuleCatalog();

      expect(taxonomiesRepository.loadAllTermsCallCount, 0);
      expect(taxonomiesRepository.batchTermsCallCount, 1);
      expect(
        taxonomiesRepository.batchTaxonomyIdGroups.map((group) => group.length),
        <int>[20],
      );
      expect(taxonomiesRepository.batchTermLimits, <int>[200]);

      await controller.onDispose();
    },
  );

  testWidgets('canonical map filter row exposes rule and visual actions',
      (tester) async {
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminDiscoveryFiltersController>(
      TenantAdminDiscoveryFiltersController(
        settingsRepository: settingsRepository,
        ruleCatalogRepository: _EmptyDiscoveryFilterRuleCatalogRepository(),
      ),
    );

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminDiscoveryFilterSurfaceScreen(
          surface: TenantAdminDiscoveryFilterSurfaceDefinition.map,
        ),
      ),
    );

    await tester.tap(
      find.byKey(TenantAdminDiscoveryFiltersKeys.addFilterButton),
    );
    await tester.pumpAndSettle();

    final rowFinder = find.byKey(
      TenantAdminDiscoveryFiltersKeys.filterRow('public_map.primary', 0),
    );
    expect(rowFinder, findsOneWidget);

    expect(
      find.byKey(
        TenantAdminDiscoveryFiltersKeys.filterRuleButton(
          'public_map.primary',
          0,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        TenantAdminDiscoveryFiltersKeys.filterVisualButton(
          'public_map.primary',
          0,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rowFinder, matching: find.text('Imagem')),
      findsNothing,
    );
    expect(
      find.descendant(of: rowFinder, matching: find.text('Limpar imagem')),
      findsNothing,
    );

    expect(find.text('Imagem'), findsNothing);
    expect(find.text('Limpar imagem'), findsNothing);
  });

  testWidgets(
    'canonical map filter row preview prefers marker override icon+color over image',
    (tester) async {
      final initialDiscoveryFilters =
          TenantAdminDiscoveryFiltersSettings.empty().applyFilters(
        surface: TenantAdminDiscoveryFilterSurfaceDefinition.map,
        filters: TenantAdminDiscoveryFilterCatalogItems([
          TenantAdminDiscoveryFilterCatalogItem(
            keyValue: _token('events'),
            labelValue: _requiredText('Eventos'),
            imageUriValue:
                _optionalUrl('https://tenant.test/legacy-events.png'),
            overrideMarkerValue: TenantAdminFlagValue(true),
            markerOverride: TenantAdminMapFilterMarkerOverride.icon(
              iconValue: _requiredText('music'),
              colorValue: _hexColor('#C6141F'),
              iconColorValue: _hexColor('#FFFFFF'),
            ),
            query: TenantAdminDiscoveryFilterQuery(
              entityValues: [_token('event')],
            ),
          ),
        ]),
      );
      final settingsRepository = _FakeTenantAdminSettingsRepository(
        initialDiscoveryFiltersSettings:
            TenantAdminDiscoveryFiltersSettingsValue(
          initialDiscoveryFilters.rawDiscoveryFilters,
        ),
      );
      GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
        settingsRepository,
      );
      GetIt.I.registerSingleton<TenantAdminDiscoveryFiltersController>(
        TenantAdminDiscoveryFiltersController(
          settingsRepository: settingsRepository,
          ruleCatalogRepository: _EmptyDiscoveryFilterRuleCatalogRepository(),
        ),
      );

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminDiscoveryFilterSurfaceScreen(
            surface: TenantAdminDiscoveryFilterSurfaceDefinition.map,
          ),
        ),
      );

      final rowFinder = find.byKey(
        TenantAdminDiscoveryFiltersKeys.filterRow('public_map.primary', 0),
      );
      expect(rowFinder, findsOneWidget);

      final iconFinder = find.descendant(
        of: rowFinder,
        matching: find.byIcon(MapMarkerVisualResolver.resolveIcon('music')),
      );
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder.first);
      expect(iconWidget.color, Colors.white);

      final previewFinder = find.byKey(
        TenantAdminDiscoveryFiltersKeys.filterVisualPreview(
          'public_map.primary',
          0,
        ),
      );
      expect(previewFinder, findsOneWidget);
      final previewContainer = tester.widget<Container>(previewFinder.first);
      final previewColor = previewContainer.color;
      expect(previewColor, isNotNull);
      expect((previewColor!.r * 255).round(), 0xC6);
      expect((previewColor.g * 255).round(), 0x14);
      expect((previewColor.b * 255).round(), 0x1F);
      expect(previewColor.a, closeTo(0.22, 0.005));
    },
  );

  testWidgets('canonical map filter row exposes image preview by URL key',
      (tester) async {
    const imageUri = 'https://tenant.test/filter-image.png';
    final initialDiscoveryFilters =
        TenantAdminDiscoveryFiltersSettings.empty().applyFilters(
      surface: TenantAdminDiscoveryFilterSurfaceDefinition.map,
      filters: TenantAdminDiscoveryFilterCatalogItems([
        TenantAdminDiscoveryFilterCatalogItem(
          keyValue: _token('assets'),
          labelValue: _requiredText('Assets'),
          imageUriValue: _optionalUrl(imageUri),
          query: TenantAdminDiscoveryFilterQuery(
            entityValues: [_token('static_asset')],
          ),
        ),
      ]),
    );
    final settingsRepository = _FakeTenantAdminSettingsRepository(
      initialDiscoveryFiltersSettings: TenantAdminDiscoveryFiltersSettingsValue(
        initialDiscoveryFilters.rawDiscoveryFilters,
      ),
    );
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminDiscoveryFiltersController>(
      TenantAdminDiscoveryFiltersController(
        settingsRepository: settingsRepository,
        ruleCatalogRepository: _EmptyDiscoveryFilterRuleCatalogRepository(),
      ),
    );

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminDiscoveryFilterSurfaceScreen(
          surface: TenantAdminDiscoveryFilterSurfaceDefinition.map,
        ),
      ),
    );

    final rowFinder = find.byKey(
      TenantAdminDiscoveryFiltersKeys.filterRow('public_map.primary', 0),
    );
    expect(rowFinder, findsOneWidget);

    final previewFinder = find.byKey(
      TenantAdminDiscoveryFiltersKeys.filterVisualPreview(
        'public_map.primary',
        0,
      ),
    );
    expect(previewFinder, findsOneWidget);
    expect(find.byKey(const ValueKey<String>(imageUri)), findsOneWidget);
  });

  testWidgets('map filter rule sheet is query-only (without visual fields)',
      (tester) async {
    final filter = TenantAdminMapFilterCatalogItem(
      keyValue: _token('events'),
      labelValue: _requiredText('Eventos'),
      query:
          TenantAdminMapFilterQuery(source: TenantAdminMapFilterSource.event),
    );
    final catalog = TenantAdminMapFilterRuleCatalog(
      typesBySource: TenantAdminMapFilterTypeOptionsBySourceValue({
        TenantAdminMapFilterSource.event: [
          TenantAdminMapFilterTypeOption(
            slugValue: _token('show'),
            labelValue: _requiredText('Show'),
          ),
        ],
      }),
      taxonomyTermsBySource: TenantAdminMapFilterTaxonomyOptionsBySourceValue({
        TenantAdminMapFilterSource.event: [
          TenantAdminMapFilterTaxonomyTermOption(
            tokenValue: _token('rock'),
            labelValue: _requiredText('Rock'),
            taxonomySlugValue: _token('genre'),
            taxonomyLabelValue: _requiredText('Gênero'),
          ),
        ],
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminMapFilterRuleSheet(
            filter: filter,
            catalog: catalog,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Regra do filtro'), findsOneWidget);
    expect(find.text('Origem'), findsOneWidget);
    expect(find.text('Tipos'), findsOneWidget);
    expect(find.text('Taxonomias'), findsOneWidget);
    expect(find.text('Sobrescrever marcador'), findsNothing);
    expect(find.text('Modo do marcador'), findsNothing);
    expect(find.text('Visual do filtro'), findsNothing);
  });

  testWidgets('Visual sheet owns canonical marker icon-image flow',
      (tester) async {
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminDiscoveryFiltersController>(
      TenantAdminDiscoveryFiltersController(
        settingsRepository: settingsRepository,
        ruleCatalogRepository: _EmptyDiscoveryFilterRuleCatalogRepository(),
      ),
    );

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminDiscoveryFilterSurfaceScreen(
          surface: TenantAdminDiscoveryFilterSurfaceDefinition.map,
        ),
      ),
    );

    await tester.tap(
      find.byKey(TenantAdminDiscoveryFiltersKeys.addFilterButton),
    );
    await tester.pumpAndSettle();

    final rowFinder = find.byKey(
      TenantAdminDiscoveryFiltersKeys.filterRow('public_map.primary', 0),
    );
    expect(rowFinder, findsOneWidget);

    await tester.tap(
      find.byKey(
        TenantAdminDiscoveryFiltersKeys.filterVisualButton(
          'public_map.primary',
          0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visual do filtro'), findsOneWidget);
    expect(find.text('Sobrescrever marcador'), findsOneWidget);
    expect(find.byType(TenantAdminMapMarkerIconPickerField), findsNothing);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.byType(TenantAdminMapMarkerIconPickerField), findsOneWidget);
    expect(find.text('Cor do marcador'), findsOneWidget);
    expect(find.text('Cor do ícone'), findsOneWidget);

    await tester.tap(find.text('Ícone').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Imagem').last);
    await tester.pumpAndSettle();

    expect(find.byType(TenantAdminMapMarkerIconPickerField), findsNothing);
    expect(
      find.widgetWithText(TextFormField, 'Imagem do marcador (URL)'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Imagem do marcador (URL)'),
      'https://guarappari.test/storage/filter-image.png',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(TenantAdminDiscoveryFiltersKeys.saveFiltersButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(TenantAdminDiscoveryFiltersKeys.saveFiltersButton),
    );
    await tester.pumpAndSettle();

    final updated = settingsRepository.updatedDiscoveryFiltersSettings;
    expect(updated, isNotNull);
    final raw = updated!.rawDiscoveryFilters.value;
    final surfaces = raw['surfaces'] as Map;
    final surface = surfaces['public_map.primary'] as Map;
    final filters = surface['filters'] as List;
    expect(filters, hasLength(1));
    final filter = filters.single as Map;
    expect(filter['override_marker'], isTrue);
    final markerOverride = filter['marker_override'] as Map;
    expect(markerOverride['mode'], 'image');
    expect(
      markerOverride['image_uri'],
      'https://guarappari.test/storage/filter-image.png',
    );
  });

  testWidgets('Visual sheet validates icon inputs before allowing apply',
      (tester) async {
    String latestSnackMessage() {
      final snackBars = tester.widgetList<SnackBar>(find.byType(SnackBar));
      expect(snackBars, isNotEmpty);
      final latest = snackBars.last.content;
      if (latest is Text) {
        return latest.data ?? '';
      }
      return latest.toStringShort();
    }

    final filter = TenantAdminMapFilterCatalogItem(
      keyValue: _token('events'),
      labelValue: _requiredText('Eventos'),
    );

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminMapFilterVisualSheet(
          filter: filter,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final visualSheetFinder = find
        .ancestor(
          of: find.text('Visual do filtro'),
          matching: find.byType(SafeArea),
        )
        .last;
    final applyButtonFinder = find.descendant(
      of: visualSheetFinder,
      matching: find.widgetWithText(FilledButton, 'Aplicar'),
    );

    await tester.tap(
      find.descendant(
        of: visualSheetFinder,
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(applyButtonFinder);
    await tester.pumpAndSettle();
    expect(
      latestSnackMessage(),
      contains('Visual inválido: em modo ícone'),
    );
  });

  testWidgets('Visual sheet validates image url when override mode is image',
      (tester) async {
    final filter = TenantAdminMapFilterCatalogItem(
      keyValue: _token('events'),
      labelValue: _requiredText('Eventos'),
      imageUriValue: _optionalUrl('https://tenant.test/filter.png'),
      overrideMarkerValue: TenantAdminFlagValue(true),
      markerOverride: TenantAdminMapFilterMarkerOverride.image(
        imageUriValue: _optionalUrl('https://tenant.test/filter.png'),
      ),
      query:
          TenantAdminMapFilterQuery(source: TenantAdminMapFilterSource.event),
    );

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminMapFilterVisualSheet(filter: filter),
      ),
    );

    expect(find.text('Visual do filtro'), findsOneWidget);
    expect(find.text('Sobrescrever marcador'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Imagem do marcador (URL)'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Imagem do marcador (URL)'),
      'invalid-url',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
    await tester.pumpAndSettle();

    final snackBars = tester.widgetList<SnackBar>(find.byType(SnackBar));
    expect(snackBars, isNotEmpty);
    final latest = snackBars.last.content;
    final message =
        latest is Text ? (latest.data ?? '') : latest.toStringShort();
    expect(message, contains('URL válida (http/https)'));
  });

  testWidgets(
      'map marker icon picker writes storage key when user selects icon',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TenantAdminMapMarkerIconPickerField(
            controller: controller,
            labelText: 'Ícone',
          ),
        ),
      ),
    );

    expect(controller.text, isEmpty);
    expect(find.text('Selecionar ícone'), findsOneWidget);

    await tester.tap(find.byTooltip('Selecionar ícone'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Museu').first,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Museu').first);
    await tester.pumpAndSettle();

    expect(controller.text, MapMarkerIconToken.museum.storageKey);
    expect(find.text('Museu'), findsOneWidget);
  });

  testWidgets('saves firebase settings via remote repository', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminSettingsTechnicalIntegrationsScreen(
          initialSection: TenantAdminSettingsIntegrationSection.appLinks,
        ),
      ),
    );

    final projectIdRow = find.byKey(
      const ValueKey('tenant_admin_settings_firebase_project_id_edit'),
    );
    final saveFirebaseButton = find.byKey(
      const ValueKey('tenant_admin_settings_save_firebase'),
    );

    await tester.scrollUntilVisible(
      projectIdRow,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: projectIdRow,
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Project ID'),
      'project-updated',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      saveFirebaseButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(saveFirebaseButton);
    await tester.pumpAndSettle();

    expect(settingsRepository.updatedFirebaseProjectId, 'project-updated');
  });

  testWidgets('saves resend email settings via remote repository',
      (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminSettingsTechnicalIntegrationsScreen(
          initialSection: TenantAdminSettingsIntegrationSection.resend,
        ),
      ),
    );

    final tokenRow = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsResendTokenEdit,
      skipOffstage: false,
    );
    final fromRow = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsResendFromEdit,
      skipOffstage: false,
    );
    final toRow = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsResendToEdit,
      skipOffstage: false,
    );
    final saveButton = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsSaveResend,
      skipOffstage: false,
    );

    await tester.scrollUntilVisible(
      tokenRow,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: tokenRow,
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'API Token'),
      're_token_updated',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: fromRow,
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'From'),
      'Belluga <noreply@belluga.space>',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: toRow,
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'To'),
      'owner@belluga.space, ops@belluga.space',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      saveButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(settingsRepository.updatedResendEmailSettings, isNotNull);
    expect(
      settingsRepository.updatedResendEmailSettings!.token,
      're_token_updated',
    );
    expect(
      settingsRepository.updatedResendEmailSettings!.from,
      'Belluga <noreply@belluga.space>',
    );
    expect(
      _recipientStrings(settingsRepository.updatedResendEmailSettings!.to),
      equals(['owner@belluga.space', 'ops@belluga.space']),
    );
  });

  testWidgets('saves outbound webhook settings via remote repository',
      (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminSettingsTechnicalIntegrationsScreen(
          initialSection: TenantAdminSettingsIntegrationSection.outbound,
        ),
      ),
    );

    final whatsappRow = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsOutboundWhatsappWebhookEdit,
      skipOffstage: false,
    );
    final otpRow = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsOutboundOtpSmsUrlEdit,
      skipOffstage: false,
    );
    final ttlRow = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsOutboundOtpTtlEdit,
      skipOffstage: false,
    );
    final saveButton = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsSaveOutbound,
      skipOffstage: false,
    );

    await tester.scrollUntilVisible(
      whatsappRow,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Webhook WhatsApp'), findsOneWidget);
    expect(find.text('Secondary OTP Channel com SMS'), findsOneWidget);
    expect(find.text('URL SMS'), findsOneWidget);
    expect(find.text('Webhook OTP'), findsNothing);
    expect(find.text('Usar webhook WhatsApp para OTP'), findsNothing);
    expect(find.text('Canal OTP'), findsNothing);

    await tester.tap(
      find.descendant(
        of: whatsappRow,
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Webhook WhatsApp'),
      'https://integrations.example/whatsapp-updated',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: otpRow,
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'URL SMS'),
      'https://integrations.example/otp-updated',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: ttlRow,
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'TTL OTP (min)'),
      '8',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      saveButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(settingsRepository.updatedOutboundIntegrationsSettings, isNotNull);
    expect(
      settingsRepository
          .updatedOutboundIntegrationsSettings!.whatsappWebhookUrl,
      'https://integrations.example/whatsapp-updated',
    );
    expect(
      settingsRepository.updatedOutboundIntegrationsSettings!.otpWebhookUrl,
      'https://integrations.example/otp-updated',
    );
    expect(
      settingsRepository
          .updatedOutboundIntegrationsSettings!.otpUseWhatsappWebhook,
      isTrue,
    );
    expect(
      settingsRepository
          .updatedOutboundIntegrationsSettings!.otpDeliveryChannel,
      'whatsapp',
    );
    expect(
      settingsRepository.updatedOutboundIntegrationsSettings!.otpTtlMinutes,
      8,
    );
  });

  testWidgets('shows SMS URL only when secondary OTP SMS channel is enabled',
      (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository()
      .._outboundIntegrationsSettings = TenantAdminOutboundIntegrationsSettings(
        whatsappWebhookUrlValue:
            _optionalUrl('https://integrations.example/whatsapp'),
        otpUseWhatsappWebhookValue: _booleanValue(true),
        otpDeliveryChannelValue: _token('whatsapp'),
        otpTtlMinutesValue: _positiveInt(10),
        otpResendCooldownSecondsValue: _positiveInt(60),
        otpMaxAttemptsValue: _positiveInt(5),
      );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminSettingsTechnicalIntegrationsScreen(
          initialSection: TenantAdminSettingsIntegrationSection.outbound,
        ),
      ),
    );

    final smsSwitch = find.byKey(
      TenantAdminSettingsKeys
          .technicalIntegrationsOutboundOtpSmsSecondarySwitch,
      skipOffstage: false,
    );
    await tester.scrollUntilVisible(
      smsSwitch,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Secondary OTP Channel com SMS'), findsOneWidget);
    expect(find.text('URL SMS'), findsNothing);

    await tester.tap(smsSwitch);
    await tester.pumpAndSettle();

    expect(find.text('URL SMS'), findsOneWidget);
  });

  testWidgets('saves and deletes telemetry integrations via remote repository',
      (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminSettingsTechnicalIntegrationsScreen(
          initialSection: TenantAdminSettingsIntegrationSection.telemetry,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Telemetry'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('firebase'), findsNothing);
    expect(find.text('mixpanel'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Token'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'URL webhook'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Token'),
      'mixpanel-token-123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Eventos (separados por vírgula)'),
      'app_opened',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar integração'));
    await tester.pumpAndSettle();

    expect(settingsRepository.lastTelemetryIntegration, isNotNull);
    expect(settingsRepository.lastTelemetryIntegration!.type, 'mixpanel');
    expect(
      settingsRepository.lastTelemetryIntegration!.token,
      'mixpanel-token-123',
    );
    expect(
      settingsRepository.lastTelemetryIntegration!.events,
      equals(['app_opened']),
    );
    expect(find.text('track_all=true'), findsNothing);
    expect(find.text('mixpanel'), findsNWidgets(2));
    expect(find.text('app_opened'), findsWidgets);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(settingsRepository.deletedTelemetryTypes, equals(['mixpanel']));
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('telemetry webhook mode shows URL field instead of token',
      (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminSettingsTechnicalIntegrationsScreen(
          initialSection: TenantAdminSettingsIntegrationSection.telemetry,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Telemetry'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('webhook').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Token'), findsNothing);
    expect(find.widgetWithText(TextField, 'URL webhook'), findsOneWidget);
  });

  testWidgets('saves app links settings via remote repository', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminSettingsTechnicalIntegrationsScreen(
          initialSection: TenantAdminSettingsIntegrationSection.appLinks,
        ),
      ),
    );

    final packageRow = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsAppLinksAndroidPackageEdit,
      skipOffstage: false,
    );
    final androidPublicationSwitch = find.byKey(
      TenantAdminSettingsKeys
          .technicalIntegrationsAppLinksAndroidPublicationSwitch,
      skipOffstage: false,
    );
    final androidStoreUrlRow = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsAppLinksAndroidStoreUrlEdit,
      skipOffstage: false,
    );
    final fingerprintsRow = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsAppLinksFingerprintsEdit,
      skipOffstage: false,
    );
    final saveButton = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsSaveAppLinks,
      skipOffstage: false,
    );

    await tester.scrollUntilVisible(
      packageRow,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Publicação'), findsOneWidget);
    await tester.scrollUntilVisible(
      androidPublicationSwitch,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(androidPublicationSwitch);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      androidStoreUrlRow,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: androidStoreUrlRow,
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'URL Android'),
      'https://play.google.com/store/apps/details?id=com.guarappari.app',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
          of: packageRow, matching: find.byIcon(Icons.edit_outlined)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Package'),
      'com.guarappari.app',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      fingerprintsRow,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: fingerprintsRow,
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Fingerprints'),
      '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:AA:23:11:22:33:44:55:66:77:88:99',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      saveButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(settingsRepository.updatedAppLinksSettings, isNotNull);
    expect(
      settingsRepository.updatedAppLinksSettings!.androidAppIdentifier,
      'com.guarappari.app',
    );
    expect(
      settingsRepository.updatedAppLinksSettings!.androidSha256CertFingerprints,
      equals(
        [
          '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:AA:23:11:22:33:44:55:66:77:88:99',
        ],
      ),
    );
    expect(
      settingsRepository.updatedAppLinksSettings!.androidPublicationEnabled,
      isTrue,
    );
    expect(
      settingsRepository.updatedAppLinksSettings!.androidStoreUrl,
      'https://play.google.com/store/apps/details?id=com.guarappari.app',
    );
  });

  testWidgets(
      'updates iOS paths via canonical checklist before saving app links',
      (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminSettingsTechnicalIntegrationsScreen(
          initialSection: TenantAdminSettingsIntegrationSection.appLinks,
        ),
      ),
    );

    final iosPathsRow = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsAppLinksIosPathsEdit,
      skipOffstage: false,
    );
    final saveButton = find.byKey(
      TenantAdminSettingsKeys.technicalIntegrationsSaveAppLinks,
      skipOffstage: false,
    );

    await tester.scrollUntilVisible(
      iosPathsRow,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: iosPathsRow,
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selecionar iOS paths'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(CheckboxListTile, '/home'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, '/home'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Aplicar'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      saveButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(settingsRepository.updatedAppLinksSettings, isNotNull);
    expect(
      settingsRepository.updatedAppLinksSettings!.iosPaths,
      equals(['/invite*', '/convites*', '/home']),
    );
  });

  testWidgets('saves branding settings via remote repository', (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsVisualIdentityScreen()),
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.visualIdentityScopedAppBar),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.visualIdentityBackButton),
      findsOneWidget,
    );
    expect(find.byKey(TenantAdminSettingsKeys.brandingPrimaryField),
        findsOneWidget);
    expect(find.byKey(TenantAdminSettingsKeys.brandingSecondaryField),
        findsOneWidget);
    expect(
      find.byKey(TenantAdminSettingsKeys.brandingPrimaryPickerButton),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.brandingSecondaryPickerButton),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.brandingPublicMetadataTitleField),
      findsOneWidget,
    );
    expect(
      find.byKey(
        TenantAdminSettingsKeys.brandingPublicMetadataDescriptionField,
      ),
      findsOneWidget,
    );
    expect(find.text('Favicon (.ico)'), findsOneWidget);
    expect(
      find.byKey(TenantAdminSettingsKeys.brandingFaviconPreview),
      findsOneWidget,
    );
    expect(find.text('Fallback ativo pelo icone PWA'), findsOneWidget);
    expect(find.text('Publicacao atual: /favicon.ico'), findsOneWidget);
    expect(
      find.textContaining('Preview atualmente entregue por /favicon.ico'),
      findsOneWidget,
    );
    expect(
      find.textContaining('essa rota usa fallback do icone PWA'),
      findsOneWidget,
    );

    final primaryPickerButton = find.byKey(
      TenantAdminSettingsKeys.brandingPrimaryPickerButton,
    );
    await tester.scrollUntilVisible(
      primaryPickerButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(primaryPickerButton);
    await tester.pumpAndSettle();

    final pickerDialog = find.byType(AlertDialog);
    final hexInputField = find.descendant(
      of: pickerDialog,
      matching: find.byType(TextFormField),
    );

    expect(find.text('#E53935'), findsNothing);
    expect(hexInputField, findsOneWidget);

    await tester.enterText(hexInputField, '#A36CE3');
    await tester.pumpAndSettle();

    expect(find.text('Aplicar cor'), findsOneWidget);
    await tester.tap(find.text('Aplicar cor'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(TenantAdminSettingsKeys.brandingPublicMetadataTitleField),
      'Guarappari Home',
    );
    await tester.enterText(
      find.byKey(
        TenantAdminSettingsKeys.brandingPublicMetadataDescriptionField,
      ),
      'Fallback institucional da home.',
    );
    await tester.pumpAndSettle();

    final saveBrandingButton = find.byKey(
      const ValueKey('tenant_admin_settings_save_branding'),
    );

    await tester.scrollUntilVisible(
      saveBrandingButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(saveBrandingButton);
    await tester.pumpAndSettle();

    expect(settingsRepository.lastBrandingInput, isNotNull);
    expect(settingsRepository.lastBrandingInput!.tenantName, 'Tenant Test');
    expect(
      settingsRepository.lastBrandingInput!.primarySeedColor,
      '#A36CE3',
    );
    expect(
      settingsRepository.lastBrandingInput!.secondarySeedColor,
      '#673AB7',
    );
    expect(
      settingsRepository.lastBrandingInput!.publicWebDefaultTitle,
      'Guarappari Home',
    );
    expect(
      settingsRepository.lastBrandingInput!.publicWebDefaultDescription,
      'Fallback institucional da home.',
    );
  });

  testWidgets('renders dedicated favicon preview status when ico exists',
      (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository(
      initialHasDedicatedFavicon: true,
      initialUsesPwaFaviconFallback: false,
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsVisualIdentityScreen()),
    );

    expect(
      find.byKey(TenantAdminSettingsKeys.brandingFaviconPreview),
      findsOneWidget,
    );
    expect(find.text('.ico dedicado salvo'), findsOneWidget);
    expect(
      find.text('Preview atualmente publicado em /favicon.ico.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'disables apply in branding color picker when typed hex is invalid',
      (tester) async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    GetIt.I.registerSingleton<AppDataRepositoryContract>(repository);
    GetIt.I.registerSingleton<TenantAdminSettingsRepositoryContract>(
      settingsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(
        externalImageProxy: _FakeTenantAdminExternalImageProxy(),
      ),
    );
    final controller = TenantAdminSettingsController();
    GetIt.I.registerSingleton<TenantAdminSettingsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminSettingsVisualIdentityScreen()),
    );

    final primaryPickerButton = find.byKey(
      TenantAdminSettingsKeys.brandingPrimaryPickerButton,
    );
    await tester.scrollUntilVisible(
      primaryPickerButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(primaryPickerButton);
    await tester.pumpAndSettle();

    final pickerDialog = find.byType(AlertDialog);
    final hexInputField = find.descendant(
      of: pickerDialog,
      matching: find.byType(TextFormField),
    );
    final applyButtonFinder = find.widgetWithText(FilledButton, 'Aplicar cor');

    expect(hexInputField, findsOneWidget);
    expect(applyButtonFinder, findsOneWidget);

    await tester.enterText(hexInputField, '#12345');
    await tester.pumpAndSettle();

    expect(find.text('Formato inválido. Use #RRGGBB.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(applyButtonFinder).onPressed,
      isNull,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    final saveBrandingButton = find.byKey(
      const ValueKey('tenant_admin_settings_save_branding'),
    );
    await tester.scrollUntilVisible(
      saveBrandingButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveBrandingButton);
    await tester.pumpAndSettle();

    expect(settingsRepository.lastBrandingInput, isNotNull);
    expect(settingsRepository.lastBrandingInput!.primarySeedColor, '#009688');
  });

  test('controller saves branding light logo upload using project asset bytes',
      () async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
    );
    final ingestionService = TenantAdminImageIngestionService(
      externalImageProxy: _FakeTenantAdminExternalImageProxy(),
    );
    await controller.init();

    final logoFile = File('assets/images/logo_horizontal.png');
    expect(logoFile.existsSync(), isTrue);
    final logoBytes = await logoFile.readAsBytes();
    expect(logoBytes, isNotEmpty);
    final upload = await ingestionService.buildUpload(
      XFile.fromData(
        logoBytes,
        mimeType: 'image/png',
        name: 'logo_horizontal.png',
      ),
      slot: TenantAdminImageSlot.lightLogo,
    );
    expect(upload, isNotNull);
    expect(upload!.bytes, isNotEmpty);
    expect(upload.mimeType, 'image/png');
    expect(upload.fileName, endsWith('.png'));
    expect(upload.bytes.take(8).toList(),
        equals([137, 80, 78, 71, 13, 10, 26, 10]));

    await controller.saveBranding(
      lightLogoUpload: upload,
      darkLogoUpload: null,
      lightIconUpload: null,
      darkIconUpload: null,
      faviconUpload: null,
      pwaIconUpload: null,
      publicWebDefaultImageUpload: null,
    );

    final savedUpload = settingsRepository.lastBrandingInput?.lightLogoUpload;
    expect(savedUpload, isNotNull);
    expect(savedUpload!.bytes, isNotEmpty);
    expect(savedUpload.mimeType, 'image/png');
    expect(savedUpload.fileName, endsWith('.png'));
    expect(savedUpload.bytes.take(8).toList(),
        equals([137, 80, 78, 71, 13, 10, 26, 10]));
    expect(
      controller.brandingLightLogoUrlStreamValue.value,
      allOf(
        contains('https://guarappari.test/storage/light-logo.png'),
        contains('v='),
      ),
    );

    controller.onDispose();
  });

  test(
      'controller uses selected tenant domain for branding preview url in landlord mode',
      () async {
    final repository = _FakeAppDataRepository(
      _buildAppData(mainDomain: 'https://belluga.app'),
    );
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    final tenantScope = _FakeTenantScope('guarappari.test');
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
      tenantScope: tenantScope,
    );

    await controller.init();
    expect(
      controller.brandingLightLogoUrlStreamValue.value,
      allOf(
        contains('https://guarappari.test/logo-light.png'),
        contains('v='),
      ),
    );

    await controller.saveBranding(
      lightLogoUpload: null,
      darkLogoUpload: null,
      lightIconUpload: null,
      darkIconUpload: null,
      faviconUpload: null,
      pwaIconUpload: null,
      publicWebDefaultImageUpload: null,
    );

    expect(
      controller.brandingLightLogoUrlStreamValue.value,
      allOf(
        contains('https://guarappari.test/logo-light.png'),
        contains('v='),
      ),
    );
    controller.onDispose();
  });

  test(
      'controller falls back to canonical tenant pwa icon endpoint when repository pwa url is missing',
      () async {
    final repository = _FakeAppDataRepository(
      _buildAppData(mainDomain: 'https://belluga.app'),
    );
    final settingsRepository =
        _FakeTenantAdminSettingsRepository(initialPwaIconUrl: null);
    final tenantScope = _FakeTenantScope('guarappari.test');
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
      tenantScope: tenantScope,
    );

    await controller.init();

    expect(
      controller.brandingPwaIconUrlStreamValue.value,
      allOf(
        contains('https://guarappari.test/icon/icon-512x512.png'),
        contains('v='),
      ),
    );
    controller.onDispose();
  });

  test('controller reports recoverable app data refresh failures to Sentry',
      () async {
    final sentryCaptures = <_SentryCapture>[];
    SentryErrorReporter.overrideCaptureExceptionForTesting(
      (throwable, {stackTrace, hint, message, withScope}) async {
        sentryCaptures.add(
          _SentryCapture(
            throwable: throwable,
            stackTrace: stackTrace,
            withScope: withScope,
          ),
        );
        return SentryId.empty();
      },
    );
    final repository = _FakeAppDataRepository(
      _buildAppData(),
      failInitOnCall: 1,
    );
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
    );
    controller.domainPathController.text = 'novo.guarappari.test';

    await controller.createDomain();

    expect(sentryCaptures, hasLength(1));
    expect(sentryCaptures.single.throwable, isA<StateError>());
    expect(sentryCaptures.single.stackTrace, isA<StackTrace>());
    controller.onDispose();
  });

  test('controller rehydrates branding colors from repository after save',
      () async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
    );

    await controller.init();
    controller.brandingPrimarySeedColorController.text = '#A36CE3';
    controller.brandingSecondarySeedColorController.text = '#03DAC6';

    await controller.saveBranding(
      lightLogoUpload: null,
      darkLogoUpload: null,
      lightIconUpload: null,
      darkIconUpload: null,
      faviconUpload: null,
      pwaIconUpload: null,
      publicWebDefaultImageUpload: null,
    );

    final reloadedController = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
    );
    await reloadedController.init();

    expect(
      reloadedController.brandingPrimarySeedColorController.text,
      '#A36CE3',
    );
    expect(
      reloadedController.brandingSecondarySeedColorController.text,
      '#03DAC6',
    );

    controller.onDispose();
    reloadedController.onDispose();
  });

  test('controller forwards favicon upload and refreshes favicon preview url',
      () async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
    );

    await controller.init();

    final faviconUpload = tenantAdminMediaUploadFromRaw(
      bytes: Uint8List.fromList([0, 0, 1, 0, 1, 0, 16, 16]),
      fileName: 'favicon.ico',
      mimeType: 'image/x-icon',
    );

    await controller.saveBranding(
      lightLogoUpload: null,
      darkLogoUpload: null,
      lightIconUpload: null,
      darkIconUpload: null,
      faviconUpload: faviconUpload,
      pwaIconUpload: null,
      publicWebDefaultImageUpload: null,
    );

    expect(settingsRepository.lastBrandingInput?.faviconUpload, isNotNull);
    expect(
      settingsRepository.lastBrandingInput?.faviconUpload?.fileName,
      'favicon.ico',
    );
    expect(
      controller.brandingFaviconUrlStreamValue.value,
      allOf(
        contains('https://guarappari.test/favicon.ico'),
        contains('v='),
      ),
    );

    controller.onDispose();
  });

  test('controller restores remote favicon preview after clearing local upload',
      () async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
    );

    await controller.init();

    final initialPreviewUrl = controller.brandingFaviconUrlStreamValue.value;
    expect(initialPreviewUrl, isNotNull);

    final faviconUpload = tenantAdminMediaUploadFromRaw(
      bytes: Uint8List.fromList([0, 0, 1, 0, 1, 0, 16, 16]),
      fileName: 'favicon.ico',
      mimeType: 'image/x-icon',
    );

    controller.updateBrandingFaviconUpload(faviconUpload);
    expect(controller.brandingFaviconUrlStreamValue.value, isNull);

    controller.clearBrandingFaviconUpload();

    expect(controller.brandingFaviconUploadStreamValue.value, isNull);
    expect(
      controller.brandingFaviconUrlStreamValue.value,
      initialPreviewUrl,
    );

    controller.onDispose();
  });

  test(
      'controller keeps branding draft empty and reports error when branding fetch fails',
      () async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository =
        _FakeTenantAdminSettingsRepository(throwOnBrandingFetch: true);
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
    );

    await controller.init();

    expect(
      controller.remoteErrorStreamValue.value,
      contains('branding unavailable'),
    );
    expect(controller.brandingTenantNameController.text, isEmpty);
    expect(controller.brandingPrimarySeedColorController.text, isEmpty);
    expect(controller.brandingSecondarySeedColorController.text, isEmpty);
    expect(controller.brandingLightLogoUrlStreamValue.value, isNull);

    controller.onDispose();
  });

  test('controller consumes shared location picker confirmation stream',
      () async {
    final repository = _FakeAppDataRepository(_buildAppData());
    final settingsRepository = _FakeTenantAdminSettingsRepository();
    final locationSelection = TenantAdminLocationSelectionService();
    final controller = TenantAdminSettingsController(
      appDataRepository: repository,
      settingsRepository: settingsRepository,
      locationSelectionService: locationSelection,
    );

    controller.bindLocalPreferencesFlow();
    locationSelection.setInitialLocation(
      tenantAdminLocationFromRaw(
        latitude: -20.612345,
        longitude: -40.487654,
      ),
    );
    locationSelection.confirmSelection();
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.mapDefaultOriginLatitudeController.text,
      '-20.612345',
    );
    expect(
      controller.mapDefaultOriginLongitudeController.text,
      '-40.487654',
    );
    controller.onDispose();
  });
}

Future<void> _pumpWithAutoRoute(
  WidgetTester tester,
  Widget child,
) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: _settingsTestRouteNameForChild(child),
        path: '/',
        meta: _settingsTestMetaForChild(child),
        builder: (_, __) => child,
      ),
    ],
  )..ignorePopCompleters = true;

  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _settingsTestMetaForChild(Widget child) {
  if (_isInternalSettingsTestChild(child)) {
    return canonicalRouteMeta(
      family: CanonicalRouteFamily.tenantAdminSettingsInternal,
      chromeMode: RouteChromeMode.scopedSectionAppBar,
    );
  }

  return canonicalRouteMeta(
    family: CanonicalRouteFamily.tenantAdminSettingsRoot,
  );
}

String _settingsTestRouteNameForChild(Widget child) {
  if (_isScaffoldWithBody<TenantAdminSettingsEnvironmentSnapshotScreen>(
      child)) {
    return 'settings-environment-snapshot-test';
  }
  if (_isScaffoldWithBody<TenantAdminSettingsDomainsScreen>(child)) {
    return 'settings-domains-test';
  }
  if (_isScaffoldWithBody<TenantAdminSettingsLocalPreferencesScreen>(child)) {
    return 'settings-local-preferences-test';
  }
  if (_isScaffoldWithBody<TenantAdminSettingsTechnicalIntegrationsScreen>(
    child,
  )) {
    return 'settings-technical-integrations-test';
  }
  if (_isScaffoldWithBody<TenantAdminSettingsVisualIdentityScreen>(child)) {
    return 'settings-visual-identity-test';
  }
  return 'settings-test';
}

bool _isInternalSettingsTestChild(Widget child) {
  return _isScaffoldWithBody<TenantAdminSettingsEnvironmentSnapshotScreen>(
        child,
      ) ||
      _isScaffoldWithBody<TenantAdminSettingsDomainsScreen>(child) ||
      _isScaffoldWithBody<TenantAdminSettingsLocalPreferencesScreen>(child) ||
      _isScaffoldWithBody<TenantAdminSettingsTechnicalIntegrationsScreen>(
        child,
      ) ||
      _isScaffoldWithBody<TenantAdminSettingsVisualIdentityScreen>(child);
}

bool _isScaffoldWithBody<T extends Widget>(Widget child) {
  return child is Scaffold && child.body is T;
}

class _FakeDiscoveryFilterAccountProfilesRepository
    extends TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return const <TenantAdminProfileTypeDefinition>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDiscoveryFilterStaticAssetsRepository
    extends TenantAdminStaticAssetsRepositoryContract {
  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async {
    return const <TenantAdminStaticProfileTypeDefinition>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDiscoveryFilterEventsRepository
    extends TenantAdminEventsRepositoryContract {
  _FakeDiscoveryFilterEventsRepository({
    this.allowedTaxonomies = const <String>[],
  });

  final List<String> allowedTaxonomies;

  @override
  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    if (allowedTaxonomies.isEmpty) {
      return const <TenantAdminEventType>[];
    }
    return [
      TenantAdminEventType.withAllowedTaxonomies(
        nameValue: tenantAdminRequiredText('Event'),
        slugValue: tenantAdminRequiredText('event'),
        allowedTaxonomiesValue: tenantAdminTrimmedStringList(
          allowedTaxonomies,
        ),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDiscoveryFilterTaxonomiesRepository
    extends TenantAdminTaxonomiesRepositoryContract
    implements TenantAdminTaxonomiesBatchTermsRepositoryContract {
  _FakeDiscoveryFilterTaxonomiesRepository({
    int generatedTaxonomyCount = 0,
  })  : _generatedTaxonomyCount = generatedTaxonomyCount,
        _taxonomies = generatedTaxonomyCount > 0
            ? List<TenantAdminTaxonomyDefinition>.generate(
                generatedTaxonomyCount,
                (index) => _taxonomyDefinition(
                  id: 'generated-${index.toString().padLeft(3, '0')}',
                  slug: 'generated_${index.toString().padLeft(3, '0')}',
                  name: 'Generated ${index.toString().padLeft(3, '0')}',
                  appliesTo: ['event'],
                ),
              )
            : [
                _taxonomyDefinition(
                  id: 'genre-id',
                  slug: 'genre',
                  name: 'Gênero Musical',
                  appliesTo: ['event'],
                ),
                _taxonomyDefinition(
                  id: 'cuisine-id',
                  slug: 'cuisine',
                  name: 'Cozinha',
                  appliesTo: ['event'],
                ),
              ];

  final int _generatedTaxonomyCount;
  final List<TenantAdminTaxonomyDefinition> _taxonomies;
  int loadAllTermsCallCount = 0;
  int batchTermsCallCount = 0;
  List<String> lastBatchTaxonomyIds = const <String>[];
  List<List<String>> batchTaxonomyIdGroups = const <List<String>>[];
  List<int> batchTermLimits = const <int>[];

  final Map<String, List<TenantAdminTaxonomyTermDefinition>> _termsById = {
    'genre-id': [
      _taxonomyTermDefinition(
        id: 'rock-id',
        taxonomyId: 'genre-id',
        slug: 'rock',
        name: 'Rock',
      ),
    ],
    'cuisine-id': [
      _taxonomyTermDefinition(
        id: 'pizza-id',
        taxonomyId: 'cuisine-id',
        slug: 'pizza',
        name: 'Pizza',
      ),
    ],
  };

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return _taxonomies;
  }

  @override
  Future<void> loadAllTerms({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoInt? pageSize,
  }) async {
    loadAllTermsCallCount += 1;
    await super.loadAllTerms(taxonomyId: taxonomyId, pageSize: pageSize);
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return _termsById[taxonomyId.value] ??
        const <TenantAdminTaxonomyTermDefinition>[];
  }

  @override
  Future<TenantAdminTaxonomyTermsByTaxonomyId> fetchTermsByTaxonomyIds({
    required List<TenantAdminTaxRepoString> taxonomyIds,
    TenantAdminTaxRepoInt? termLimit,
  }) async {
    batchTermsCallCount += 1;
    lastBatchTaxonomyIds = taxonomyIds.map((entry) => entry.value).toList();
    batchTaxonomyIdGroups = [
      ...batchTaxonomyIdGroups,
      lastBatchTaxonomyIds,
    ];
    batchTermLimits = [
      ...batchTermLimits,
      termLimit?.value ?? 200,
    ];

    return TenantAdminTaxonomyTermsByTaxonomyId(
      entries: [
        for (final taxonomyId in taxonomyIds)
          TenantAdminTaxonomyTermsForTaxonomyId(
            taxonomyIdValue: tenantAdminRequiredText(taxonomyId.value),
            terms: _generatedTaxonomyCount > 0
                ? [
                    _taxonomyTermDefinition(
                      id: '${taxonomyId.value}-term',
                      taxonomyId: taxonomyId.value,
                      slug: 'term',
                      name: 'Term',
                    ),
                  ]
                : _termsById[taxonomyId.value] ??
                    const <TenantAdminTaxonomyTermDefinition>[],
          ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData, {this.failInitOnCall});

  final AppData _appData;
  final int? failInitOnCall;
  int initCallCount = 0;

  @override
  AppData get appData => _appData;

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;
  final StreamValue<DistanceInMetersValue> _maxRadiusMetersStreamValue =
      StreamValue<DistanceInMetersValue>(
          defaultValue:
              DistanceInMetersValue.fromRaw(1000, defaultValue: 1000));

  @override
  DistanceInMetersValue get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _themeModeStreamValue;
  final StreamValue<ThemeMode?> _themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.system;

  @override
  Future<void> init() async {
    initCallCount += 1;
    if (initCallCount == failInitOnCall) {
      throw StateError('app data refresh failed');
    }
  }

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    _maxRadiusMetersStreamValue.addValue(meters);
  }

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    _themeModeStreamValue.addValue(mode.value);
  }
}

class _SentryCapture {
  _SentryCapture({
    required this.throwable,
    required this.stackTrace,
    required this.withScope,
  });

  final dynamic throwable;
  final dynamic stackTrace;
  final ScopeCallback? withScope;
}

class _FakeTenantAdminSettingsRepository
    extends TenantAdminSettingsRepositoryContract {
  _FakeTenantAdminSettingsRepository({
    this.throwOnBrandingFetch = false,
    this.createDomainError,
    String? initialPwaIconUrl = 'https://guarappari.test/storage/pwa-icon.png',
    bool initialHasDedicatedFavicon = false,
    bool initialUsesPwaFaviconFallback = true,
    TenantAdminMapUiSettings? initialMapUiSettings,
    TenantAdminDiscoveryFiltersSettingsValue? initialDiscoveryFiltersSettings,
    List<TenantAdminDomainEntry>? initialDomains,
  })  : _brandingSettings = TenantAdminBrandingSettings(
          tenantName: _requiredText('Tenant Test'),
          brightnessDefault: TenantAdminBrandingBrightness.light,
          primarySeedColor: _hexColor('#009688'),
          secondarySeedColor: _hexColor('#673AB7'),
          publicWebDefaultTitle: _optionalText('Tenant Home'),
          publicWebDefaultDescription:
              _optionalText('Fallback institucional inicial.'),
          publicWebDefaultImageUrl:
              _optionalUrl('https://guarappari.test/storage/public-web.jpg'),
          lightLogoUrl:
              _optionalUrl('https://guarappari.test/storage/light-logo.png'),
          darkLogoUrl:
              _optionalUrl('https://guarappari.test/storage/dark-logo.png'),
          lightIconUrl:
              _optionalUrl('https://guarappari.test/storage/light-icon.png'),
          darkIconUrl:
              _optionalUrl('https://guarappari.test/storage/dark-icon.png'),
          faviconUrl: _optionalUrl('https://guarappari.test/favicon.ico'),
          pwaIconUrl: initialPwaIconUrl == null
              ? null
              : _optionalUrl(initialPwaIconUrl),
          hasDedicatedFaviconValue: _booleanValue(initialHasDedicatedFavicon),
          usesPwaFaviconFallbackValue:
              _booleanValue(initialUsesPwaFaviconFallback),
        ),
        _domains = List<TenantAdminDomainEntry>.from(
          initialDomains ??
              [
                _domainEntry(id: 'domain-1', path: 'guarappari.test'),
                _domainEntry(id: 'domain-2', path: 'legacy.guarappari.test'),
              ],
          growable: true,
        ) {
    if (initialMapUiSettings != null) {
      _mapUiSettings = initialMapUiSettings;
    }
    if (initialDiscoveryFiltersSettings != null) {
      _discoveryFiltersSettings = initialDiscoveryFiltersSettings;
    }
  }

  final bool throwOnBrandingFetch;
  final Object? createDomainError;
  final List<TenantAdminDomainEntry> _domains;
  final List<String> createdDomainPaths = <String>[];
  final List<String> deletedDomainIds = <String>[];
  String? updatedFirebaseProjectId;
  TenantAdminResendEmailSettings? updatedResendEmailSettings;
  TenantAdminOutboundIntegrationsSettings? updatedOutboundIntegrationsSettings;
  TenantAdminTelemetryIntegration? lastTelemetryIntegration;
  final List<String> deletedTelemetryTypes = <String>[];
  TenantAdminBrandingUpdateInput? lastBrandingInput;
  TenantAdminMapUiSettings? updatedMapUiSettings;
  TenantAdminDiscoveryFiltersSettingsValue? updatedDiscoveryFiltersSettings;
  TenantAdminAppLinksSettings? updatedAppLinksSettings;
  String? uploadedMapFilterKey;
  TenantAdminMediaUpload? uploadedMapFilterPayload;
  final StreamValue<TenantAdminBrandingSettings?> _brandingSettingsStreamValue =
      StreamValue<TenantAdminBrandingSettings?>(defaultValue: null);
  TenantAdminMapUiSettings _mapUiSettings = TenantAdminMapUiSettings(
    rawMapUiValue: TenantAdminDynamicMapValue({
      'radius': 15000,
      'default_origin': {
        'lat': -20.6736,
        'lng': -40.4976,
        'label': 'Centro',
      },
    }),
    defaultOrigin: TenantAdminMapDefaultOrigin(
      lat: _lat(-20.6736),
      lng: _lng(-40.4976),
      label: _optionalText('Centro'),
    ),
    filters: TenantAdminMapFilterCatalogItems(),
  );
  TenantAdminDiscoveryFiltersSettingsValue _discoveryFiltersSettings =
      TenantAdminDiscoveryFiltersSettingsValue();
  TenantAdminBrandingSettings _brandingSettings;
  TenantAdminAppLinksSettings _appLinksSettings =
      buildTenantAdminAppLinksSettings(
    rawAppLinks: {
      'android': {
        'sha256_cert_fingerprints': [
          '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:AA:23:11:22:33:44:55:66:77:88:99',
        ],
      },
      'ios': {
        'team_id': 'TEAMID1234',
        'paths': ['/invite*', '/convites*'],
      },
    },
    androidAppIdentifier: 'com.guarappari.app',
    androidSha256CertFingerprints: [
      '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:AA:23:11:22:33:44:55:66:77:88:99',
    ],
    iosTeamId: 'TEAMID1234',
    iosBundleId: 'com.guarappari.app',
    iosPaths: ['/invite*', '/convites*'],
  );
  TenantAdminResendEmailSettings _resendEmailSettings =
      TenantAdminResendEmailSettings(
    token: _optionalText('re_fixture_token'),
    from: _optionalText('Belluga <noreply@belluga.space>'),
    toRecipients: _resendRecipients(['admin@belluga.space']),
    ccRecipients: _resendRecipients(['ops@belluga.space']),
    bccRecipients: TenantAdminResendEmailRecipients(),
    replyToRecipients: _resendRecipients(['reply@belluga.space']),
  );
  TenantAdminOutboundIntegrationsSettings _outboundIntegrationsSettings =
      TenantAdminOutboundIntegrationsSettings(
    whatsappWebhookUrlValue:
        _optionalUrl('https://integrations.example/whatsapp'),
    otpWebhookUrlValue: _optionalUrl('https://integrations.example/otp'),
    otpUseWhatsappWebhookValue: _booleanValue(true),
    otpDeliveryChannelValue: _token('whatsapp'),
    otpTtlMinutesValue: _positiveInt(10),
    otpResendCooldownSecondsValue: _positiveInt(60),
    otpMaxAttemptsValue: _positiveInt(5),
  );
  TenantAdminTelemetrySettingsSnapshot _telemetrySnapshot =
      TenantAdminTelemetrySettingsSnapshot(
    integrations: const [],
    availableEventValues: TenantAdminTrimmedStringListValue(['app_opened']),
  );

  @override
  StreamValue<TenantAdminBrandingSettings?> get brandingSettingsStreamValue =>
      _brandingSettingsStreamValue;

  @override
  void clearBrandingSettings() {
    _brandingSettingsStreamValue.addValue(null);
  }

  @override
  Future<TenantAdminMapUiSettings> fetchMapUiSettings() async {
    return _mapUiSettings;
  }

  @override
  Future<TenantAdminDiscoveryFiltersSettingsValue>
      fetchDiscoveryFiltersSettings() async {
    return _discoveryFiltersSettings;
  }

  @override
  Future<TenantAdminDiscoveryFiltersSettingsValue>
      updateDiscoveryFiltersSettings({
    required TenantAdminDiscoveryFiltersSettingsValue settings,
  }) async {
    updatedDiscoveryFiltersSettings = settings;
    _discoveryFiltersSettings = settings;
    return settings;
  }

  @override
  Future<TenantAdminAppLinksSettings> fetchAppLinksSettings() async {
    return _appLinksSettings;
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminDomainEntry>> fetchDomainsPage({
    required TenantAdminCountValue page,
    required TenantAdminCountValue pageSize,
  }) async {
    final safePage = page.value <= 0 ? 1 : page.value;
    final safePageSize = pageSize.value <= 0 ? 1 : pageSize.value;
    final start = (safePage - 1) * safePageSize;
    if (start >= _domains.length) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminDomainEntry>[],
        hasMore: false,
      );
    }
    final end = start + safePageSize > _domains.length
        ? _domains.length
        : start + safePageSize;
    return tenantAdminPagedResultFromRaw(
      items: _domains.sublist(start, end),
      hasMore: end < _domains.length,
    );
  }

  @override
  Future<TenantAdminDomainEntry> createDomain({
    required TenantAdminRequiredTextValue path,
  }) async {
    final normalizedPath = path.value.trim().toLowerCase();
    createdDomainPaths.add(normalizedPath);
    if (createDomainError != null) {
      throw createDomainError!;
    }
    final created = _domainEntry(
      id: 'domain-created-${createdDomainPaths.length}',
      path: normalizedPath,
    );
    _domains.insert(0, created);
    return created;
  }

  @override
  Future<void> deleteDomain(TenantAdminRequiredTextValue domainId) async {
    deletedDomainIds.add(domainId.value);
    _domains.removeWhere((domain) => domain.id == domainId.value);
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> deleteTelemetryIntegration({
    required Object type,
  }) async {
    final resolvedType =
        type is String ? type : (type as dynamic).value as String;
    deletedTelemetryTypes.add(resolvedType);
    _telemetrySnapshot = TenantAdminTelemetrySettingsSnapshot(
      integrations: _telemetrySnapshot.integrations
          .where((integration) => integration.type != resolvedType)
          .toList(growable: false),
      availableEventValues: _telemetrySnapshot.availableEvents,
    );
    return _telemetrySnapshot;
  }

  @override
  Future<TenantAdminFirebaseSettings?> fetchFirebaseSettings() async {
    return TenantAdminFirebaseSettings(
      apiKey: _requiredText('apikey'),
      appId: _requiredText('appid'),
      projectId: _requiredText('project-test'),
      messagingSenderId: _requiredText('sender'),
      storageBucket: _requiredText('bucket'),
    );
  }

  @override
  Future<TenantAdminResendEmailSettings> fetchResendEmailSettings() async {
    return _resendEmailSettings;
  }

  @override
  Future<TenantAdminOutboundIntegrationsSettings>
      fetchOutboundIntegrationsSettings() async {
    return _outboundIntegrationsSettings;
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> fetchTelemetrySettings() async {
    return _telemetrySnapshot;
  }

  @override
  Future<TenantAdminBrandingSettings> fetchBrandingSettings() async {
    if (throwOnBrandingFetch) {
      throw Exception('branding unavailable');
    }
    _brandingSettingsStreamValue.addValue(_brandingSettings);
    return _brandingSettings;
  }

  @override
  Future<TenantAdminMapUiSettings> updateMapUiSettings({
    required TenantAdminMapUiSettings settings,
  }) async {
    updatedMapUiSettings = settings;
    _mapUiSettings = settings;
    return settings;
  }

  @override
  Future<TenantAdminAppLinksSettings> updateAppLinksSettings({
    required TenantAdminAppLinksSettings settings,
  }) async {
    updatedAppLinksSettings = settings;
    _appLinksSettings = settings;
    return settings;
  }

  @override
  Future<String> uploadMapFilterImage({
    required Object key,
    required TenantAdminMediaUpload upload,
  }) async {
    uploadedMapFilterKey =
        key is String ? key : (key as dynamic).value as String;
    uploadedMapFilterPayload = upload;
    return 'https://guarappari.test/api/v1/media/map-filters/$uploadedMapFilterKey?v=1';
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> upsertTelemetryIntegration({
    required TenantAdminTelemetryIntegration integration,
  }) async {
    lastTelemetryIntegration = integration;
    _telemetrySnapshot = TenantAdminTelemetrySettingsSnapshot(
      integrations: [integration],
      availableEventValues: TenantAdminTrimmedStringListValue(['app_opened']),
    );
    return _telemetrySnapshot;
  }

  @override
  Future<TenantAdminFirebaseSettings> updateFirebaseSettings({
    required TenantAdminFirebaseSettings settings,
  }) async {
    updatedFirebaseProjectId = settings.projectId;
    return settings;
  }

  @override
  Future<TenantAdminResendEmailSettings> updateResendEmailSettings({
    required TenantAdminResendEmailSettings settings,
  }) async {
    updatedResendEmailSettings = settings;
    _resendEmailSettings = settings;
    return settings;
  }

  @override
  Future<TenantAdminOutboundIntegrationsSettings>
      updateOutboundIntegrationsSettings({
    required TenantAdminOutboundIntegrationsSettings settings,
  }) async {
    updatedOutboundIntegrationsSettings = settings;
    _outboundIntegrationsSettings = settings;
    return settings;
  }

  @override
  Future<TenantAdminPushSettings> updatePushSettings({
    required TenantAdminPushSettings settings,
  }) async {
    return settings;
  }

  @override
  Future<TenantAdminBrandingSettings> updateBranding({
    required TenantAdminBrandingUpdateInput input,
  }) async {
    lastBrandingInput = input;
    _brandingSettings = TenantAdminBrandingSettings(
      tenantName: _requiredText(input.tenantName),
      brightnessDefault: input.brightnessDefault,
      primarySeedColor: _hexColor(input.primarySeedColor),
      secondarySeedColor: _hexColor(input.secondarySeedColor),
      publicWebDefaultTitle: _optionalText(input.publicWebDefaultTitle ?? ''),
      publicWebDefaultDescription:
          _optionalText(input.publicWebDefaultDescription ?? ''),
      publicWebDefaultImageUrl: _optionalUrl(
        input.publicWebDefaultImageUpload == null
            ? 'https://guarappari.test/storage/public-web.jpg'
            : 'https://guarappari.test/storage/public-web-updated.jpg',
      ),
      lightLogoUrl:
          _optionalUrl('https://guarappari.test/storage/light-logo.png'),
      darkLogoUrl:
          _optionalUrl('https://guarappari.test/storage/dark-logo.png'),
      lightIconUrl:
          _optionalUrl('https://guarappari.test/storage/light-icon.png'),
      darkIconUrl:
          _optionalUrl('https://guarappari.test/storage/dark-icon.png'),
      faviconUrl: _optionalUrl('https://guarappari.test/favicon.ico'),
      pwaIconUrl: _optionalUrl('https://guarappari.test/storage/pwa-icon.png'),
      hasDedicatedFaviconValue: _booleanValue(input.faviconUpload != null),
      usesPwaFaviconFallbackValue: _booleanValue(input.faviconUpload == null),
    );
    _brandingSettingsStreamValue.addValue(_brandingSettings);
    return _brandingSettings;
  }
}

class _SlowDiscoveryFiltersSettingsRepository
    extends _FakeTenantAdminSettingsRepository {
  _SlowDiscoveryFiltersSettingsRepository({
    required this.fetchCompleter,
  });

  final Completer<TenantAdminDiscoveryFiltersSettingsValue> fetchCompleter;
  int fetchCount = 0;

  @override
  Future<TenantAdminDiscoveryFiltersSettingsValue>
      fetchDiscoveryFiltersSettings() {
    fetchCount += 1;
    return fetchCompleter.future;
  }
}

class _EmptyDiscoveryFilterRuleCatalogRepository
    implements TenantAdminDiscoveryFilterRuleCatalogRepositoryContract {
  @override
  Future<TenantAdminMapFilterRuleCatalog> fetchRuleCatalog() async {
    return const TenantAdminMapFilterRuleCatalog.empty();
  }
}

class _FakeTenantAdminExternalImageProxy
    implements TenantAdminExternalImageProxyContract {
  @override
  Future<Uint8List> fetchExternalImageBytes({
    required Object imageUrl,
  }) async {
    return Uint8List(0);
  }
}

class _FakeTenantScope implements TenantAdminTenantScopeContract {
  _FakeTenantScope(String initialDomain) {
    _selectedTenantDomainStreamValue.addValue(initialDomain);
  }

  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl => 'https://example.test/admin/api';

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomainStreamValue.addValue((tenantDomain is String
            ? tenantDomain
            : (tenantDomain as dynamic).value as String)
        .trim());
  }
}

AppData _buildAppData({
  String mainDomain = 'https://guarappari.test',
}) {
  const remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'profile_types': [],
    'domains': ['https://guarappari.test', 'https://belluga.app'],
    'app_domains': ['com.guarappari.app'],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#009688',
      'secondary_seed_color': '#673AB7',
    },
    'main_color': '#009688',
    'tenant_id': 'tenant-1',
    'telemetry': {
      'trackers': [],
    },
    'telemetry_context': {'location_freshness_minutes': 5},
    'firebase': {
      'apiKey': 'apikey',
      'appId': 'appid',
      'projectId': 'project-test',
      'messagingSenderId': 'sender',
      'storageBucket': 'bucket',
    },
    'push': {
      'enabled': true,
      'types': ['event'],
      'throttles': {'max_per_hour': 20},
    },
  };

  final fullRemoteData = {
    ...remoteData,
    'main_domain': mainDomain,
  };

  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'guarappari.test',
    'href': 'https://guarappari.test',
    'port': null,
    'device': 'test-device',
  };

  return buildAppDataFromInitialization(
    remoteData: fullRemoteData,
    localInfo: localInfo,
  );
}
