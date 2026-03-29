import 'dart:io';
import 'dart:typed_data';
import 'package:belluga_now/testing/tenant_admin_app_links_settings_builder.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/models/tenant_admin_settings_integration_section.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_environment_snapshot_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_local_preferences_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_technical_integrations_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_visual_identity_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_map_filter_rule_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_map_filter_visual_sheet.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_icon_catalog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_map_marker_icon_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<TenantAdminLocationSelectionContract>(
      TenantAdminLocationSelectionService(),
    );
  });

  tearDown(() async {
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
      find.byKey(TenantAdminSettingsKeys.hubActionPreferences),
      findsNothing,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.hubActionVisualIdentity),
      findsNothing,
    );
    expect(
      find.text('Toque para editar preferências e filtros do mapa'),
      findsOneWidget,
    );
    expect(find.text('Toque para editar identidade visual'), findsOneWidget);

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
      find.byKey(TenantAdminSettingsKeys.hubIntegrationAppLinks),
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

  testWidgets('adds map filter item and persists catalog on map_ui save',
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

    await tester.scrollUntilVisible(
      find.byKey(TenantAdminSettingsKeys.localPreferencesAddMapFilterButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(TenantAdminSettingsKeys.localPreferencesAddMapFilterButton),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(TenantAdminSettingsKeys.localPreferencesMapFiltersCard),
      findsOneWidget,
    );
    expect(
      find.byKey(TenantAdminSettingsKeys.localPreferencesMapFilterRow(0)),
      findsOneWidget,
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
    final filters = settingsRepository.updatedMapUiSettings!.filters;
    expect(filters, hasLength(1));
    expect(filters.first.key, 'filter_1');
    expect(filters.first.label, 'Filtro 1');
  });

  testWidgets(
      'map filter row exposes explicit Visual action and removes legacy image actions',
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

    await tester.scrollUntilVisible(
      find.byKey(TenantAdminSettingsKeys.localPreferencesAddMapFilterButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(TenantAdminSettingsKeys.localPreferencesAddMapFilterButton),
    );
    await tester.pumpAndSettle();

    final rowFinder = find.byKey(
      TenantAdminSettingsKeys.localPreferencesMapFilterRow(0),
    );
    expect(rowFinder, findsOneWidget);

    expect(
      find.descendant(
        of: rowFinder,
        matching: find.widgetWithText(OutlinedButton, 'Regra'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: rowFinder,
        matching: find.widgetWithText(OutlinedButton, 'Visual'),
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

    final popupFinder = find.descendant(
      of: rowFinder,
      matching: find.byType(PopupMenuButton<String>),
    );
    expect(popupFinder, findsOneWidget);
    await tester.tap(popupFinder);
    await tester.pumpAndSettle();

    expect(find.text('Editar regra'), findsOneWidget);
    expect(find.text('Editar visual'), findsOneWidget);
    expect(find.text('Imagem'), findsNothing);
    expect(find.text('Limpar imagem'), findsNothing);
  });

  testWidgets(
    'map filter row preview prefers marker override icon+color over legacy image',
    (tester) async {
      final repository = _FakeAppDataRepository(_buildAppData());
      final settingsRepository = _FakeTenantAdminSettingsRepository(
        initialMapUiSettings: TenantAdminMapUiSettings(
          rawMapUiValue: TenantAdminDynamicMapValue(const {
            'radius': 15000,
            'default_origin': {
              'lat': -20.6736,
              'lng': -40.4976,
              'label': 'Centro',
            },
          }),
          defaultOrigin: TenantAdminMapDefaultOrigin(
            lat: -20.6736,
            lng: -40.4976,
            label: 'Centro',
          ),
          filters: [
            TenantAdminMapFilterCatalogItem(
              key: 'events',
              label: 'Eventos',
              imageUri: 'https://tenant.test/legacy-events.png',
              overrideMarker: true,
              markerOverride: TenantAdminMapFilterMarkerOverride.icon(
                icon: 'music',
                color: '#C6141F',
                iconColor: '#FFFFFF',
              ),
            ),
          ],
        ),
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
        const Scaffold(body: TenantAdminSettingsLocalPreferencesScreen()),
      );

      final rowFinder = find.byKey(
        TenantAdminSettingsKeys.localPreferencesMapFilterRow(0),
      );
      expect(rowFinder, findsOneWidget);

      final iconFinder = find.descendant(
        of: rowFinder,
        matching: find.byIcon(Icons.music_note),
      );
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder.first);
      expect(iconWidget.color, Colors.white);

      final previewFinder = find.byKey(
        TenantAdminSettingsKeys.localPreferencesMapFilterVisualPreview(0),
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

  testWidgets('map filter rule sheet is query-only (without visual fields)',
      (tester) async {
    final filter = TenantAdminMapFilterCatalogItem(
      key: 'events',
      label: 'Eventos',
      query:
          TenantAdminMapFilterQuery(source: TenantAdminMapFilterSource.event),
    );
    final catalog = TenantAdminMapFilterRuleCatalog(
      typesBySource: {
        TenantAdminMapFilterSource.event: [
          TenantAdminMapFilterTypeOption(
            slug: 'show',
            label: 'Show',
          ),
        ],
      },
      taxonomyTermsBySource: {
        TenantAdminMapFilterSource.event: [
          TenantAdminMapFilterTaxonomyTermOption(
            token: 'rock',
            label: 'Rock',
            taxonomySlug: 'genre',
            taxonomyLabel: 'Gênero',
          ),
        ],
      },
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

    await tester.scrollUntilVisible(
      find.byKey(TenantAdminSettingsKeys.localPreferencesAddMapFilterButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(TenantAdminSettingsKeys.localPreferencesAddMapFilterButton),
    );
    await tester.pumpAndSettle();

    final rowFinder = find.byKey(
      TenantAdminSettingsKeys.localPreferencesMapFilterRow(0),
    );
    expect(rowFinder, findsOneWidget);

    await tester.tap(
      find.descendant(
        of: rowFinder,
        matching: find.widgetWithText(OutlinedButton, 'Visual'),
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
      find.byKey(TenantAdminSettingsKeys.localPreferencesSaveOriginButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(TenantAdminSettingsKeys.localPreferencesSaveOriginButton),
    );
    await tester.pumpAndSettle();

    final updated = settingsRepository.updatedMapUiSettings;
    expect(updated, isNotNull);
    expect(updated!.filters, hasLength(1));
    final filter = updated.filters.first;
    expect(filter.overrideMarker, isTrue);
    expect(filter.markerOverride, isNotNull);
    expect(filter.markerOverride!.mode,
        TenantAdminMapFilterMarkerOverrideMode.image);
    expect(
      filter.markerOverride!.imageUri,
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

    await tester.scrollUntilVisible(
      find.byKey(TenantAdminSettingsKeys.localPreferencesAddMapFilterButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(TenantAdminSettingsKeys.localPreferencesAddMapFilterButton),
    );
    await tester.pumpAndSettle();

    final rowFinder = find.byKey(
      TenantAdminSettingsKeys.localPreferencesMapFilterRow(0),
    );
    expect(rowFinder, findsOneWidget);

    await tester.tap(
      find.descendant(
        of: rowFinder,
        matching: find.widgetWithText(OutlinedButton, 'Visual'),
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
      key: 'events',
      label: 'Eventos',
      imageUri: 'https://tenant.test/filter.png',
      overrideMarker: true,
      markerOverride: TenantAdminMapFilterMarkerOverride.image(
        imageUri: 'https://tenant.test/filter.png',
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
    expect(
      find.byKey(
        TenantAdminSettingsKeys.technicalIntegrationsScopedAppBar,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        TenantAdminSettingsKeys.technicalIntegrationsBackButton,
        skipOffstage: false,
      ),
      findsOneWidget,
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
    await tester.tap(find.widgetWithText(CheckboxListTile, '/home'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
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

    await tester.tap(
      find.byKey(TenantAdminSettingsKeys.brandingPrimaryPickerButton),
    );
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

    await tester.tap(
      find.byKey(TenantAdminSettingsKeys.brandingPrimaryPickerButton),
    );
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
      pwaIconUpload: null,
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
      pwaIconUpload: null,
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
      pwaIconUpload: null,
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
      TenantAdminLocation(
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
        name: 'settings-test',
        path: '/',
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

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData);

  final AppData _appData;
  int initCallCount = 0;

  @override
  AppData get appData => _appData;

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;
  final StreamValue<double> _maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: 1000);

  @override
  double get maxRadiusMeters => maxRadiusMetersStreamValue.value;

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
  }

  @override
  Future<void> setMaxRadiusMeters(double meters) async {
    _maxRadiusMetersStreamValue.addValue(meters);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeModeStreamValue.addValue(mode);
  }
}

class _FakeTenantAdminSettingsRepository
    implements TenantAdminSettingsRepositoryContract {
  _FakeTenantAdminSettingsRepository({
    this.throwOnBrandingFetch = false,
    String? initialPwaIconUrl = 'https://guarappari.test/storage/pwa-icon.png',
    TenantAdminMapUiSettings? initialMapUiSettings,
  }) : _brandingSettings = TenantAdminBrandingSettings(
          tenantName: 'Tenant Test',
          brightnessDefault: TenantAdminBrandingBrightness.light,
          primarySeedColor: '#009688',
          secondarySeedColor: '#673AB7',
          lightLogoUrl: 'https://guarappari.test/storage/light-logo.png',
          darkLogoUrl: 'https://guarappari.test/storage/dark-logo.png',
          lightIconUrl: 'https://guarappari.test/storage/light-icon.png',
          darkIconUrl: 'https://guarappari.test/storage/dark-icon.png',
          pwaIconUrl: initialPwaIconUrl,
        ) {
    if (initialMapUiSettings != null) {
      _mapUiSettings = initialMapUiSettings;
    }
  }

  final bool throwOnBrandingFetch;
  String? updatedFirebaseProjectId;
  TenantAdminBrandingUpdateInput? lastBrandingInput;
  TenantAdminMapUiSettings? updatedMapUiSettings;
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
      lat: -20.6736,
      lng: -40.4976,
      label: 'Centro',
    ),
    filters: [],
  );
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
  Future<TenantAdminAppLinksSettings> fetchAppLinksSettings() async {
    return _appLinksSettings;
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> deleteTelemetryIntegration({
    required String type,
  }) async {
    return TenantAdminTelemetrySettingsSnapshot(
      integrations: [],
      availableEventValues: TenantAdminTrimmedStringListValue(['app_opened']),
    );
  }

  @override
  Future<TenantAdminFirebaseSettings?> fetchFirebaseSettings() async {
    return TenantAdminFirebaseSettings(
      apiKey: 'apikey',
      appId: 'appid',
      projectId: 'project-test',
      messagingSenderId: 'sender',
      storageBucket: 'bucket',
    );
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> fetchTelemetrySettings() async {
    return TenantAdminTelemetrySettingsSnapshot(
      integrations: [],
      availableEventValues: TenantAdminTrimmedStringListValue(['app_opened']),
    );
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
    required String key,
    required TenantAdminMediaUpload upload,
  }) async {
    uploadedMapFilterKey = key;
    uploadedMapFilterPayload = upload;
    return 'https://guarappari.test/api/v1/media/map-filters/$key?v=1';
  }

  @override
  Future<TenantAdminTelemetrySettingsSnapshot> upsertTelemetryIntegration({
    required TenantAdminTelemetryIntegration integration,
  }) async {
    return TenantAdminTelemetrySettingsSnapshot(
      integrations: [integration],
      availableEventValues: TenantAdminTrimmedStringListValue(['app_opened']),
    );
  }

  @override
  Future<TenantAdminFirebaseSettings> updateFirebaseSettings({
    required TenantAdminFirebaseSettings settings,
  }) async {
    updatedFirebaseProjectId = settings.projectId;
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
      tenantName: input.tenantName,
      brightnessDefault: input.brightnessDefault,
      primarySeedColor: input.primarySeedColor,
      secondarySeedColor: input.secondarySeedColor,
      lightLogoUrl: 'https://guarappari.test/storage/light-logo.png',
      darkLogoUrl: 'https://guarappari.test/storage/dark-logo.png',
      lightIconUrl: 'https://guarappari.test/storage/light-icon.png',
      darkIconUrl: 'https://guarappari.test/storage/dark-icon.png',
      pwaIconUrl: 'https://guarappari.test/storage/pwa-icon.png',
    );
    _brandingSettingsStreamValue.addValue(_brandingSettings);
    return _brandingSettings;
  }
}

class _FakeTenantAdminExternalImageProxy
    implements TenantAdminExternalImageProxyContract {
  @override
  Future<Uint8List> fetchExternalImageBytes({
    required String imageUrl,
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
  void selectTenantDomain(String tenantDomain) {
    _selectedTenantDomainStreamValue.addValue(tenantDomain.trim());
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
