import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/my_events_carousel_card.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home event card shows explicit end time when provided',
      (tester) async {
    final event = buildVenueEventResume(
      id: 'event-1',
      slug: 'event-1',
      title: 'Evento Longo',
      imageUri: Uri.parse('https://tenant.test/media/event.png'),
      startDateTime: DateTime.utc(2026, 4, 1, 10, 0),
      endDateTime: DateTime.utc(2026, 4, 1, 13, 0),
      location: 'Carvoeiro',
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(360, 800)),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: MyEventsCarouselCard(
                event: event,
                isConfirmed: true,
                pendingInvitesCount: 0,
                distanceLabel: '760m',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('07:00 - 10:00'), findsOneWidget);
  });

  testWidgets('home event card does not show inferred end time',
      (tester) async {
    final event = buildVenueEventResume(
      id: 'event-1',
      slug: 'event-1',
      title: 'Evento Longo',
      imageUri: Uri.parse('https://tenant.test/media/event.png'),
      startDateTime: DateTime.utc(2026, 4, 1, 10, 0),
      location: 'Carvoeiro',
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(360, 800)),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: MyEventsCarouselCard(
                event: event,
                isConfirmed: true,
                pendingInvitesCount: 0,
                distanceLabel: '760m',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('07:00 - 10:00'), findsNothing);
    expect(find.textContaining('07:00'), findsOneWidget);
  });
}
