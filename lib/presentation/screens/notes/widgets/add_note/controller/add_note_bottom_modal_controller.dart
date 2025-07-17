import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/domain/notes/note_model.dart';

class AddNoteBottomModalController {

  final CourseItemModel courseItemModel;
  final Duration? currentVideoPosition;
  final NoteModel? noteModel; 

  AddNoteBottomModalController({
    required this.courseItemModel,
    this.currentVideoPosition,
    this.noteModel,
  });

  final noteContentTextController = TextEditingController();

  final colorSelectedStreamValue = StreamValue<Color>(
    defaultValue: Colors.yellow.shade200,
  );

  void changeColor(Color color) {
    colorSelectedStreamValue.addValue(colorSelectedStreamValue.value);
  }

  void saveNote() {
    if(noteModel == null) {
      _createNote();
    } else {
      _updateNote();
    } 
  }

  void _updateNote(){

  }

  void _createNote(){

  }
}
