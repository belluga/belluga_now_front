import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/schedule/event_artist_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
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

}
