import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_bool_value.dart';
import 'package:belluga_now/infrastructure/services/push/push_action_dispatcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
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
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>(defaultValue: null);

  @override
  final StreamValue<String?> lastKnownAddressStreamValue = StreamValue<String?>(
    defaultValue: null,
  );

  @override
  @override
  final StreamValue<LocationResolutionPhase>
  locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(Object? address) async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({Object? minInterval}) async => false;

  @override
  Future<String?> resolveUserLocation({
    Object? timeout,
    UserLocationRepositoryContractBoolValue? requestPermissionIfNeededValue,
  }) async => null;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async => false;

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
      userLocationRepository: _FakeUserLocationRepository(),
      onShowToast: (message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
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

  test(
    'contacts permission permanently denied opens contacts settings',
    () async {
      var contactsSettingsOpenCount = 0;
      final dispatcher = PushActionDispatcher(
        userLocationRepository: _FakeUserLocationRepository(),
        contactsPermissionRequester: () async =>
            PermissionStatus.permanentlyDenied,
        contactsSettingsOpener: () async {
          contactsSettingsOpenCount += 1;
        },
        onShowToast: (_) => fail('toast should not be shown'),
      );

      await dispatcher.dispatch(
        button: ButtonData.fromMap({
          'label': 'Contacts',
          'action': {
            'type': 'custom',
            'custom_action': 'request_contacts_permission',
          },
        }),
        step: StepData.fromMap({
          'slug': 'contacts-step',
          'type': 'cta',
          'title': 'Contacts',
          'gate': {
            'type': 'contacts_permission',
            'onFail': {'toast': 'Need contacts'},
          },
          'buttons': [],
        }),
      );

      expect(contactsSettingsOpenCount, 1);
    },
  );

  test('location permission denied shows the configured toast', () async {
    final shownToasts = <String>[];
    final dispatcher = PushActionDispatcher(
      userLocationRepository: _FakeUserLocationRepository(),
      locationPermissionChecker: () async => LocationPermission.denied,
      onShowToast: shownToasts.add,
    );

    await dispatcher.dispatch(
      button: ButtonData.fromMap({
        'label': 'Location',
        'action': {
          'type': 'custom',
          'custom_action': 'request_location_permission',
        },
      }),
      step: StepData.fromMap({
        'slug': 'location-step',
        'type': 'cta',
        'title': 'Location',
        'gate': {
          'type': 'location_permission',
          'onFail': {'toast': 'Need location'},
        },
        'buttons': [],
      }),
    );

    expect(shownToasts, ['Need location']);
  });
}
