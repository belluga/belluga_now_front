import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/enums/tab_content_type.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/course_floating_action_buttons.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/course_header_builder/course_header_builder.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/tabs/childrens_list.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/tabs/files_list.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/tabs/notes_list.dart';
import 'package:unifast_portal/presentation/screens/notes/widgets/add_note/add_note_bottom_modal.dart';

@RoutePage()
class CourseScreen extends StatefulWidget {
  final String courseItemId;

  const CourseScreen({
    super.key,
    @PathParam('courseItemId') required this.courseItemId,
  });

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen>
    with TickerProviderStateMixin {
  late CourseScreenController _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: StreamValueBuilder<CourseItemModel>(
        streamValue: _controller.currentCourseItemStreamValue,
        onNullWidget: Center(child: CircularProgressIndicator()),
        builder: (context, courseModel) {
          return Column(
            children: [
              Expanded(
                flex: 1,
                child: CourseHeaderBuilder(courseItemModel: courseModel),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceDim,
                  child: TabBar(
                    controller: _controller.tabController,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Theme.of(context).colorScheme.onPrimary,
                    tabs: List.generate(_controller.tabContentTypes.length, (
                      index,
                    ) {
                      final TabContentType contentType =
                          _controller.tabContentTypes[index];

                      switch (contentType) {
                        case TabContentType.childrens:
                          return Tab(
                            text: courseModel
                                .childrensSummary
                                ?.label
                                .valueFormated,
                          );
                        case TabContentType.files:
                          return Tab(text: 'Arquivos');
                        case TabContentType.notes:
                          return Tab(text: 'Anotações');
                      }
                    }),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TabBarView(
                    controller: _controller.tabController,
                    children: List.generate(
                      _controller.tabContentTypes.length,
                      (index) {
                        final TabContentType contentType =
                            _controller.tabContentTypes[index];

                        switch (contentType) {
                          case TabContentType.childrens:
                            return ChildrensList();
                          case TabContentType.files:
                            return FilesList();
                          case TabContentType.notes:
                            return NotesList();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: CourseFloatingActionButtons(
        onPressed: _showNotesAddBottomSheet,
      ),
    );
  }

  void _initializeController() {
    _controller = GetIt.I.registerSingleton<CourseScreenController>(
      CourseScreenController(vsync: this),
    );
    _controller.setCourse(widget.courseItemId);
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

  @override
  void dispose() {
    super.dispose();
    GetIt.I.unregister<CourseScreenController>();
  }
}
