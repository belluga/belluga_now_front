import 'package:flutter/rendering.dart';
import 'package:belluga_now/domain/notes/note_model.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/notes/note_dto.dart';
import 'package:belluga_now/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class NotesRepositoryContract {
  BackendContract get backend => GetIt.I.get<BackendContract>();

  final notesSteamValue = StreamValue<List<NoteModel>?>(defaultValue: null);

  Future<void> getNotes(String courseItemId) async {
    notesSteamValue.addValue(null);
    final List<NoteDTO> _notesRaw = await backend.getNotes(courseItemId);

    final _notes =
        _notesRaw.map((noteDto) => NoteModel.fromDTO(noteDto)).toList();

    _notes.sort((a, b) {
      if (a.position.value == null && b.position.value == null) {
        return 0;
      }

      final Duration? _a = a.position.value;
      final Duration? _b = b.position.value;

      if (_a == null && _b == null) {
        return 0;
      }

      if (_a == null) {
        return 1;
      }

      if (_b == null) {
        return -1;
      }

      return _a.compareTo(_b);
    });

    notesSteamValue.addValue(_notes);
  }

  Future<void> createNote({
    required String courseItemId,
    required String content,
    required Color color,
    Duration? position,
  }) async {
    await backend.createNote(
      color: color,
      courseItemId: courseItemId,
      content: content,
      position: position,
    );
    await getNotes(courseItemId);
  }

  Future<void> updateNote({
    required String id,
    required String courseItemId,
    required String content,
    required Color color,
    Duration? position,
  }) async {
    await backend.updateNote(
      id: id,
      color: color,
      courseItemId: courseItemId,
      content: content,
      position: position,
    );
    await getNotes(courseItemId);
  }

  Future<NoteModel?> getNote(
      {required String courseId, required String noteId}) async {
    final NoteDTO? _noteRaw =
        await backend.getNote(courseId: courseId, noteId: noteId);
    if (_noteRaw == null) {
      return null;
    }
    return NoteModel.fromDTO(_noteRaw);
  }

  Future<void> deleteNote(
      {required String courseId, required String noteId}) async {
    final NoteModel? _note = await getNote(
      courseId: courseId,
      noteId: noteId,
    );
    if (_note != null) {
      await backend.deleteNote(noteId);
      await getNotes(_note.courseItemId.value);
    }
  }
}
