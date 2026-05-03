import 'package:belluga_now/application/invites/invite_from_event_factory.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'build uses selected event occurrence id for share-code invite context',
    () {
      final event = EventDTO.fromJson({
        'id': '507f1f77bcf86cd799439011',
        'slug': 'evento-teste',
        'type': {
          'id': '507f1f77bcf86cd799439111',
          'name': 'Show',
          'slug': 'show',
        },
        'title': 'Evento Teste',
        'content': '<p>Bora?</p>',
        'location': 'Guarapari',
        'date_time_start': '2026-03-13T20:00:00Z',
        'occurrence_id': 'occ-second',
        'occurrences': [
          {
            'occurrence_id': 'occ-first',
            'date_time_start': '2026-03-13T20:00:00Z',
            'is_selected': false,
          },
          {
            'occurrence_id': 'occ-second',
            'date_time_start': '2026-03-14T20:00:00Z',
            'is_selected': true,
          },
        ],
      }).toDomain();

      final invite = InviteFromEventFactory.build(
        event: event,
        fallbackImageUri: Uri.parse('https://example.com/event.jpg'),
      );

      expect(invite.eventId, '507f1f77bcf86cd799439011');
      expect(invite.occurrenceId, 'occ-second');
    },
  );
}
