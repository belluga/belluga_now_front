import 'package:belluga_now/domain/notes/note_model.dart';
import 'package:belluga_now/domain/notes/value_objects/note_content_value.dart';
import 'package:belluga_now/domain/notes/value_objects/note_position_value.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/notes/note_dto.dart';
import 'package:flutter/material.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

mixin NotesDtoMapper {
  NoteModel mapNote(NoteDTO dto) {
    return NoteModel(
      id: MongoIDValue()..tryParse(dto.id),
      courseItemId: MongoIDValue()..parse(dto.courseItemId),
      content: NoteContentValue(defaultValue: '')..parse(dto.content),
      color: ColorValue(defaultValue: Colors.amber)..tryParse(dto.colorHex),
      position: NotePositionValue()..tryParse(dto.position),
    );
  }
}
