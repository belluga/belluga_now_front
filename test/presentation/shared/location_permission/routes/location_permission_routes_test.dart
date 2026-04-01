import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/presentation/shared/location_permission/routes/location_permission_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerLazySingleton<InitializationModule>(
      () => InitializationModule(),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'LocationPermissionRoutePage renders with InitializationModule scope',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LocationPermissionRoutePage(
            initialState: LocationPermissionState.denied,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Veja o que está perto de você'), findsOneWidget);
      expect(find.text('Permitir localização'), findsOneWidget);
      expect(
        GetIt.I.isRegistered<InitializationModule>(),
        isTrue,
      );
    },
  );

  testWidgets(
    'LocationPermissionRoutePage falls back to denied state when args are absent',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LocationPermissionRoutePage(),
        ),
      );
      await tester.pump();

      expect(find.text('Veja o que está perto de você'), findsOneWidget);
      expect(find.text('Permitir localização'), findsOneWidget);
    },
  );
}
