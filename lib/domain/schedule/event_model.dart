import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/schedule/event_artist_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_dto.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class EventModel {
  final MongoIDValue id;
  final EventTypeModel type;
  final TitleValue title;
  final HTMLContentValue content;
  final DescriptionValue location;
  final ThumbModel? thumb;
  final DateTimeValue dateTimeStart;
  final DateTimeValue? dateTimeEnd;
  final List<EventArtistModel> artists;
  final List<EventActionModel> actions;
  final CityCoordinate? coordinate;

  EventModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    required this.thumb,
    required this.dateTimeStart,
    required this.dateTimeEnd,
    required this.artists,
    required this.actions,
    required this.coordinate,
  });

  factory EventModel.fromDTO(EventDTO dto) {
    return EventModel(
      id: MongoIDValue()..tryParse(dto.id),
      type: EventTypeModel.fromDTO(dto.type),
      title: TitleValue()..parse(dto.title),
      content: HTMLContentValue()..parse(dto.content),
      location: DescriptionValue()..parse(dto.location),
      thumb: dto.thumb != null ? ThumbModel.fromDTO(dto.thumb!) : null,
      dateTimeStart: DateTimeValue()..parse(dto.dateTimeStart),
      dateTimeEnd: dto.dateTimeEnd != null
          ? (DateTimeValue()..parse(dto.dateTimeEnd!))
          : null,
      artists: dto.artists.map(EventArtistModel.fromDTO).toList(),
      actions: dto.actions.map((e) => EventActionModel.fromDTO(e)).toList(),
      coordinate: (dto.latitude != null && dto.longitude != null)
          ? CityCoordinate(
              latitude: dto.latitude!,
              longitude: dto.longitude!,
            )
          : null,
    );
  }
}
