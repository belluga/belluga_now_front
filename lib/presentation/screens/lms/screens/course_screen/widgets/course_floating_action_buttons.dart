import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/enums/tab_content_type.dart';
import 'package:unifast_portal/presentation/screens/notes/widgets/add_note/add_note_bottom_modal.dart';

class CourseFloatingActionButtons extends StatefulWidget {
  const CourseFloatingActionButtons({super.key});

  @override
  State<CourseFloatingActionButtons> createState() => _CourseFloatingActionButtonsState();
}

class _CourseFloatingActionButtonsState extends State<CourseFloatingActionButtons> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TabContentType>(
      streamValue: _controller.tabContentTypeStreamValue,
      onNullWidget: SizedBox.shrink(),
      builder: (context, tabContentType) {
        if (tabContentType != TabContentType.notes) {
          return SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: _showNotesAddBottomSheet,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Icon(
            Icons.add_comment,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        );
      },
    );
  }

  void _showNotesAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddNoteBottomModal(
        courseItemModel: _controller.currentCourseItemStreamValue.value!,
        currentVideoPosition:
            _controller.contentVideoPlayerController.positionStreamValue.value,
      ),
    );
  }
}
