import 'package:belluga_now/domain/notes/value_objects/note_content_value.dart';
import 'package:belluga_now/domain/notes/value_objects/note_position_value.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class NoteModel {
  final MongoIDValue? id;
  final MongoIDValue courseItemId;
  final NoteContentValue content;
  final ColorValue color;
  final NotePositionValue position;

  NoteModel({
    required this.id,
    required this.courseItemId,
    required this.content,
    required this.color,
    required this.position,
  });
}
