import 'dart:async';

import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/screens/tenant_admin_profile_type_detail_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/screens/tenant_admin_profile_type_form_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/screens/tenant_admin_profile_types_list_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_map_marker_icon_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../support/auto_route_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('drops duplicate pending saves and releases submission guard', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    final pending = Completer<void>();
    controller.pendingSubmission = pending;
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: const [],
        capabilityRevision: 7,
        visual: TenantAdminPoiVisual.icon(
          iconValue: TenantAdminRequiredTextValue()..parse('place'),
          colorValue: TenantAdminHexColorValue()..parse('#FF8800'),
        ),
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw({}),
      ),
    );

    final save = find.text('Salvar alteracoes');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save);
    await tester.pump();
    expect(controller.submitUpdateCalls, 1);
    expect(controller.lastExpectedCapabilityRevision, 7);
    expect(controller.formSavingStreamValue.value, isTrue);
    expect(controller.tryBeginFormSubmission(), isFalse);

    pending.complete();
    await tester.pumpAndSettle();
    expect(controller.formSavingStreamValue.value, isFalse);
    expect(controller.submitUpdateCalls, 1);
    expect(controller.tryBeginFormSubmission(), isTrue);
    controller.finishFormSubmission();
  });

  testWidgets(
    'asks destructive confirmation when disabling POI and respects cancel/confirm',
    (tester) async {
      final controller = _TestProfileTypesController(67);
      await _pumpFormScreen(
        tester,
        controller: controller,
        definition: tenantAdminProfileTypeDefinitionFromRaw(
          type: 'venue',
          label: 'Venue',
          allowedTaxonomies: const [],
          capabilityDefinitions: [
            tenantAdminProfileTypeCapabilityDefinitionFromRaw(
              key: 'is_map_poi_enabled',
              domain: 'location',
              valueType: 'boolean',
              defaultValue: false,
              failClosedValue: false,
              allowedValues: const [],
              parameters: const [],
              resources: const [],
            ),
          ],
          visual: TenantAdminPoiVisual.icon(
            iconValue: TenantAdminRequiredTextValue()..parse('place'),
            colorValue: TenantAdminHexColorValue()..parse('#FF8800'),
          ),
          capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(<
            String,
            TenantAdminProfileTypeCapabilityValue
          >{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'required',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: true,
                ),
            'is_reference_location_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: true,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
          }),
        ),
      );

      final poiToggle = find.byKey(
        const ValueKey<String>('profileTypeCapability_is_map_poi_enabled'),
      );
      await tester.ensureVisible(poiToggle);
      await tester.tap(poiToggle);
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Salvar alteracoes'),
        200,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Salvar alteracoes'));
      await tester.pumpAndSettle();

      expect(
        find.text('Alerta: vamos deletar 67 projeções de Venue.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(controller.submitUpdateCalls, 0);

      await tester.scrollUntilVisible(
        find.text('Salvar alteracoes'),
        200,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Salvar alteracoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(controller.submitUpdateCalls, 1);
      expect(controller.lastCapabilities?.configuredIsMapPoiEnabled, isFalse);
      expect(
        controller.lastCapabilities
            ?.valueFor(_text('is_reference_location_enabled'))
            ?.booleanValue,
        isTrue,
      );
      expect(controller.lastVisual, isNotNull);
      expect(controller.lastVisual?.mode, TenantAdminPoiVisualMode.icon);
    },
  );

  testWidgets('keeps dormant reference location configuration editable', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'hotel',
        label: 'Hotel',
        allowedTaxonomies: const [],
        capabilityDefinitions: [
          tenantAdminProfileTypeCapabilityDefinitionFromRaw(
            key: 'is_reference_location_enabled',
            domain: 'location',
            valueType: 'boolean',
            defaultValue: false,
            failClosedValue: false,
            allowedValues: const [],
            parameters: const [],
            resources: const [],
          ),
        ],
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
          <String, TenantAdminProfileTypeCapabilityValue>{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'is_reference_location_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
          },
        ),
      ),
    );

    final referenceToggle = tester.widget<SwitchListTile>(
      find.byKey(
        const ValueKey<String>(
          'profileTypeCapability_is_reference_location_enabled',
        ),
      ),
    );

    expect(referenceToggle.value, isFalse);
    expect(referenceToggle.onChanged, isNotNull);
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'profileTypeCapability_is_reference_location_enabled',
        ),
      ),
    );
    await tester.pump();
    expect(
      controller.currentCapabilities
          .valueFor(_text('is_reference_location_enabled'))
          ?.booleanValue,
      isTrue,
    );
    expect(find.text('Requer POI habilitado.'), findsNothing);
  });

  testWidgets('keeps favoritable independent from public discovery changes', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: const [],
        capabilityDefinitions: [
          tenantAdminProfileTypeCapabilityDefinitionFromRaw(
            key: 'is_publicly_discoverable',
            domain: 'visibility',
            valueType: 'boolean',
            defaultValue: true,
            failClosedValue: false,
            allowedValues: const [],
            parameters: const [],
            resources: const [],
          ),
          tenantAdminProfileTypeCapabilityDefinitionFromRaw(
            key: 'is_favoritable',
            domain: 'relationships',
            valueType: 'boolean',
            defaultValue: false,
            failClosedValue: false,
            allowedValues: const [],
            parameters: const [],
            resources: const [],
          ),
        ],
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
          <String, TenantAdminProfileTypeCapabilityValue>{
            'is_publicly_discoverable':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
          },
        ),
      ),
    );

    final favoritableFinder = find.byKey(
      const ValueKey<String>('profileTypeCapability_is_favoritable'),
    );
    final publicFinder = find.byKey(
      const ValueKey<String>('profileTypeCapability_is_publicly_discoverable'),
    );

    await tester.ensureVisible(favoritableFinder);
    var favoritableToggle = tester.widget<SwitchListTile>(favoritableFinder);
    expect(favoritableToggle.value, isTrue);
    expect(favoritableToggle.onChanged, isNotNull);
    expect(find.text('Requer descoberta publica habilitada.'), findsNothing);

    await tester.ensureVisible(publicFinder);
    await tester.tap(publicFinder);
    await tester.pumpAndSettle();

    favoritableToggle = tester.widget<SwitchListTile>(favoritableFinder);
    expect(favoritableToggle.value, isTrue);
    expect(favoritableToggle.onChanged, isNotNull);

    await tester.tap(publicFinder);
    await tester.pumpAndSettle();

    favoritableToggle = tester.widget<SwitchListTile>(favoritableFinder);
    expect(favoritableToggle.value, isTrue);
    expect(favoritableToggle.onChanged, isNotNull);

    await tester.tap(favoritableFinder);
    await tester.pumpAndSettle();

    expect(
      controller.currentCapabilities.isEnabled(
        _text('is_publicly_discoverable'),
      ),
      isFalse,
    );
    expect(
      controller.currentCapabilities.isEnabled(_text('is_favoritable')),
      isFalse,
    );
  });

  testWidgets(
    'keeps public discovery toggle editable when queryability is off',
    (tester) async {
      final controller = _TestProfileTypesController(0);
      await _pumpFormScreen(
        tester,
        controller: controller,
        definition: tenantAdminProfileTypeDefinitionFromRaw(
          type: 'artist',
          label: 'Artist',
          allowedTaxonomies: const [],
          capabilityDefinitions: [
            tenantAdminProfileTypeCapabilityDefinitionFromRaw(
              key: 'is_publicly_discoverable',
              domain: 'visibility',
              valueType: 'boolean',
              defaultValue: true,
              failClosedValue: false,
              allowedValues: const [],
              parameters: const [],
              resources: const [],
            ),
          ],
          capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(<
            String,
            TenantAdminProfileTypeCapabilityValue
          >{
            'is_queryable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_publicly_navigable':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: true,
                ),
            'is_publicly_discoverable':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: true,
                ),
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
          }),
        ),
      );

      final discoverableFinder = find.byKey(
        const ValueKey<String>(
          'profileTypeCapability_is_publicly_discoverable',
        ),
      );
      final discoverableToggle = tester.widget<SwitchListTile>(
        discoverableFinder,
      );

      expect(discoverableToggle.value, isTrue);
      expect(discoverableToggle.onChanged, isNotNull);
      expect(
        find.text('Requer capacidade de consulta habilitada.'),
        findsNothing,
      );

      await tester.tap(discoverableFinder);
      await tester.pumpAndSettle();

      expect(
        controller.currentCapabilities.isEnabled(_text('is_queryable')),
        isFalse,
      );
      expect(
        controller.currentCapabilities.isEnabled(
          _text('is_publicly_discoverable'),
        ),
        isFalse,
      );
    },
  );

  testWidgets('toggles inviteable capability in profile type form', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: const [],
        capabilityDefinitions: [
          tenantAdminProfileTypeCapabilityDefinitionFromRaw(
            key: 'is_inviteable',
            domain: 'relationships',
            valueType: 'boolean',
            defaultValue: false,
            failClosedValue: false,
            allowedValues: const [],
            parameters: const [],
            resources: const [],
          ),
        ],
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
          <String, TenantAdminProfileTypeCapabilityValue>{
            'is_inviteable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_nested_profile_groups':
                tenantAdminProfileTypeCapabilityValueFromRaw(value: false),
          },
        ),
      ),
    );

    final toggle = find.byKey(
      const ValueKey<String>('profileTypeCapability_is_inviteable'),
    );
    await tester.ensureVisible(toggle);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(
      controller.currentCapabilities.isEnabled(_text('is_inviteable')),
      isTrue,
    );
  });

  testWidgets('renders shared marker icon picker in POI visual editor', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: const [],
        visual: TenantAdminPoiVisual.icon(
          iconValue: TenantAdminRequiredTextValue()..parse('place'),
          colorValue: TenantAdminHexColorValue()..parse('#FF8800'),
        ),
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
          <String, TenantAdminProfileTypeCapabilityValue>{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'required',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: true,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
          },
        ),
      ),
    );

    expect(find.text('Visual do tipo'), findsOneWidget);
    expect(find.byType(TenantAdminMapMarkerIconPickerField), findsOneWidget);
  });

  testWidgets('toggles nested account tab capability in profile type form', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: const [],
        capabilityDefinitions: [
          tenantAdminProfileTypeCapabilityDefinitionFromRaw(
            key: 'has_nested_profile_groups',
            domain: 'relationships',
            valueType: 'boolean',
            defaultValue: false,
            failClosedValue: false,
            allowedValues: const [],
            parameters: const [],
            resources: const [],
          ),
        ],
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
          <String, TenantAdminProfileTypeCapabilityValue>{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_nested_profile_groups':
                tenantAdminProfileTypeCapabilityValueFromRaw(value: false),
          },
        ),
      ),
    );

    final toggle = find.byKey(
      const ValueKey<String>('profileTypeCapability_has_nested_profile_groups'),
    );
    await tester.ensureVisible(toggle);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(
      controller.currentCapabilities.isEnabled(
        _text('has_nested_profile_groups'),
      ),
      isTrue,
    );
  });

  testWidgets('toggles contact channel capability in profile type form', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: const [],
        capabilityDefinitions: [
          tenantAdminProfileTypeCapabilityDefinitionFromRaw(
            key: 'has_contact_channels',
            domain: 'profile_content',
            valueType: 'boolean',
            defaultValue: false,
            failClosedValue: false,
            allowedValues: const [],
            parameters: const [],
            resources: const [],
          ),
        ],
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(<
          String,
          TenantAdminProfileTypeCapabilityValue
        >{
          'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: 'disabled',
          ),
          'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: false,
          ),
          'is_physical_host_enabled':
              tenantAdminProfileTypeCapabilityValueFromRaw(
                value: false,
              ),
          'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'has_contact_channels': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: false,
          ),
        }),
      ),
    );

    final toggle = find.byKey(
      const ValueKey<String>('profileTypeCapability_has_contact_channels'),
    );
    await tester.ensureVisible(toggle);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(
      controller.currentCapabilities.isEnabled(_text('has_contact_channels')),
      isTrue,
    );
  });

  testWidgets('gallery capability toggle updates controller state', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: const [],
        capabilityDefinitions: [
          tenantAdminProfileTypeCapabilityDefinitionFromRaw(
            key: 'has_gallery',
            domain: 'profile_content',
            valueType: 'boolean',
            defaultValue: false,
            failClosedValue: false,
            allowedValues: const [],
            parameters: const [],
            resources: const [],
          ),
        ],
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
          <String, TenantAdminProfileTypeCapabilityValue>{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_gallery': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
          },
        ),
      ),
    );

    final toggle = find.byKey(
      const ValueKey<String>('profileTypeCapability_has_gallery'),
    );
    await tester.ensureVisible(toggle);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(
      controller.currentCapabilities.isEnabled(_text('has_gallery')),
      isTrue,
    );
  });

  testWidgets(
    'hydrates gallery capability as enabled when type already has it',
    (tester) async {
      final controller = _TestProfileTypesController(0);
      await _pumpFormScreen(
        tester,
        controller: controller,
        definition: tenantAdminProfileTypeDefinitionFromRaw(
          type: 'venue',
          label: 'Venue',
          allowedTaxonomies: const [],
          capabilityDefinitions: [
            tenantAdminProfileTypeCapabilityDefinitionFromRaw(
              key: 'has_gallery',
              domain: 'profile_content',
              valueType: 'boolean',
              defaultValue: false,
              failClosedValue: false,
              allowedValues: const [],
              parameters: const [],
              resources: const [],
            ),
          ],
          capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(<
            String,
            TenantAdminProfileTypeCapabilityValue
          >{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_gallery': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
          }),
        ),
      );

      final toggle = find.byKey(
        const ValueKey<String>('profileTypeCapability_has_gallery'),
      );
      await tester.ensureVisible(toggle);

      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(
        controller.currentCapabilities.isEnabled(_text('has_gallery')),
        isTrue,
      );
    },
  );

  testWidgets('shows gallery capability label in profile type list cards', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(
      0,
      initialProfileTypes: [
        tenantAdminProfileTypeDefinitionFromRaw(
          type: 'venue',
          label: 'Venue',
          allowedTaxonomies: const [],
          capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(<
            String,
            TenantAdminProfileTypeCapabilityValue
          >{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_gallery': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
          }),
        ),
      ],
    );

    await _pumpListScreen(tester, controller: controller);

    expect(find.text('Venue'), findsOneWidget);
    expect(find.textContaining('Has gallery'), findsOneWidget);
  });

  testWidgets('shows contact capability label in profile type list cards', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(
      0,
      initialProfileTypes: [
        tenantAdminProfileTypeDefinitionFromRaw(
          type: 'artist',
          label: 'Artist',
          allowedTaxonomies: const [],
          capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(<
            String,
            TenantAdminProfileTypeCapabilityValue
          >{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_contact_channels':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: true,
                ),
          }),
        ),
      ],
    );

    await _pumpListScreen(tester, controller: controller);

    expect(find.text('Artist'), findsOneWidget);
    expect(find.textContaining('Has contact channels'), findsOneWidget);
  });

  testWidgets('shows gallery capability chip in profile type detail', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    final definition = tenantAdminProfileTypeDefinitionFromRaw(
      type: 'venue',
      label: 'Venue',
      allowedTaxonomies: const [],
      capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
        <String, TenantAdminProfileTypeCapabilityValue>{
          'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: 'disabled',
          ),
          'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: false,
          ),
          'is_physical_host_enabled':
              tenantAdminProfileTypeCapabilityValueFromRaw(
                value: false,
              ),
          'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: false,
          ),
          'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: false,
          ),
          'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: false,
          ),
          'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: false,
          ),
          'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: false,
          ),
          'has_gallery': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
        },
      ),
    );

    await _pumpDetailScreen(
      tester,
      controller: controller,
      definition: definition,
    );

    expect(find.widgetWithText(Chip, 'Has gallery'), findsOneWidget);
  });

  testWidgets('shows contact capability chip in profile type detail', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    final definition = tenantAdminProfileTypeDefinitionFromRaw(
      type: 'artist',
      label: 'Artist',
      allowedTaxonomies: const [],
      capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
        <String, TenantAdminProfileTypeCapabilityValue>{
          'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: 'disabled',
          ),
          'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: false,
          ),
          'is_physical_host_enabled':
              tenantAdminProfileTypeCapabilityValueFromRaw(
                value: false,
              ),
          'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
          'has_contact_channels': tenantAdminProfileTypeCapabilityValueFromRaw(
            value: true,
          ),
        },
      ),
    );

    await _pumpDetailScreen(
      tester,
      controller: controller,
      definition: definition,
    );

    expect(find.widgetWithText(Chip, 'Has contact channels'), findsOneWidget);
  });

  testWidgets('favoritable capability is editable without public discovery', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'private-partner',
        label: 'Private Partner',
        allowedTaxonomies: const [],
        capabilityDefinitions: [
          tenantAdminProfileTypeCapabilityDefinitionFromRaw(
            key: 'is_favoritable',
            domain: 'relationships',
            valueType: 'boolean',
            defaultValue: false,
            failClosedValue: false,
            allowedValues: const [],
            parameters: const [],
            resources: const [],
          ),
        ],
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
          <String, TenantAdminProfileTypeCapabilityValue>{
            'is_publicly_discoverable':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
          },
        ),
      ),
    );

    final toggle = find.byKey(
      const ValueKey<String>('profileTypeCapability_is_favoritable'),
    );
    await tester.ensureVisible(toggle);
    expect(tester.widget<SwitchListTile>(toggle).onChanged, isNotNull);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(
      controller.currentCapabilities.isEnabled(
        _text('is_publicly_discoverable'),
      ),
      isFalse,
    );
    expect(
      controller.currentCapabilities.isEnabled(_text('is_favoritable')),
      isTrue,
    );
  });

  testWidgets('renders and hydrates plural label field', (tester) async {
    final controller = _TestProfileTypesController(0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'artist',
        label: 'Artist',
        pluralLabel: 'Artists',
        allowedTaxonomies: const [],
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
          <String, TenantAdminProfileTypeCapabilityValue>{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
          },
        ),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Label plural'), findsOneWidget);
    expect(find.text('Artists'), findsWidgets);
  });

  testWidgets(
    'shows canonical type image upload controls for type_asset visuals',
    (tester) async {
      final controller = _TestProfileTypesController(0);
      await _pumpFormScreen(
        tester,
        controller: controller,
        definition: tenantAdminProfileTypeDefinitionFromRaw(
          type: 'restaurant',
          label: 'Restaurant',
          allowedTaxonomies: const [],
          visual: TenantAdminPoiVisual.image(
            imageSource: TenantAdminPoiVisualImageSource.typeAsset,
            colorValue: TenantAdminHexColorValue()..parse('#00897B'),
            imageUrlValue: TenantAdminOptionalUrlValue()
              ..parse(
                'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
              ),
          ),
          capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(<
            String,
            TenantAdminProfileTypeCapabilityValue
          >{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'required',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: true,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
          }),
        ),
      );

      expect(find.text('Imagem canônica do tipo'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Cor do marcador'),
        findsOneWidget,
      );
      expect(find.byType(TenantAdminImageUploadField), findsOneWidget);
      expect(find.text('Enviar imagem canônica'), findsOneWidget);
    },
  );

  testWidgets('type_asset upload uses canonical image source sheet', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'restaurant',
        label: 'Restaurant',
        allowedTaxonomies: const [],
        visual: TenantAdminPoiVisual.image(
          imageSource: TenantAdminPoiVisualImageSource.typeAsset,
        ),
        capabilities: tenantAdminProfileTypeCapabilitiesFromRaw(
          <String, TenantAdminProfileTypeCapabilityValue>{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'required',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: true,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: true,
            ),
          },
        ),
      ),
    );

    expect(find.text('Enviar imagem canônica'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Enviar imagem canônica'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar imagem canônica'));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar imagem canônica do tipo'), findsOneWidget);
    expect(find.text('Do dispositivo'), findsOneWidget);
    expect(find.text('Da web'), findsOneWidget);
  });
}

Future<void> _pumpFormScreen(
  WidgetTester tester, {
  required TenantAdminProfileTypesController controller,
  required TenantAdminProfileTypeDefinition definition,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 2000);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  GetIt.I.registerSingleton<TenantAdminProfileTypesController>(controller);

  await pumpAutoRouteTestApp(
    tester,
    routeName: 'tenant-admin-profile-type-form-test',
    routeFamily: CanonicalRouteFamily.tenantAdminAccountsInternal,
    child: TenantAdminProfileTypeFormScreen(definition: definition),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpListScreen(
  WidgetTester tester, {
  required TenantAdminProfileTypesController controller,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 2000);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await controller.loadTypes();
  GetIt.I.registerSingleton<TenantAdminProfileTypesController>(controller);

  await pumpAutoRouteTestApp(
    tester,
    routeName: 'tenant-admin-profile-types-list-test',
    routeFamily: CanonicalRouteFamily.tenantAdminAccountsInternal,
    child: const TenantAdminProfileTypesListScreen(),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDetailScreen(
  WidgetTester tester, {
  required TenantAdminProfileTypesController controller,
  required TenantAdminProfileTypeDefinition definition,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 2000);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  GetIt.I.registerSingleton<TenantAdminProfileTypesController>(controller);

  await pumpAutoRouteTestApp(
    tester,
    routeName: 'tenant-admin-profile-type-detail-test',
    routeFamily: CanonicalRouteFamily.tenantAdminAccountsInternal,
    child: TenantAdminProfileTypeDetailScreen(definition: definition),
  );
  await tester.pumpAndSettle();
}

class _TestProfileTypesController extends TenantAdminProfileTypesController {
  _TestProfileTypesController(
    this._impactCount, {
    List<TenantAdminProfileTypeDefinition> initialProfileTypes = const [],
  }) : super(
         repository: _FakeAccountProfilesRepository(
           initialProfileTypes: initialProfileTypes,
         ),
         taxonomiesRepository: _FakeTaxonomiesRepository(),
       );

  final int _impactCount;
  int submitUpdateCalls = 0;
  TenantAdminProfileTypeCapabilities? lastCapabilities;
  TenantAdminPoiVisual? lastVisual;
  Completer<void>? pendingSubmission;
  int? lastExpectedCapabilityRevision;

  @override
  Future<int> previewDisableProjectionCount(
    String type,
    TenantAdminProfileTypeCapabilities capabilities,
  ) async {
    return _impactCount;
  }

  @override
  Future<void> submitUpdateType({
    required String type,
    String? newType,
    String? label,
    String? pluralLabel,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    int? expectedCapabilityRevision,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    bool? removeTypeAsset,
    bool includeVisual = false,
  }) async {
    submitUpdateCalls += 1;
    lastCapabilities = capabilities;
    lastVisual = visual;
    lastExpectedCapabilityRevision = expectedCapabilityRevision;
    if (pendingSubmission != null) {
      await pendingSubmission!.future;
    }
  }
}

class _FakeAccountProfilesRepository
    extends TenantAdminAccountProfilesRepositoryContract
    with TenantAdminProfileTypesPaginationMixin {
  _FakeAccountProfilesRepository({
    List<TenantAdminProfileTypeDefinition> initialProfileTypes = const [],
  }) : _initialProfileTypes =
           List<TenantAdminProfileTypeDefinition>.unmodifiable(
             initialProfileTypes,
           );

  final List<TenantAdminProfileTypeDefinition> _initialProfileTypes;

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required TenantAdminAccountProfilesRepoString accountId,
    required TenantAdminAccountProfilesRepoString profileType,
    required TenantAdminAccountProfilesRepoString displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    List<TenantAdminNestedProfileGroup> nestedProfileGroups =
        const <TenantAdminNestedProfileGroup>[],
    BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft> contactChannelDrafts =
        const <BellugaContactChannelDraft>[],
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: type,
      label: label,
      pluralLabel: pluralLabel ?? label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<void> deleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {}

  @override
  Future<void> deleteProfileType(
    TenantAdminAccountProfilesRepoString type,
  ) async {}

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
  }) async {
    return const <TenantAdminAccountProfile>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchAccountProfilesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? search,
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoString? profileType,
  }) async {
    final profiles = await fetchAccountProfiles(accountId: accountId);
    return tenantAdminPagedResultFromRaw(items: profiles, hasMore: false);
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return _initialProfileTypes;
  }

  @override
  Future<TenantAdminProfileTypeDefinition> fetchProfileType(
    TenantAdminAccountProfilesRepoString profileType,
  ) async {
    for (final definition in _initialProfileTypes) {
      if (definition.type == profileType.value) {
        return definition;
      }
    }
    throw StateError('Profile type not found: ${profileType.value}');
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
  fetchProfileTypesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: _initialProfileTypes,
      hasMore: false,
    );
  }

  @override
  Future<void> forceDeleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    TenantAdminAccountProfilesRepoString? profileType,
    TenantAdminAccountProfilesRepoString? displayName,
    TenantAdminAccountProfilesRepoString? slug,
    TenantAdminAccountProfilesRepoInt? aggregateRevision,
    TenantAdminLocation? location,
    TenantAdminAccountProfilesRepoBool? includeLocation,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminAccountProfilesRepoBool? removeAvatar,
    TenantAdminAccountProfilesRepoBool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    List<TenantAdminNestedProfileGroup>? nestedProfileGroups,
    BellugaContactSourceMode? contactMode,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminAccountProfilesRepoInt? expectedCapabilityRevision,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: newType ?? type,
      label: label ?? type,
      pluralLabel: pluralLabel ?? label ?? type,
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities:
          capabilities ??
          tenantAdminProfileTypeCapabilitiesFromRaw(<
            String,
            TenantAdminProfileTypeCapabilityValue
          >{
            'is_favoritable': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: 'disabled',
            ),
            'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'is_physical_host_enabled':
                tenantAdminProfileTypeCapabilityValueFromRaw(
                  value: false,
                ),
            'has_bio': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_taxonomies': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_avatar': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_cover': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
            'has_events': tenantAdminProfileTypeCapabilityValueFromRaw(
              value: false,
            ),
          }),
    );
  }
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {}

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {}

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return const <TenantAdminTaxonomyDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
  fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: const <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return const <TenantAdminTaxonomyTermDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
  fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: const <TenantAdminTaxonomyTermDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) async {
    throw UnimplementedError();
  }
}

TenantAdminRequiredTextValue _text(String value) =>
    TenantAdminRequiredTextValue()..parse(value);
