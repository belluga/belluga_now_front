import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/domain/notes/note_model.dart';
import 'package:unifast_portal/presentation/common/widgets/button_loading.dart';
import 'package:unifast_portal/presentation/screens/notes/widgets/add_note/color_selector.dart';
import 'package:unifast_portal/presentation/screens/notes/widgets/add_note/controller/add_note_bottom_modal_controller.dart';

class AddNoteBottomModal extends StatefulWidget {
  final CourseItemModel courseItemModel;
  final Duration? currentVideoPosition;
  final NoteModel? noteModel;

  const AddNoteBottomModal({
    super.key,
    required this.courseItemModel,
    this.currentVideoPosition,
    this.noteModel,
  });

  @override
  State<AddNoteBottomModal> createState() => _AddNoteBottomModalState();
}

class _AddNoteBottomModalState extends State<AddNoteBottomModal> {
  late AddNoteBottomModalController _controller;

  @override
  void initState() {
    super.initState();

    _controller = GetIt.I.registerSingleton(
      AddNoteBottomModalController(
        courseItemModel: widget.courseItemModel,
        currentVideoPosition: widget.currentVideoPosition,
        noteModel: widget.noteModel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomInset),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.noteModel == null ? 'Adicionar nota' : "Editar nota",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StreamValueBuilder(
                      streamValue: _controller.colorSelectedStreamValue,
                      builder: (context, colorSelected) {
                        return ColorSelector(
                          colorOptions: [
                            Colors.yellow.shade200,
                            Colors.pink.shade100,
                            Colors.green.shade100,
                            Colors.blue.shade100,
                          ],
                          selectedColor: colorSelected,
                          onColorSelected: _controller.changeColor,
                        );
                      },
                    ),
                    SizedBox(width: 32),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: ButtonLoading(
                              onPressed: _saveNote,
                              loadingStatusStreamValue:
                                  _controller.savingNoteStreamValue,
                              label: 'Salvar',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamValueBuilder(
                  streamValue: _controller.colorSelectedStreamValue,
                  builder: (context, colorSelected) {
                    return Container(
                      decoration: BoxDecoration(
                        color: colorSelected,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextField(
                        controller: _controller.noteContentTextController,
                        maxLines: 5,
                        autofocus: widget.noteModel == null,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          color: Colors.black, // Ensures the font color is dark
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none, // Removes the border
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Digite sua nota...',
                          hintStyle: TextStyle(
                            color: Colors
                                .black54, // Hint text in a slightly lighter dark color
                          ),
                          contentPadding: EdgeInsets.all(
                            12.0,
                          ), // Adds padding inside the text area
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    await _controller.saveNote();
    _pop();
  }

  void _pop() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    super.dispose();
    GetIt.I.unregister<AddNoteBottomModalController>();
  }
}
