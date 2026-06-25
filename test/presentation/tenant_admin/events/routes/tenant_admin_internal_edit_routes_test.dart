import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_form_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_edit_route.dart';
import 'package:belluga_now/presentation/tenant_admin/events/routes/tenant_admin_event_type_edit_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'TenantAdminEventEditRoutePage exposes URL-hydratable params for readback',
    () {
      const route = TenantAdminEventEditRoutePage(
        eventId: 'evt-42',
        occurrenceId: 'occ-2',
      );

      expect(route.resolverParams, {'eventId': 'evt-42'});
    },
  );

  testWidgets(
    'TenantAdminEventEditRoutePage keeps selected occurrence as UI intent after readback hydration',
    (tester) async {
      const route = TenantAdminEventEditRoutePage(
        eventId: 'evt-42',
        occurrenceId: 'occ-2',
      );
      final event = _buildEvent(
        occurrences: <TenantAdminEventOccurrence>[
          TenantAdminEventOccurrence(
            occurrenceIdValue: tenantAdminOptionalText('occ-1'),
            dateTimeStartValue: tenantAdminDateTime(DateTime.utc(2026, 4, 20)),
          ),
          TenantAdminEventOccurrence(
            occurrenceIdValue: tenantAdminOptionalText('occ-2'),
            dateTimeStartValue: tenantAdminDateTime(DateTime.utc(2026, 4, 21)),
          ),
        ],
      );

      late Widget builtScreen;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              builtScreen = route.buildScreen(context, event);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(builtScreen, isA<TenantAdminEventFormScreen>());
      final formScreen = builtScreen as TenantAdminEventFormScreen;
      expect(formScreen.existingEvent, isNotNull);
      expect(formScreen.existingEvent!.occurrences.first.occurrenceId, 'occ-2');
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

TenantAdminEvent _buildEvent({
  required List<TenantAdminEventOccurrence> occurrences,
}) {
  return TenantAdminEvent(
    eventIdValue: tenantAdminRequiredText('evt-42'),
    slugValue: tenantAdminRequiredText('evento-teste'),
    titleValue: tenantAdminRequiredText('Evento teste'),
    contentValue: tenantAdminOptionalText('Conteudo'),
    type: TenantAdminEventType(
      nameValue: tenantAdminRequiredText('Show'),
      slugValue: tenantAdminRequiredText('show'),
    ),
    occurrences: occurrences,
    publication: TenantAdminEventPublication(
      statusValue: tenantAdminRequiredText('draft'),
    ),
  );
}
