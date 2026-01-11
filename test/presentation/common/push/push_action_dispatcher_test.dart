import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/push/push_action_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_handler/push_handler.dart';
import 'package:stream_value/core/stream_value.dart';

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>(defaultValue: null);

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(String? address) async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({
    Duration minInterval = const Duration(seconds: 30),
  }) async =>
      false;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      false;

  @override
  Future<void> stopTracking() async {}
}

void main() {
  testWidgets('noop custom action is treated as unsupported', (tester) async {
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    final dispatcher = PushActionDispatcher(
      contextProvider: () => context,
      userLocationRepository: _FakeUserLocationRepository(),
    );

    final button = ButtonData.fromMap({
      'label': 'Test',
      'action': {'type': 'custom', 'custom_action': 'noop'},
    });
    final step = StepData.fromMap({
      'slug': 'step-1',
      'type': 'cta',
      'title': 'Step 1',
      'body': '',
      'buttons': [],
    });

    await tester.runAsync(
      () => dispatcher.dispatch(button: button, step: step),
    );
    await tester.pump();

    expect(
      find.text('Ação indisponível. Atualize o app ou tente novamente.'),
      findsOneWidget,
    );
  });
}
