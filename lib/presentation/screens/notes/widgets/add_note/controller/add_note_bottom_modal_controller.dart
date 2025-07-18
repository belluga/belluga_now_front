import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/domain/notes/note_model.dart';
import 'package:unifast_portal/domain/repositories/notes_repository_contract.dart';

class AddNoteBottomModalController {
  final CourseItemModel courseItemModel;
  final Duration? currentVideoPosition;
  final NoteModel? noteModel;

  AddNoteBottomModalController({
    required this.courseItemModel,
    this.currentVideoPosition,
    this.noteModel,
  }){
    if (noteModel != null) {
      noteContentTextController.text = noteModel!.content.value;
      colorSelectedStreamValue.addValue(noteModel!.color.value);
    }
  }

  final notesRepository = GetIt.I.get<NotesRepositoryContract>();

  final noteContentTextController = TextEditingController();

  final colorSelectedStreamValue = StreamValue<Color>(
    defaultValue: Colors.yellow.shade200,
  );

  final savingNoteStreamValue = StreamValue<bool>(defaultValue: false);

  void changeColor(Color color) => colorSelectedStreamValue.addValue(color);

  Future<void> saveNote() async {
    if (noteModel == null) {
      await _createNote();
    } else {
      await _updateNote();
    }
  }

  Future<void> _updateNote() async {}

  Future<void> _createNote() async {
    savingNoteStreamValue.addValue(true);   
    await notesRepository.createNote(
      courseItemId: courseItemModel.id.value,
      content: noteContentTextController.text,
      color: colorSelectedStreamValue.value,
      position: currentVideoPosition,
    );
    savingNoteStreamValue.addValue(false);
  }
}
