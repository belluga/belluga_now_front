import 'package:belluga_now/domain/courses/teacher_model.dart';
import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_dto.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class EventModel {
  final MongoIDValue id;
  final EventTypeModel type;
  final TitleValue title;
  final HTMLContentValue content;
  final ThumbModel? thumb;
  final DateTimeValue dateTimeStart;
  final List<TeacherModel> teachers;
  final List<EventActionModel> actions;

  EventModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.thumb,
    required this.dateTimeStart,
    required this.teachers,
    required this.actions,
  });

  factory EventModel.fromDTO(EventDTO dto) {
    return EventModel(
      id: MongoIDValue()..tryParse(dto.id),
      type: EventTypeModel.fromDTO(dto.type),
      title: TitleValue()..parse(dto.title),
      content: HTMLContentValue()..parse(dto.content),
      thumb: dto.thumb != null ? ThumbModel.fromDTO(dto.thumb!) : null,
      dateTimeStart: DateTimeValue()..parse(dto.dateTimeStart),
      teachers: dto.teachers.map((e) => TeacherModel.fromDTO(e)).toList(),
      actions: dto.actions.map((e) => EventActionModel.fromDTO(e)).toList(),
    );
  }
}
