import 'package:belluga_now/application/map_surface/belluga_map_handle.dart';
import 'package:belluga_now/application/map_surface/belluga_map_interaction.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_surface/belluga_map_surface.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets(
    'publishes a viewport change when wheel zoom settles without pan',
    (tester) async {
      final handle = BellugaMapHandle();
      final interactions = <BellugaMapInteractionEvent>[];
      final subscription = handle.interactionStream.listen(interactions.add);
      addTearDown(() async {
        await subscription.cancel();
        handle.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BellugaMapSurface(
              handle: handle,
              initialCenter: CityCoordinate.fromLatLng(
                const LatLng(-20.3155, -40.3128),
              ),
              initialZoom: 15,
              minZoom: 10,
              maxZoom: 18,
              annotations: const [],
            ),
          ),
        ),
      );
      await tester.pump();
      interactions.clear();

      final mapCenter = tester.getCenter(find.byType(FlutterMap));
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: mapCenter,
          scrollDelta: const Offset(0, -120),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        interactions.where(
          (event) => event.type == BellugaMapInteractionType.zoom,
        ),
        isNotEmpty,
      );
      expect(interactions.last.origin, BellugaMapInteractionOrigin.user);
      expect(interactions.last.viewport, isNotNull);
    },
  );

  test('classifies flutter_map sources at the adapter boundary', () {
    expect(
      mapInteractionOriginForSource(MapEventSource.dragEnd),
      BellugaMapInteractionOrigin.user,
    );
    expect(
      mapInteractionOriginForSource(MapEventSource.scrollWheel),
      BellugaMapInteractionOrigin.user,
    );
    expect(
      mapInteractionOriginForSource(MapEventSource.mapController),
      BellugaMapInteractionOrigin.programmatic,
    );
    expect(
      mapInteractionOriginForSource(MapEventSource.fitCamera),
      BellugaMapInteractionOrigin.programmatic,
    );
    expect(
      mapInteractionOriginForSource(MapEventSource.nonRotatedSizeChange),
      BellugaMapInteractionOrigin.system,
    );
  });
}
