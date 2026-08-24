import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_avatar_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_genre_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_id_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_is_highlight_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_name_value.dart';
import 'package:belluga_now/domain/upcoming_ocurrence/projections/upcoming_ocurrence_resume.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/date_grouped_event_list.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets('keeps the full date header visible on a mobile-width viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final date = DateTime(2030, 8, 26);
    final event = buildUpcomingOcurrenceResume(
      id: '507f1f77bcf86cd799439098',
      slug: 'mobile-date-header',
      title: 'Evento com cabeçalho de data',
      imageUri: Uri.parse('http://example.com/event.jpg'),
      startDateTime: date.add(const Duration(hours: 18)),
      location: 'Campo do Buenos Aires',
      venueTitle: 'Carvoeiro',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DateGroupedEventList(
            events: [event],
            onEventSelected: (_) {},
            primary: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ),
      ),
    );
    await tester.pump();

    final label = DateFormat.MMMMEEEEd().format(date).toUpperCase();
    final labelFinder = find.text(label);
    expect(labelFinder, findsOneWidget);

    final labelWidget = tester.widget<Text>(labelFinder);
    expect(labelWidget.maxLines, 1);
    expect(labelWidget.overflow, isNot(TextOverflow.ellipsis));
    expect(labelWidget.softWrap, isFalse);
    final labelRect = tester.getRect(labelFinder);
    expect(labelRect.left, greaterThanOrEqualTo(0));
    expect(labelRect.right, lessThanOrEqualTo(390));
  });

  testWidgets(
    'highlights long-running event in AGORA section when endDateTime is in the future',
    (tester) async {
      final now = DateTime.now();
      final event = buildUpcomingOcurrenceResume(
        id: '507f1f77bcf86cd799439099',
        slug: 'ongoing-event',
        title: 'Evento em Andamento',
        imageUri: Uri.parse('http://example.com/event.jpg'),
        startDateTime: now.subtract(const Duration(hours: 20)),
        endDateTime: now.add(const Duration(hours: 6)),
        location: 'Av. Beira Mar, 4500',
        venueTitle: 'Carvoeiro',
        artists: [
          _buildArtist(
            id: '507f1f77bcf86cd799439111',
            name: 'Ananda Torres',
            avatarUrl: 'http://example.com/ananda.jpg',
          ),
        ],
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
      expect(find.text('Ananda Torres'), findsOneWidget);
      expect(find.text('Carvoeiro - Av. Beira Mar, 4500'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps occurrence-first card identity when the same event appears on multiple dates',
    (tester) async {
      final eventId = '507f1f77bcf86cd799439099';
      final baseDate = DateTime(2026, 5, 15, 18);
      final events = <UpcomingOcurrenceResume>[
        buildUpcomingOcurrenceResume(
          id: eventId,
          slug: 'festa-da-imigracao-italiana',
          title: '5 ª Festa da Imigração Italiana',
          imageUri: Uri.parse('http://example.com/event.jpg'),
          startDateTime: baseDate,
          location: 'Campo do Buenos Aires',
          selectedOccurrenceId: '69dd8398d698348015047b62',
        ),
        buildUpcomingOcurrenceResume(
          id: eventId,
          slug: 'festa-da-imigracao-italiana',
          title: '5 ª Festa da Imigração Italiana',
          imageUri: Uri.parse('http://example.com/event.jpg'),
          startDateTime: baseDate.add(const Duration(days: 1)),
          location: 'Campo do Buenos Aires',
          selectedOccurrenceId: '69ee1dafb70a4bcfef05e979',
        ),
        buildUpcomingOcurrenceResume(
          id: eventId,
          slug: 'festa-da-imigracao-italiana',
          title: '5 ª Festa da Imigração Italiana',
          imageUri: Uri.parse('http://example.com/event.jpg'),
          startDateTime: baseDate.add(const Duration(days: 2)),
          location: 'Campo do Buenos Aires',
          selectedOccurrenceId: '69ee1f37b861740a340d94d0',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DateGroupedEventList(
                events: events,
                onEventSelected: (_) {},
                primary: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>(
            'date-grouped-event-card-occurrence:69dd8398d698348015047b62',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'date-grouped-event-card-occurrence:69ee1dafb70a4bcfef05e979',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'date-grouped-event-card-occurrence:69ee1f37b861740a340d94d0',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(DateFormat.MMMMEEEEd().format(baseDate).toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(
          DateFormat.MMMMEEEEd()
              .format(baseDate.add(const Duration(days: 1)))
              .toUpperCase(),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          DateFormat.MMMMEEEEd()
              .format(baseDate.add(const Duration(days: 2)))
              .toUpperCase(),
        ),
        findsOneWidget,
      );
    },
  );
}

ArtistResume _buildArtist({
  required String id,
  required String name,
  String? avatarUrl,
}) {
  final avatarValue = ArtistAvatarValue();
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    avatarValue.parse(avatarUrl);
  }
  return ArtistResume(
    idValue: ArtistIdValue()..parse(id),
    nameValue: ArtistNameValue()..parse(name),
    avatarValue: avatarValue,
    isHighlightValue: ArtistIsHighlightValue()..parse('false'),
    genreValues: const <ArtistGenreValue>[],
  );
}
