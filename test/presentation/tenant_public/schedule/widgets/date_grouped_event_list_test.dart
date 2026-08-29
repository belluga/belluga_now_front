import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_avatar_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_genre_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_id_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_is_highlight_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_name_value.dart';
import 'package:belluga_now/domain/services/timezone_service_contract.dart';
import 'package:belluga_now/domain/services/value_objects/timezone_service_contract_values.dart';
import 'package:belluga_now/domain/upcoming_ocurrence/projections/upcoming_ocurrence_resume.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/date_grouped_event_list.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

void main() {
  tearDown(() async {
    await GetIt.I.reset();
  });

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
            scaleDateHeaderToFit: true,
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
    'preserves the legacy date header layout unless scaling is opted in',
    (tester) async {
      final date = DateTime(2030, 8, 26);
      final event = buildUpcomingOcurrenceResume(
        id: '507f1f77bcf86cd799439097',
        slug: 'legacy-date-header',
        title: 'Evento com cabeçalho legado',
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
      expect(
        find.ancestor(of: labelFinder, matching: find.byType(FittedBox)),
        findsNothing,
      );

      final labelWidget = tester.widget<Text>(labelFinder);
      expect(labelWidget.maxLines, isNull);
      expect(labelWidget.softWrap, isNull);
    },
  );

  testWidgets(
    'groups by local calendar date and orders shuffled occurrences by start time',
    (tester) async {
      GetIt.I.registerSingleton<TimezoneServiceContract>(
        _FakeTimezoneService(hoursOffset: -3),
      );

      final firstLocalDate = DateTime(2026, 8, 24);
      final secondLocalDate = DateTime(2026, 8, 25);
      final firstDayLate = buildUpcomingOcurrenceResume(
        id: '507f1f77bcf86cd799439091',
        slug: 'first-day-late',
        title: 'Primeiro Dia Tarde',
        imageUri: Uri.parse('http://example.com/first-day.jpg'),
        startDateTime: DateTime.utc(2026, 8, 25, 2, 30),
        location: 'Campo do Buenos Aires',
        selectedOccurrenceId: '507f1f77bcf86cd799439191',
      );
      final secondDayLate = buildUpcomingOcurrenceResume(
        id: '507f1f77bcf86cd799439092',
        slug: 'second-day-late',
        title: 'Segundo Dia Tarde',
        imageUri: Uri.parse('http://example.com/second-day-late.jpg'),
        startDateTime: DateTime.utc(2026, 8, 25, 5, 30),
        location: 'Campo do Buenos Aires',
        selectedOccurrenceId: '507f1f77bcf86cd799439192',
      );
      final secondDayEarly = buildUpcomingOcurrenceResume(
        id: '507f1f77bcf86cd799439093',
        slug: 'second-day-early',
        title: 'Segundo Dia Cedo',
        imageUri: Uri.parse('http://example.com/second-day-early.jpg'),
        startDateTime: DateTime.utc(2026, 8, 25, 3, 30),
        location: 'Campo do Buenos Aires',
        selectedOccurrenceId: '507f1f77bcf86cd799439193',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DateGroupedEventList(
                events: [secondDayLate, firstDayLate, secondDayEarly],
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
        find.text(DateFormat.MMMMEEEEd().format(firstLocalDate).toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(DateFormat.MMMMEEEEd().format(secondLocalDate).toUpperCase()),
        findsOneWidget,
      );

      final firstDayTop = tester.getTopLeft(
        find.byKey(
          const ValueKey<String>(
            'date-grouped-event-card-occurrence:507f1f77bcf86cd799439191',
          ),
        ),
      );
      final secondDayEarlyTop = tester.getTopLeft(
        find.byKey(
          const ValueKey<String>(
            'date-grouped-event-card-occurrence:507f1f77bcf86cd799439193',
          ),
        ),
      );
      final secondDayLateTop = tester.getTopLeft(
        find.byKey(
          const ValueKey<String>(
            'date-grouped-event-card-occurrence:507f1f77bcf86cd799439192',
          ),
        ),
      );

      expect(firstDayTop.dy, lessThan(secondDayEarlyTop.dy));
      expect(secondDayEarlyTop.dy, lessThan(secondDayLateTop.dy));
    },
  );

  testWidgets(
    'orders equal-start occurrences by occurrence id deterministically',
    (tester) async {
      final sameStart = DateTime.utc(2030, 8, 26, 21);
      final third = buildUpcomingOcurrenceResume(
        id: '507f1f77bcf86cd799439103',
        slug: 'third-equal-start',
        title: 'Terceiro Horário Igual',
        imageUri: Uri.parse('http://example.com/third.jpg'),
        startDateTime: sameStart,
        location: 'Campo do Buenos Aires',
        selectedOccurrenceId: '507f1f77bcf86cd799439203',
      );
      final first = buildUpcomingOcurrenceResume(
        id: '507f1f77bcf86cd799439101',
        slug: 'first-equal-start',
        title: 'Primeiro Horário Igual',
        imageUri: Uri.parse('http://example.com/first.jpg'),
        startDateTime: sameStart,
        location: 'Campo do Buenos Aires',
        selectedOccurrenceId: '507f1f77bcf86cd799439201',
      );
      final second = buildUpcomingOcurrenceResume(
        id: '507f1f77bcf86cd799439102',
        slug: 'second-equal-start',
        title: 'Segundo Horário Igual',
        imageUri: Uri.parse('http://example.com/second.jpg'),
        startDateTime: sameStart,
        location: 'Campo do Buenos Aires',
        selectedOccurrenceId: '507f1f77bcf86cd799439202',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DateGroupedEventList(
                events: [third, first, second],
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

      final firstTop = tester.getTopLeft(
        find.byKey(
          const ValueKey<String>(
            'date-grouped-event-card-occurrence:507f1f77bcf86cd799439201',
          ),
        ),
      );
      final secondTop = tester.getTopLeft(
        find.byKey(
          const ValueKey<String>(
            'date-grouped-event-card-occurrence:507f1f77bcf86cd799439202',
          ),
        ),
      );
      final thirdTop = tester.getTopLeft(
        find.byKey(
          const ValueKey<String>(
            'date-grouped-event-card-occurrence:507f1f77bcf86cd799439203',
          ),
        ),
      );

      expect(firstTop.dy, lessThan(secondTop.dy));
      expect(secondTop.dy, lessThan(thirdTop.dy));
    },
  );

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

class _FakeTimezoneService implements TimezoneServiceContract {
  _FakeTimezoneService({required this.hoursOffset});

  final int hoursOffset;

  @override
  TimezoneServiceContractDateTimeValue utcToLocal(
    TimezoneServiceContractDateTimeValue value,
  ) {
    final raw = value.value;
    final baseUtc = raw.isUtc ? raw : raw.toUtc();
    final shifted = baseUtc.add(Duration(hours: hoursOffset));
    return timezoneServiceDateTime(
      DateTime(
        shifted.year,
        shifted.month,
        shifted.day,
        shifted.hour,
        shifted.minute,
        shifted.second,
        shifted.millisecond,
        shifted.microsecond,
      ),
      defaultValue: shifted,
    );
  }

  @override
  TimezoneServiceContractDateTimeValue localToUtc(
    TimezoneServiceContractDateTimeValue value,
  ) {
    final raw = value.value;
    final normalized = DateTime(
      raw.year,
      raw.month,
      raw.day,
      raw.hour - hoursOffset,
      raw.minute,
      raw.second,
      raw.millisecond,
      raw.microsecond,
    );
    return timezoneServiceDateTime(normalized.toUtc(), defaultValue: raw);
  }
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
