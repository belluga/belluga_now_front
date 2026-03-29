import 'package:belluga_now/domain/services/timezone_service_contract.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<TimezoneServiceContract>(
      _FakeTimezoneService(hoursOffset: -3),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('startDateTime projection uses timezone boundary service', () {
    final event = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439011',
      'slug': 'evento-local',
      'type': {
        'id': 'show',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show ao vivo',
      },
      'title': 'Noite Local',
      'content': 'Conteúdo',
      'location': 'Centro',
      'date_time_start': '2026-03-29T23:00:00Z',
      'date_time_end': '2026-03-30T01:00:00Z',
      'artists': const [
        {
          'id': '507f1f77bcf86cd799439012',
          'display_name': 'Artista 1',
          'avatar_url': null,
          'highlight': true,
          'genres': ['samba'],
        },
      ],
      'thumb': {
        'type': 'image',
        'data': {'url': 'https://tenant.test/evento.jpg'},
      },
    }).toDomain();

    final fallbackThumb = ThumbUriValue(
      defaultValue: Uri.parse('https://tenant.test/fallback.jpg'),
      isRequired: true,
    )..parse('https://tenant.test/fallback.jpg');

    final projection = VenueEventResume.fromScheduleEvent(event, fallbackThumb);

    expect(projection.startDateTime.hour, 20);
    expect(projection.startDateTime.day, 29);
  });
}

class _FakeTimezoneService implements TimezoneServiceContract {
  _FakeTimezoneService({required this.hoursOffset});

  final int hoursOffset;

  @override
  DateTime utcToLocal(DateTime value) {
    final baseUtc = value.isUtc ? value : value.toUtc();
    final shifted = baseUtc.add(Duration(hours: hoursOffset));
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  @override
  DateTime localToUtc(DateTime value) {
    final normalized = DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
    return DateTime.utc(
      normalized.year,
      normalized.month,
      normalized.day,
      normalized.hour,
      normalized.minute,
      normalized.second,
      normalized.millisecond,
      normalized.microsecond,
    ).subtract(Duration(hours: hoursOffset));
  }
}
