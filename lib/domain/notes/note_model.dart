import 'package:flutter/material.dart';
import 'package:belluga_now/domain/notes/value_objects/note_content_value.dart';
import 'package:belluga_now/domain/notes/value_objects/note_position_value.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/notes/note_dto.dart';
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

  factory NoteModel.fromDTO(NoteDTO dto) {
    final _id = MongoIDValue()..tryParse(dto.id);
    final _courseItemId = MongoIDValue()..parse(dto.courseItemId);
    final _content = NoteContentValue(defaultValue: "")..parse(dto.content);
    final _color = ColorValue(defaultValue: Colors.amber)
      ..tryParse(dto.colorHex);

    final _position = NotePositionValue()..tryParse(dto.position);

    return NoteModel(
      id: _id,
      courseItemId: _courseItemId,
      content: _content,
      color: _color,
      position: _position,
    );
  }
}
