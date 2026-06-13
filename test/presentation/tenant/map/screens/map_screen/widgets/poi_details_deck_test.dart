import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_slug_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_details_deck.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  testWidgets(
    'event invite action keeps the hydrated selected occurrence in the deck widget',
    (tester) async {
      final poi = _buildEventPoi();
      final controller = _StubMapScreenController(
        selectedPoi: poi,
        hydratedEvents: {
          poi.id: _buildEventDetailModel(
            slug: 'show-na-praia',
            occurrenceId: 'occ-map-selected',
          ),
        },
      );
      final router = _RecordingStackRouter();

      await _pumpDeck(tester, controller: controller, router: router);

      await tester.tap(find.byTooltip('Convidar'));
      await tester.pumpAndSettle();

      expect(router.pushedRoutes, hasLength(1));
      final route = router.pushedRoutes.single;
      expect(route, isA<InviteShareRoute>());
      final inviteRoute = route as InviteShareRoute;
      expect(inviteRoute.args?.invite?.eventSlug, 'show-na-praia');
      expect(inviteRoute.args?.invite?.occurrenceId, 'occ-map-selected');
    },
  );

  testWidgets(
    'event invite action fails closed when deck event hydration is missing',
    (tester) async {
      final poi = _buildEventPoi();
      final controller = _StubMapScreenController(selectedPoi: poi);
      final router = _RecordingStackRouter();

      await _pumpDeck(tester, controller: controller, router: router);

      await tester.tap(find.byTooltip('Convidar'));
      await tester.pumpAndSettle();

      expect(router.pushedRoutes, isEmpty);
      expect(
        controller.statusMessageStreamValue.value,
        'Detalhes do evento ainda não estão prontos para convite.',
      );
    },
  );
}

Future<void> _pumpDeck(
  WidgetTester tester, {
  required _StubMapScreenController controller,
  required _RecordingStackRouter router,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StackRouterScope(
        controller: router,
        stateHash: 0,
        child: Scaffold(
          body: PoiDetailDeck(controller: controller),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

CityPoiModel _buildEventPoi() {
  final idValue = CityPoiIdValue()..parse('poi-event');
  final nameValue = CityPoiNameValue()..parse('Show na Praia');
  final descriptionValue = CityPoiDescriptionValue()..parse('Evento no mapa');
  final addressValue = CityPoiAddressValue()..parse('Av. Brasil');
  final priorityValue = PoiPriorityValue()..parse('1');
  final refTypeValue = PoiReferenceTypeValue()..parse('event');
  final refIdValue = PoiReferenceIdValue()..parse('event-1');
  final refSlugValue = PoiReferenceSlugValue()..parse('show-na-praia');

  return CityPoiModel(
    idValue: idValue,
    nameValue: nameValue,
    descriptionValue: descriptionValue,
    addressValue: addressValue,
    category: CityPoiCategory.restaurant,
    coordinate: CityCoordinate(
      latitudeValue: LatitudeValue()..parse('-20.0'),
      longitudeValue: LongitudeValue()..parse('-40.0'),
    ),
    priorityValue: priorityValue,
    refTypeValue: refTypeValue,
    refIdValue: refIdValue,
    refSlugValue: refSlugValue,
    visual: CityPoiVisual.image(
      imageUriValue: controllerImageUriValue('https://tenant.test/event.png'),
    ),
  );
}

EventModel _buildEventDetailModel({
  required String slug,
  String? occurrenceId,
}) {
  return EventDTO.fromJson({
    'id': '507f1f77bcf86cd799439099',
    'slug': slug,
    'type': {
      'id': 'type-1',
      'name': 'Feira',
      'slug': 'feira',
      'description': 'Evento',
    },
    'title': 'Evento no mapa',
    'content': '<p>Evento detalhado</p>',
    'location': 'Carvoeiro',
    'date_time_start': '2026-04-07T18:00:00Z',
    'date_time_end': '2026-04-07T21:00:00Z',
    'occurrence_id': occurrenceId,
    'artists': const [],
    'linked_account_profiles': const [],
  }).toDomain();
}

PoiFilterImageUriValue controllerImageUriValue(String raw) {
  final value = PoiFilterImageUriValue();
  value.parse(raw);
  return value;
}

class _StubMapScreenController extends Fake implements MapScreenController {
  _StubMapScreenController({
    required CityPoiModel selectedPoi,
    Map<String, EventModel>? hydratedEvents,
  }) : _hydratedEvents = hydratedEvents ?? <String, EventModel>{} {
    selectedPoiStreamValue.addValue(selectedPoi);
  }

  final Map<String, EventModel> _hydratedEvents;

  @override
  final StreamValue<CityPoiModel?> selectedPoiStreamValue =
      StreamValue<CityPoiModel?>();

  @override
  final StreamValue<int> poiDeckContentRevisionStreamValue =
      StreamValue<int>(defaultValue: 0);

  @override
  final StreamValue<ProximityPreference?> proximityPreferenceStreamValue =
      StreamValue<ProximityPreference?>(defaultValue: null);

  @override
  final StreamValue<int> poiDeckHeightRevisionStreamValue =
      StreamValue<int>(defaultValue: 0);

  @override
  final StreamValue<String?> statusMessageStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  ProximityPreference? get proximityPreference => null;

  @override
  String? get authenticatedUserDisplayName => null;

  @override
  Uri get defaultEventImageUri => Uri.parse('asset://event-placeholder');

  @override
  List<CityPoiModel> deckPoisForSelectedPoi(CityPoiModel selectedPoi) =>
      <CityPoiModel>[selectedPoi];

  @override
  int deckIndexForSelectedPoi(
    CityPoiModel selectedPoi,
    List<CityPoiModel> deckPois,
  ) =>
      0;

  @override
  void clearSelectedPoi({bool preserveMarkerMemory = true}) {
    selectedPoiStreamValue.addValue(null);
  }

  @override
  Future<void> handleFilteredDeckPageChanged(int index) async {}

  @override
  bool canUsePoiAsReferencePoint(CityPoiModel poi) => false;

  @override
  bool isPoiReferencePoint(CityPoiModel poi) => false;

  @override
  EventModel? hydratedEventForPoi(CityPoiModel poi) => _hydratedEvents[poi.id];

  @override
  double? getPoiDeckHeight(String poiId) => null;

  @override
  void updatePoiDeckHeight(String poiId, double height) {}

  @override
  double resolvePoiDeckHeightForDeck(
    List<CityPoiModel> deckPois, {
    required int currentIndex,
    required double defaultHeight,
    required double safeFallbackHeight,
  }) =>
      defaultHeight;
}

class _RecordingStackRouter extends Fake implements StackRouter {
  final List<PageRouteInfo<dynamic>> pushedRoutes = [];

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushedRoutes.add(route);
    return null;
  }
}
