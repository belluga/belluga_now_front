import 'package:belluga_now/application/map_surface/belluga_map_handle.dart';
import 'package:belluga_now/application/map_surface/belluga_map_interaction.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_surface/belluga_map_surface.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_surface/belluga_map_surface_flutter_map.dart'
    as flutter_map_surface;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets(
    'publishes programmatic viewport changes for real handle translations',
    (tester) async {
      final handle = BellugaMapHandle();
      final interactions = <BellugaMapInteractionEvent>[];
      final subscription = handle.interactionStream.listen(interactions.add);
      addTearDown(() async {
        await subscription.cancel();
        handle.dispose();
      });

      await _pumpMapSurface(tester, handle);
      interactions.clear();
      final initialViewport = handle.currentViewport!;

      final ordinaryTarget = CityCoordinate.fromLatLng(
        const LatLng(-20.3400, -40.3400),
      );
      expect(
        ordinaryTarget.latitude,
        lessThan(initialViewport.southWest.latitude),
      );
      expect(handle.moveTo(ordinaryTarget, zoom: 16), isTrue);
      await tester.pump();

      final ordinaryEvent = interactions.singleWhere(
        (event) => event.isViewportChange,
      );
      expect(ordinaryEvent.origin, BellugaMapInteractionOrigin.programmatic);
      expect(ordinaryEvent.viewport, isNotNull);
      expect(
        ordinaryEvent.viewport!.northEast.latitude,
        greaterThan(ordinaryTarget.latitude),
      );
      expect(
        ordinaryEvent.viewport!.southWest.latitude,
        lessThan(ordinaryTarget.latitude),
      );
      expect(
        ordinaryEvent.viewport!.southWest.latitude,
        isNot(initialViewport.southWest.latitude),
      );

      interactions.clear();
      final anchoredTarget = CityCoordinate.fromLatLng(
        const LatLng(-20.3700, -40.3700),
      );
      expect(
        anchoredTarget.latitude,
        lessThan(ordinaryEvent.viewport!.southWest.latitude),
      );
      expect(
        handle.moveToAnchored(
          anchoredTarget,
          zoom: 16,
          verticalViewportAnchor: 0.68,
        ),
        isTrue,
      );
      await tester.pump();

      final anchoredEvent = interactions.singleWhere(
        (event) => event.isViewportChange,
      );
      expect(anchoredEvent.origin, BellugaMapInteractionOrigin.programmatic);
      expect(anchoredEvent.type, BellugaMapInteractionType.pan);
      expect(anchoredEvent.viewport, isNotNull);
      expect(
        anchoredEvent.viewport!.northEast.latitude,
        greaterThan(anchoredTarget.latitude),
      );
      expect(
        anchoredEvent.viewport!.southWest.latitude,
        lessThan(anchoredTarget.latitude),
      );
      expect(
        anchoredEvent.viewport!.southWest.latitude,
        isNot(ordinaryEvent.viewport!.southWest.latitude),
      );
    },
  );

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

      await _pumpMapSurface(tester, handle);
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

  testWidgets('publishes user drag only after the movement settles', (
    tester,
  ) async {
    final handle = BellugaMapHandle();
    final interactions = <BellugaMapInteractionEvent>[];
    final subscription = handle.interactionStream.listen(interactions.add);
    addTearDown(() async {
      await subscription.cancel();
      handle.dispose();
    });

    await _pumpMapSurface(tester, handle);
    interactions.clear();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FlutterMap)),
    );
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();

    expect(interactions.where((event) => event.isViewportChange), isEmpty);

    await gesture.up();
    await tester.pump();

    final settledEvent = interactions.singleWhere(
      (event) => event.isViewportChange,
    );
    expect(settledEvent.type, BellugaMapInteractionType.pan);
    expect(settledEvent.origin, BellugaMapInteractionOrigin.user);
  });

  test('classifies flutter_map sources at the adapter boundary', () {
    expect(
      flutter_map_surface.mapInteractionOriginForSource(MapEventSource.dragEnd),
      BellugaMapInteractionOrigin.user,
    );
    expect(
      flutter_map_surface.mapInteractionOriginForSource(
        MapEventSource.scrollWheel,
      ),
      BellugaMapInteractionOrigin.user,
    );
    expect(
      flutter_map_surface.mapInteractionOriginForSource(
        MapEventSource.mapController,
      ),
      BellugaMapInteractionOrigin.programmatic,
    );
    expect(
      flutter_map_surface.mapInteractionOriginForSource(
        MapEventSource.fitCamera,
      ),
      BellugaMapInteractionOrigin.programmatic,
    );
    expect(
      flutter_map_surface.mapInteractionOriginForSource(
        MapEventSource.nonRotatedSizeChange,
      ),
      BellugaMapInteractionOrigin.system,
    );
  });
}

Future<void> _pumpMapSurface(
  WidgetTester tester,
  BellugaMapHandle handle,
) async {
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
}
