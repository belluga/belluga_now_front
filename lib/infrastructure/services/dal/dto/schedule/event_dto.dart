import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_artist_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_actions_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_type_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/thumb_dto.dart';

class EventDTO {
  const EventDTO({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    this.latitude,
    this.longitude,
    this.thumb,
    required this.dateTimeStart,
    this.dateTimeEnd,
    required this.artists,
    required this.actions,
  });

  final String id;
  final EventTypeDTO type;
  final String title;
  final String? content;
  final String location;
  final double? latitude;
  final double? longitude;
  final ThumbDTO? thumb;
  final String dateTimeStart;
  final String? dateTimeEnd;
  final List<EventArtistDTO> artists;
  final List<EventActionsDTO> actions;
}
