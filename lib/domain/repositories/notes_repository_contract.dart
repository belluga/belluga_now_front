import 'package:flutter/rendering.dart';
import 'package:unifast_portal/domain/notes/note_model.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/notes/note_dto.dart';
import 'package:unifast_portal/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class NotesRepositoryContract {
  BackendContract get backend => GetIt.I.get<BackendContract>();

  final notesSteamValue = StreamValue<List<NoteModel>?>(defaultValue: null);

  Future<void> getNotes(String courseItemId) async {
    notesSteamValue.addValue(null);
    final List<NoteDTO> _notesRaw = await backend.getNotes(courseItemId);

    print(_notesRaw);

    final _notes = _notesRaw
        .map((noteDto) => NoteModel.fromDTO(noteDto))
        .toList();

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

  Future<void> deleteNote(String id) async {
    await backend.deleteNote(id);
    await getNotes(id);
  }
}
