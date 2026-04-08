import 'package:belluga_now/presentation/tenant_public/widgets/upcoming_event_card.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'agenda card shows end day and time when event ends on another day',
      (tester) async {
    final event = buildVenueEventResume(
      id: 'event-1',
      slug: 'evento-longo',
      title: 'Evento Longo',
      imageUri: Uri.parse('https://tenant.test/media/event.png'),
      startDateTime: DateTime.utc(2026, 4, 1, 10, 0),
      endDateTime: DateTime.utc(2026, 4, 30, 10, 0),
      location: 'Carvoeiro',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpcomingEventCard.fromVenueEventResume(
            event: event,
            distanceLabel: '759 m',
          ),
        ),
      ),
    );

    expect(find.textContaining('01 • 07:00 -'), findsOneWidget);
    expect(find.textContaining('30 • 07:00'), findsOneWidget);
  });

  testWidgets('agenda card omits inferred end time when absent',
      (tester) async {
    final event = buildVenueEventResume(
      id: 'event-1',
      slug: 'evento-longo',
      title: 'Evento Longo',
      imageUri: Uri.parse('https://tenant.test/media/event.png'),
      startDateTime: DateTime.utc(2026, 4, 1, 10, 0),
      location: 'Carvoeiro',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpcomingEventCard.fromVenueEventResume(
            event: event,
            distanceLabel: '759 m',
          ),
        ),
      ),
    );

    expect(find.textContaining('07:00 -'), findsNothing);
    expect(find.textContaining('07:00'), findsOneWidget);
  });

  testWidgets(
      'agenda card shows only end time when explicit end stays on same day',
      (tester) async {
    final event = buildVenueEventResume(
      id: 'event-1',
      slug: 'evento-curto',
      title: 'Evento Curto',
      imageUri: Uri.parse('https://tenant.test/media/event.png'),
      startDateTime: DateTime.utc(2026, 4, 1, 10, 0),
      endDateTime: DateTime.utc(2026, 4, 1, 13, 0),
      location: 'Carvoeiro',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpcomingEventCard.fromVenueEventResume(
            event: event,
            distanceLabel: '759 m',
          ),
        ),
      ),
    );

    expect(find.textContaining('07:00 - 10:00'), findsOneWidget);
    expect(find.textContaining('01 • 07:00 - 01 • 10:00'), findsNothing);
  });
}
