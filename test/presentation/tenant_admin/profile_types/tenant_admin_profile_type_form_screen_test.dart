import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/screens/tenant_admin_profile_type_form_screen.dart';
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
    GetIt.I.registerSingleton<TenantAdminProfileTypesController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: TenantAdminProfileTypeFormScreen(
          definition: TenantAdminProfileTypeDefinition(
            type: 'venue',
            label: 'Venue',
            allowedTaxonomies: const [],
            poiVisual: TenantAdminPoiVisual.icon(
              icon: 'place',
              color: '#FF8800',
            ),
            capabilities: TenantAdminProfileTypeCapabilities(
              isFavoritable: true,
              isPoiEnabled: true,
              hasBio: true,
              hasContent: true,
              hasTaxonomies: true,
              hasAvatar: true,
              hasCover: true,
              hasEvents: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'POI habilitado'));
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
    expect(controller.lastPoiVisual, isNull);
  });

  testWidgets('renders shared marker icon picker in POI visual editor',
      (tester) async {
    final controller = _TestProfileTypesController(impactCount: 0);
    GetIt.I.registerSingleton<TenantAdminProfileTypesController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: TenantAdminProfileTypeFormScreen(
          definition: TenantAdminProfileTypeDefinition(
            type: 'venue',
            label: 'Venue',
            allowedTaxonomies: const [],
            poiVisual: TenantAdminPoiVisual.icon(
              icon: 'place',
              color: '#FF8800',
            ),
            capabilities: TenantAdminProfileTypeCapabilities(
              isFavoritable: true,
              isPoiEnabled: true,
              hasBio: true,
              hasContent: true,
              hasTaxonomies: true,
              hasAvatar: true,
              hasCover: true,
              hasEvents: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visual do POI'), findsOneWidget);
    expect(find.byType(TenantAdminMapMarkerIconPickerField), findsOneWidget);
  });
}

class _TestProfileTypesController extends TenantAdminProfileTypesController {
  _TestProfileTypesController({
    required int impactCount,
  })  : _impactCount = impactCount,
        super(
          repository: _FakeAccountProfilesRepository(),
          taxonomiesRepository: _FakeTaxonomiesRepository(),
        );

  final int _impactCount;
  int submitUpdateCalls = 0;
  TenantAdminProfileTypeCapabilities? lastCapabilities;
  TenantAdminPoiVisual? lastPoiVisual;

  @override
  Future<int> previewDisableProjectionCount(String type) async {
    return _impactCount;
  }

  @override
  Future<void> submitUpdateType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? poiVisual,
    bool includePoiVisual = false,
  }) async {
    submitUpdateCalls += 1;
    lastCapabilities = capabilities;
    lastPoiVisual = poiVisual;
  }
}

class _FakeAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {}

  @override
  Future<void> deleteProfileType(String type) async {}

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    String accountProfileId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async {
    return const <TenantAdminAccountProfile>[];
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return const <TenantAdminProfileTypeDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    return TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
      items: const <TenantAdminProfileTypeDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    String accountProfileId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    bool? removeAvatar,
    bool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: newType ?? type,
      label: label ?? type,
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities: capabilities ??
          TenantAdminProfileTypeCapabilities(
            isFavoritable: false,
            isPoiEnabled: false,
            hasBio: false,
            hasContent: false,
            hasTaxonomies: false,
            hasAvatar: false,
            hasCover: false,
            hasEvents: false,
          ),
    );
  }
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {}

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {}

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return const <TenantAdminTaxonomyDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required int page,
    required int pageSize,
  }) async {
    return TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
      items: const <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    return const <TenantAdminTaxonomyTermDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required String taxonomyId,
    required int page,
    required int pageSize,
  }) async {
    return TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
      items: const <TenantAdminTaxonomyTermDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required String taxonomyId,
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    throw UnimplementedError();
  }
}
