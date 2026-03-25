import 'package:belluga_now/application/router/modular_app/modules/invites_module.dart';
import 'package:belluga_now/presentation/tenant_public/invites/routes/invite_share_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerLazySingleton<InvitesModule>(
      () => InvitesModule(),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'InviteShareRoutePage shows deterministic fallback when invite arg is absent',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InviteShareRoutePage(),
        ),
      );
      await tester.pump();

      expect(find.text('Compartilhar convite'), findsOneWidget);
      expect(find.text('Convite indisponível'), findsOneWidget);
      expect(find.text('Ir para convites'), findsOneWidget);
    },
  );
}
