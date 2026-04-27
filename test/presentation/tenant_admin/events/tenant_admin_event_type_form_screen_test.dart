import 'dart:async';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_temporal_bucket.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_legacy_event_parties_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_type_form_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_map_marker_icon_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('renders shared marker icon picker in event type visual editor',
      (tester) async {
    final controller = TenantAdminEventsController(
      eventsRepository: _NoopEventsRepository(),
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: TenantAdminEventTypeFormScreen(
          existingType: TenantAdminEventType(
            idValue: tenantAdminOptionalText('type-1'),
            nameValue: tenantAdminRequiredText('Show'),
            slugValue: tenantAdminRequiredText('show'),
            visual: TenantAdminPoiVisual.icon(
              iconValue: TenantAdminRequiredTextValue()..parse('music_note'),
              colorValue: TenantAdminHexColorValue()..parse('#FF8800'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visual do tipo'), findsOneWidget);
    expect(find.byType(TenantAdminMapMarkerIconPickerField), findsOneWidget);
  });

  testWidgets(
      'shows canonical event type image upload controls for type_asset visuals',
      (tester) async {
    final controller = TenantAdminEventsController(
      eventsRepository: _NoopEventsRepository(),
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: TenantAdminEventTypeFormScreen(
          existingType: TenantAdminEventType(
            idValue: tenantAdminOptionalText('type-1'),
            nameValue: tenantAdminRequiredText('Festival'),
            slugValue: tenantAdminRequiredText('festival'),
            visual: TenantAdminPoiVisual.image(
              imageSource: TenantAdminPoiVisualImageSource.typeAsset,
              colorValue: TenantAdminHexColorValue()..parse('#00897B'),
              imageUrlValue: TenantAdminOptionalUrlValue()
                ..parse(
                  'https://tenant.test/api/v1/media/event-types/type-1/type_asset?v=3',
                ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Imagem canônica do tipo'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Cor do marcador'),
      findsOneWidget,
    );
    expect(find.byType(TenantAdminImageUploadField), findsOneWidget);
    expect(find.text('Enviar imagem canônica'), findsOneWidget);
  });

  testWidgets(
      'event type image source options exclude avatar and use event cover label',
      (tester) async {
    final controller = TenantAdminEventsController(
      eventsRepository: _NoopEventsRepository(),
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: TenantAdminEventTypeFormScreen(
          existingType: TenantAdminEventType(
            idValue: tenantAdminOptionalText('type-1'),
            nameValue: tenantAdminRequiredText('Festival'),
            slugValue: tenantAdminRequiredText('festival'),
            visual: TenantAdminPoiVisual.image(
              imageSource: TenantAdminPoiVisualImageSource.cover,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
        find.byType(DropdownButtonFormField<TenantAdminPoiVisualImageSource>));
    await tester.pumpAndSettle();

    expect(find.text('Capa do evento'), findsWidgets);
    expect(find.text('Imagem canônica do tipo'), findsWidgets);
    expect(find.text('Avatar do perfil'), findsNothing);
  });

  testWidgets(
      'drops duplicate submits while preparing type asset upload for event type save',
      (tester) async {
    final saveCompleter = Completer<TenantAdminEventType>();
    final uploadGate = Completer<void>();
    final repository = _RecordingEventsRepository(
      updateEventTypeWithVisualResult: saveCompleter.future,
    );
    final imageIngestionService = _DelayedImageIngestionService(
      buildUploadCompleter: uploadGate,
      upload: tenantAdminMediaUploadFromRaw(
        bytes: Uint8List.fromList(_validPngBytes),
        fileName: 'event-type.png',
        mimeType: 'image/png',
      ),
    );
    final controller = TenantAdminEventsController(
      eventsRepository: repository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      imageIngestionService: imageIngestionService,
    );
    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    final existingType = TenantAdminEventType(
      idValue: tenantAdminOptionalText('type-1'),
      nameValue: tenantAdminRequiredText('Festival'),
      slugValue: tenantAdminRequiredText('festival'),
      visual: TenantAdminPoiVisual.image(
        imageSource: TenantAdminPoiVisualImageSource.typeAsset,
      ),
    );

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: TenantAdminEventTypeFormScreen(existingType: existingType),
      ),
    );
    await tester.pumpAndSettle();

    controller.updateEventTypeTypeAssetFile(
      XFile.fromData(
        Uint8List.fromList(_validPngBytes),
        name: 'picked.png',
        mimeType: 'image/png',
      ),
    );
    await tester.pump();

    final saveButton = find.text('Salvar alterações');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pump();

    expect(controller.eventTypeFormStateStreamValue.value.isSaving, isTrue);
    expect(repository.updateEventTypeWithVisualCallCount, 0);

    uploadGate.complete();
    await tester.pump();
    await tester.pump();

    expect(repository.updateEventTypeWithVisualCallCount, 1);

    saveCompleter.complete(existingType);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'event type edit preloads allowed taxonomies and preserves them when saving unrelated visual changes',
      (tester) async {
    final taxonomyA = TenantAdminTaxonomyDefinition(
      idValue: tenantAdminRequiredText('taxonomy-a'),
      slugValue: tenantAdminRequiredText('genre'),
      nameValue: tenantAdminRequiredText('Genero Musical'),
      appliesToValue: tenantAdminTrimmedStringList(const ['event']),
      iconValue: tenantAdminOptionalText('music_note'),
      colorValue: tenantAdminOptionalText('#AA5500'),
    );
    final taxonomyB = TenantAdminTaxonomyDefinition(
      idValue: tenantAdminRequiredText('taxonomy-b'),
      slugValue: tenantAdminRequiredText('cuisine'),
      nameValue: tenantAdminRequiredText('Cozinha'),
      appliesToValue: tenantAdminTrimmedStringList(const ['event']),
      iconValue: tenantAdminOptionalText('restaurant'),
      colorValue: tenantAdminOptionalText('#225588'),
    );
    final existingType = TenantAdminEventType.withAllowedTaxonomies(
      idValue: tenantAdminOptionalText('type-1'),
      nameValue: tenantAdminRequiredText('Festival'),
      slugValue: tenantAdminRequiredText('festival'),
      allowedTaxonomiesValue:
          tenantAdminTrimmedStringList(const ['genre', 'cuisine']),
      visual: TenantAdminPoiVisual.icon(
        iconValue: TenantAdminRequiredTextValue()..parse('celebration'),
        colorValue: TenantAdminHexColorValue()..parse('#FF8800'),
      ),
    );
    final repository = _RecordingEventsRepository(
      updateEventTypeWithVisualResult: Future<TenantAdminEventType>.value(
        existingType,
      ),
    );
    final controller = TenantAdminEventsController(
      eventsRepository: repository,
      taxonomiesRepository: _SeededTaxonomiesRepository(
        taxonomies: [taxonomyA, taxonomyB],
      ),
    );
    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: _RecordingStackRouter(),
        child: TenantAdminEventTypeFormScreen(existingType: existingType),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Taxonomias permitidas'), findsOneWidget);
    expect(
      controller.selectedEventTypeAllowedTaxonomies,
      ['genre', 'cuisine'],
    );
    await tester.ensureVisible(find.text('Genero Musical (genre)'));
    await tester.pumpAndSettle();
    final taxonomySemantics = tester
        .getSemantics(
          find.byKey(
            const ValueKey<String>(
              'tenantAdminEventTypeAllowedTaxonomySemantics_genre',
            ),
          ),
        )
        .getSemanticsData();
    expect(taxonomySemantics.hasAction(SemanticsAction.tap), isTrue);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cor do marcador'),
      '#123456',
    );
    final saveButton = find.text('Salvar alterações');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.updateEventTypeWithVisualCallCount, 1);
    expect(
      repository.lastUpdateAllowedTaxonomies,
      ['genre', 'cuisine'],
    );
  });
}

Widget _buildRoutedTestApp({
  required _RecordingStackRouter router,
  required Widget child,
}) {
  final routeData = RouteData(
    route: _FakeRouteMatch(
      name: TenantAdminEventTypeCreateRoute.name,
      fullPath: '/admin/events/types/create',
      meta: canonicalRouteMeta(
        family: CanonicalRouteFamily.tenantAdminEventsInternal,
        chromeMode: RouteChromeMode.fullscreen,
      ),
      pageRouteInfo: const TenantAdminEventTypeCreateRoute(),
    ),
    router: router,
    stackKey: const ValueKey<String>('stack'),
    pendingChildren: const <RouteMatch>[],
    type: const RouteType.material(),
  );

  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: RouteDataScope(
        routeData: routeData,
        child: child,
      ),
    ),
  );
}

class _NoopEventsRepository extends TenantAdminEventsRepositoryContract
    with TenantAdminEventsPaginationMixin {
  @override
  Future<TenantAdminEventType> createEventType({
    required TenantAdminEventsRepoString name,
    required TenantAdminEventsRepoString slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEventType> createEventTypeWithVisual({
    required TenantAdminEventsRepoString name,
    required TenantAdminEventsRepoString slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createEvent({required TenantAdminEventDraft draft}) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(
      TenantAdminEventsRepoString eventIdOrSlug) {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    return <TenantAdminEvent>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: const <TenantAdminAccountProfile>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
      fetchLegacyEventPartiesSummary() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(0),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(0),
      failedValue: TenantAdminCountValue(0),
    );
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
      repairLegacyEventParties() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(0),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(0),
      failedValue: TenantAdminCountValue(0),
    );
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEventType> updateEventType({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
  }) {
    throw UnimplementedError();
  }
}

class _NoopTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) {
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
    return <TenantAdminTaxonomyDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return <TenantAdminTaxonomyTermDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminTaxonomyTermDefinition>[],
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) {
    throw UnimplementedError();
  }
}

class _SeededTaxonomiesRepository extends _NoopTaxonomiesRepository {
  _SeededTaxonomiesRepository({
    required this.taxonomies,
  });

  final List<TenantAdminTaxonomyDefinition> taxonomies;

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return List<TenantAdminTaxonomyDefinition>.unmodifiable(taxonomies);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: taxonomies,
      hasMore: false,
    );
  }
}

class _RecordingEventsRepository extends _NoopEventsRepository {
  _RecordingEventsRepository({
    required this.updateEventTypeWithVisualResult,
  });

  final Future<TenantAdminEventType> updateEventTypeWithVisualResult;
  int updateEventTypeWithVisualCallCount = 0;
  List<String>? lastUpdateAllowedTaxonomies;

  @override
  Future<TenantAdminEventType> updateEventTypeWithVisual({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    TenantAdminEventsRepoBool? removeTypeAsset,
  }) {
    updateEventTypeWithVisualCallCount += 1;
    lastUpdateAllowedTaxonomies =
        allowedTaxonomies?.map((entry) => entry.value).toList(growable: false);
    return updateEventTypeWithVisualResult;
  }
}

class _DelayedImageIngestionService extends TenantAdminImageIngestionService {
  _DelayedImageIngestionService({
    required this.buildUploadCompleter,
    required this.upload,
  });

  final Completer<void> buildUploadCompleter;
  final TenantAdminMediaUpload upload;

  @override
  Future<TenantAdminMediaUpload?> buildUpload(
    XFile? file, {
    required TenantAdminImageSlot slot,
  }) async {
    await buildUploadCompleter.future;
    return upload;
  }
}

class _RecordingStackRouter extends Fake implements StackRouter {
  int maybePopCallCount = 0;

  @override
  Future<bool> maybePop<T extends Object?>([T? result]) async {
    maybePopCallCount += 1;
    return true;
  }
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.name,
    required this.fullPath,
    required this.meta,
    required this.pageRouteInfo,
  });

  @override
  final String name;

  @override
  final String fullPath;

  @override
  final Map<String, dynamic> meta;

  final PageRouteInfo<dynamic> pageRouteInfo;

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => pageRouteInfo;
}

const List<int> _validPngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
