import 'package:belluga_now/presentation/tenant_public/widgets/date_grouped_event_list.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'highlights long-running event in AGORA section when endDateTime is in the future',
    (tester) async {
      final now = DateTime.now();
      final event = buildVenueEventResume(
        id: '507f1f77bcf86cd799439099',
        slug: 'ongoing-event',
        title: 'Evento em Andamento',
        imageUri: Uri.parse('http://example.com/event.jpg'),
        startDateTime: now.subtract(const Duration(hours: 20)),
        endDateTime: now.add(const Duration(hours: 6)),
        location: 'Centro',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateGroupedEventList(
              events: [event],
              highlightNowEvents: true,
              onEventSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('AGORA'), findsOneWidget);
      expect(find.text('Evento em Andamento'), findsOneWidget);
    },
  );
}
