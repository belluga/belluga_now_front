import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/course_header_builder/course_header_builder.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/tabs/childrens_list.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/tabs/files_list.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

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
      body: StreamValueBuilder<CourseItemModel>(
        streamValue: _controller.currentCourseItemStreamValue,
        onNullWidget: Center(child: CircularProgressIndicator()),
        builder: (context, courseModel) {
          return Column(
            children: [
              CourseHeaderBuilder(courseItemModel: courseModel),
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
                    tabs: [
                      if (courseModel.childrensSummary != null)
                        Tab(
                          text:
                              courseModel.childrensSummary!.label.valueFormated,
                        ),
                      if (courseModel.files.isNotEmpty) Tab(text: 'Arquivos'),
                      // Tab(text: 'Anotações'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TabBarView(
                    controller: _controller.tabController,
                    children: [
                      if (courseModel.childrens.isNotEmpty) ChildrensList(),
                      if (courseModel.files.isNotEmpty) FilesList(),
                      // Tab 3: Anotações (Placeholder)
                      // const Center(child: Text('Nenhuma anotação encontrada.')),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _initializeController() {
    _controller = GetIt.I.registerSingleton<CourseScreenController>(
      CourseScreenController(courseItemId: widget.courseItemId, vsync: this),
    );
  }

  @override
  void dispose() {
    super.dispose();
    GetIt.I.unregister<CourseScreenController>();
    GetIt.I.popScope();
  }
}
