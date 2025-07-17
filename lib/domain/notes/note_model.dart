import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/notes/value_objects/note_content_value.dart';
import 'package:unifast_portal/domain/notes/value_objects/note_title_value.dart';
import 'package:unifast_portal/domain/value_objects/color_value.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/notes/note_dto.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class NoteModel {
  final MongoIDValue id;
  final NoteTitleValue title;
  final NoteContentValue content;
  final ColorValue color;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
  });

  factory NoteModel.fromDto(NoteDTO dto) {
    final _id = MongoIDValue()..parse(dto.id);
    final _title = NoteTitleValue()..tryParse(dto.title);
    final _content = NoteContentValue(defaultValue: "")..parse(dto.content);
    final _color = ColorValue(defaultValue: Colors.amber)
      ..tryParse(dto.colorHex);

    return NoteModel(
      id: _id,
      title: _title,
      content: _content,
      color: _color,
    );
  }
}