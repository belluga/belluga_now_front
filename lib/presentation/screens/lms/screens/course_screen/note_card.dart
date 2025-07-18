import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/notes/note_model.dart';

class NoteCard extends StatefulWidget {
  final NoteModel noteModel;
  final int index;

  const NoteCard({super.key, required this.noteModel, required this.index});

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        child: IntrinsicHeight(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceDim,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: widget.noteModel.color.value,
                        width: 32,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.noteModel.content.value,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.noteModel.position.value != null)
                          Text(widget.noteModel.position.valueFormated),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
