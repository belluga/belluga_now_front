import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('event Sobre renderer receives preserved rich html from API DTO',
      (tester) async {
    final event = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439011',
      'slug': 'evt-rich',
      'type': {
        'id': 'show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Evento com HTML rico',
      'content': '<h2>Event Rich Heading 🎉</h2>'
          '<p><strong>Bold event</strong><br />Second event line</p>'
          '<p><em>Italic event</em> and <s>strike event</s></p>'
          '<blockquote>Event quote</blockquote>'
          '<ul><li>Event bullet</li></ul>'
          '<ol><li>Event ordered</li></ol>',
      'location': 'Carvoeiro',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': const [],
    }).toDomain();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventInfoSection(event: event),
        ),
      ),
    );

    expect(find.text('Sobre'), findsOneWidget);
    expect(find.byType(Html), findsOneWidget);

    final htmlWidget = tester.widget<Html>(find.byType(Html));
    expect(htmlWidget.data, contains('<h2>Event Rich Heading 🎉</h2>'));
    expect(htmlWidget.data, contains('<strong>Bold event</strong>'));
    expect(htmlWidget.data, contains('<br'));
    expect(htmlWidget.data, contains('<em>Italic event</em>'));
    expect(htmlWidget.data, contains('<s>strike event</s>'));
    expect(
      htmlWidget.data,
      contains('<blockquote>Event quote</blockquote>'),
    );
    expect(htmlWidget.data, contains('<ul><li>Event bullet</li></ul>'));
    expect(htmlWidget.data, contains('<ol><li>Event ordered</li></ol>'));
  });
}
