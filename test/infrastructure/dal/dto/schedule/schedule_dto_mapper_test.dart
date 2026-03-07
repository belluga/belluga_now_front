import 'package:belluga_now/infrastructure/dal/dto/mappers/artist_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_status_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/partner_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/schedule_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/thumb_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestScheduleDtoMapper
    with
        InviteDtoMapper,
        ThumbDtoMapper,
        ArtistDtoMapper,
        PartnerDtoMapper,
        InviteStatusDtoMapper,
        ScheduleDtoMapper {}

void main() {
  test('maps event when event type id is not a Mongo ObjectId', () {
    final mapper = _TestScheduleDtoMapper();
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439011',
      'slug': 'evento-1',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type description',
        'color': '#112233',
      },
      'title': 'Evento 1',
      'content': 'Conteudo',
      'location': {
        'mode': 'physical',
        'display_name': 'Praia do Morro',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-03T20:00:00+00:00',
      'artists': const [],
    });

    final event = mapper.mapEventDto(dto);

    expect(event.type.id.value, 'type-1');
    expect(event.coordinate, isNotNull);
  });
}
