import 'package:belluga_now/infrastructure/services/dal/dto/course/teacher_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_actions_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_type_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/thumb_dto.dart';

class EventDTO {
  const EventDTO({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.thumb,
    required this.dateTimeStart,
    required this.teachers,
    required this.actions,
  });

  final String id;
  final EventTypeDTO type;
  final String title;
  final String? content;
  final ThumbDTO? thumb;
  final String dateTimeStart;
  final List<TeacherDTO> teachers;
  final List<EventActionsDTO> actions;
}
