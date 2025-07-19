import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/domain/notes/note_model.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';

class NoteCard extends StatefulWidget {
  final NoteModel noteModel;
  final void Function({NoteModel? noteModel}) onCardTap;
  final int index;

  const NoteCard({
    super.key,
    required this.noteModel,
    required this.onCardTap,
    required this.index,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => widget.onCardTap(noteModel: widget.noteModel),
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
                        const SizedBox(width: 24),
                        if (widget.noteModel.position.value != null)
                          InkWell(
                            onTap: _navigateToVideoPosition,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: .0,
                              ),
                              child: Text(
                                widget.noteModel.position.valueFormated,
                              ),
                            ),
                          ),
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

  void _navigateToVideoPosition() {
    final Duration? _position = widget.noteModel.position.value;

    if (_position != null) {
      final Duration _seekTo = _position - Duration(seconds: 5);
      _controller.contentVideoPlayerController.videoPlayerController.seekTo(
        _seekTo,
      );
      _controller.contentVideoPlayerController.videoPlayerController.play();
    }
  }
}
