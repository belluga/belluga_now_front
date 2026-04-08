import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_avatar_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_genre_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_id_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_is_highlight_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_name_value.dart';
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
