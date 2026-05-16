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
import 'package:belluga_now/presentation/tenant_admin/profile_types/screens/tenant_admin_profile_type_form_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_map_marker_icon_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'asks destructive confirmation when disabling POI and respects cancel/confirm',
    (tester) async {
      final controller = _TestProfileTypesController(impactCount: 67);
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
          capabilities: TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(true),
            isReferenceLocationEnabled: TenantAdminFlagValue(true),
            hasBio: TenantAdminFlagValue(true),
            hasContent: TenantAdminFlagValue(true),
            hasTaxonomies: TenantAdminFlagValue(true),
            hasAvatar: TenantAdminFlagValue(true),
            hasCover: TenantAdminFlagValue(true),
            hasEvents: TenantAdminFlagValue(true),
          ),
        ),
      );

      final poiToggle = find.widgetWithText(SwitchListTile, 'POI habilitado');
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
      expect(controller.lastCapabilities?.isPoiEnabled, isFalse);
      expect(controller.lastCapabilities?.isReferenceLocationEnabled, isFalse);
      expect(controller.lastVisual, isNotNull);
      expect(controller.lastVisual?.mode, TenantAdminPoiVisualMode.icon);
    },
  );

  testWidgets('disables reference location toggle when poi is disabled', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(impactCount: 0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'hotel',
        label: 'Hotel',
        allowedTaxonomies: const [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(false),
          isReferenceLocationEnabled: TenantAdminFlagValue(true),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasEvents: TenantAdminFlagValue(true),
        ),
      ),
    );

    final referenceToggle = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Referencia fixa habilitada'),
    );

    expect(referenceToggle.value, isFalse);
    expect(referenceToggle.onChanged, isNull);
    expect(find.text('Requer POI habilitado.'), findsOneWidget);
  });

  testWidgets(
    'disables favoritable behind public discovery and keeps it off when re-enabled',
    (tester) async {
      final controller = _TestProfileTypesController(impactCount: 0);
      await _pumpFormScreen(
        tester,
        controller: controller,
        definition: tenantAdminProfileTypeDefinitionFromRaw(
          type: 'artist',
          label: 'Artist',
          allowedTaxonomies: const [],
          capabilities: TenantAdminProfileTypeCapabilities(
            isPubliclyDiscoverable: TenantAdminFlagValue(false),
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(true),
            hasContent: TenantAdminFlagValue(true),
            hasTaxonomies: TenantAdminFlagValue(true),
            hasAvatar: TenantAdminFlagValue(true),
            hasCover: TenantAdminFlagValue(true),
            hasEvents: TenantAdminFlagValue(true),
          ),
        ),
      );

      var favoritableToggle = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Favoritavel'),
      );

      expect(favoritableToggle.value, isFalse);
      expect(favoritableToggle.onChanged, isNull);
      expect(
        find.text('Requer descoberta publica habilitada.'),
        findsOneWidget,
      );

      final publicToggle = find.widgetWithText(
        SwitchListTile,
        'Descoberta publica habilitada',
      );
      await tester.ensureVisible(publicToggle);
      await tester.tap(publicToggle);
      await tester.pumpAndSettle();

      favoritableToggle = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Favoritavel'),
      );
      expect(favoritableToggle.value, isFalse);
      expect(favoritableToggle.onChanged, isNotNull);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Favoritavel'));
      await tester.pumpAndSettle();

      favoritableToggle = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Favoritavel'),
      );
      expect(favoritableToggle.value, isTrue);

      await tester.tap(publicToggle);
      await tester.pumpAndSettle();

      favoritableToggle = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Favoritavel'),
      );
      expect(favoritableToggle.value, isFalse);
      expect(favoritableToggle.onChanged, isNull);

      await tester.tap(publicToggle);
      await tester.pumpAndSettle();

      favoritableToggle = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Favoritavel'),
      );
      expect(favoritableToggle.value, isFalse);
      expect(favoritableToggle.onChanged, isNotNull);
    },
  );

  testWidgets('renders shared marker icon picker in POI visual editor', (
    tester,
  ) async {
    final controller = _TestProfileTypesController(impactCount: 0);
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
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(true),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasEvents: TenantAdminFlagValue(true),
        ),
      ),
    );

    expect(find.text('Visual do tipo'), findsOneWidget);
    expect(find.byType(TenantAdminMapMarkerIconPickerField), findsOneWidget);
  });

  testWidgets('renders and hydrates plural label field', (tester) async {
    final controller = _TestProfileTypesController(impactCount: 0);
    await _pumpFormScreen(
      tester,
      controller: controller,
      definition: tenantAdminProfileTypeDefinitionFromRaw(
        type: 'artist',
        label: 'Artist',
        pluralLabel: 'Artists',
        allowedTaxonomies: const [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasEvents: TenantAdminFlagValue(true),
        ),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Label plural'), findsOneWidget);
    expect(find.text('Artists'), findsWidgets);
  });

  testWidgets(
    'shows canonical type image upload controls for type_asset visuals',
    (tester) async {
      final controller = _TestProfileTypesController(impactCount: 0);
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
          capabilities: TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(true),
            hasBio: TenantAdminFlagValue(true),
            hasContent: TenantAdminFlagValue(true),
            hasTaxonomies: TenantAdminFlagValue(true),
            hasAvatar: TenantAdminFlagValue(true),
            hasCover: TenantAdminFlagValue(true),
            hasEvents: TenantAdminFlagValue(true),
          ),
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
    final controller = _TestProfileTypesController(impactCount: 0);
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
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(true),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasEvents: TenantAdminFlagValue(true),
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
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  GetIt.I.registerSingleton<TenantAdminProfileTypesController>(controller);

  await tester.pumpWidget(
    MaterialApp(home: TenantAdminProfileTypeFormScreen(definition: definition)),
  );
  await tester.pumpAndSettle();
}

class _TestProfileTypesController extends TenantAdminProfileTypesController {
  _TestProfileTypesController({required int impactCount})
    : _impactCount = impactCount,
      super(
        repository: _FakeAccountProfilesRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
      );

  final int _impactCount;
  int submitUpdateCalls = 0;
  TenantAdminProfileTypeCapabilities? lastCapabilities;
  TenantAdminPoiVisual? lastVisual;

  @override
  Future<int> previewDisableProjectionCount(String type) async {
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
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    bool? removeTypeAsset,
    bool includeVisual = false,
  }) async {
    submitUpdateCalls += 1;
    lastCapabilities = capabilities;
    lastVisual = visual;
  }
}

class _FakeAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required TenantAdminAccountProfilesRepoString accountId,
    required TenantAdminAccountProfilesRepoString profileType,
    required TenantAdminAccountProfilesRepoString displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? content,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
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
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return const <TenantAdminProfileTypeDefinition>[];
  }

  @override
  Future<TenantAdminProfileTypeDefinition> fetchProfileType(
    TenantAdminAccountProfilesRepoString profileType,
  ) async {
    throw StateError('Profile type not found: ${profileType.value}');
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
  fetchProfileTypesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: const <TenantAdminProfileTypeDefinition>[],
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
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? content,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminAccountProfilesRepoBool? removeAvatar,
    TenantAdminAccountProfilesRepoBool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
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
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: newType ?? type,
      label: label ?? type,
      pluralLabel: pluralLabel ?? label ?? type,
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities:
          capabilities ??
          TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(false),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasEvents: TenantAdminFlagValue(false),
          ),
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
