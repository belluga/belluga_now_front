import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/notes/note_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/note_card.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/empty_list.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class NotesList extends StatefulWidget {

  final void Function({NoteModel? noteModel}) onCardTap;

  const NotesList({super.key, required this.onCardTap});

  @override
  State<NotesList> createState() => _NotesListState();
}

class _NotesListState extends State<NotesList> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.getNotes();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<NoteModel>>(
      streamValue: _controller.notesStreamValue,
      onNullWidget: Center(child: CircularProgressIndicator()),
      builder: (context, notesList) {
        if (notesList.isEmpty) {
          return EmptyListMessage();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              notesList.length,
              (index) => NoteCard(
                onCardTap: widget.onCardTap,
                noteModel: notesList[index], index: index),
            ),
          ),
        );
      },
    );
  }
}
