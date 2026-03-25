import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_edit_route.dart';
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_type_edit_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'TenantAdminEventEditRoutePage shows deterministic fallback when event arg is absent',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TenantAdminEventEditRoutePage(),
        ),
      );
      await tester.pump();

      expect(find.text('Editar evento'), findsOneWidget);
      expect(find.text('Evento indisponível'), findsOneWidget);
      expect(find.text('Voltar para eventos'), findsOneWidget);
    },
  );

  testWidgets(
    'TenantAdminEventTypeEditRoutePage shows deterministic fallback when type arg is absent',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TenantAdminEventTypeEditRoutePage(),
        ),
      );
      await tester.pump();

      expect(find.text('Editar tipo de evento'), findsOneWidget);
      expect(find.text('Tipo de evento indisponível'), findsOneWidget);
      expect(find.text('Voltar para tipos de evento'), findsOneWidget);
    },
  );
}
