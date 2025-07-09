import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/presentation/screens/lms/controllers/course_screen_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/widgets/course_header_builder/course_header_builder.dart';
import 'package:unifast_portal/presentation/screens/lms/widgets/tabs/childrens_list.dart';
import 'package:unifast_portal/presentation/screens/lms/widgets/tabs/files_list.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

@RoutePage()
class CourseScreen extends StatefulWidget {
  final CourseItemModel courseItemModel;

  const CourseScreen({super.key, required this.courseItemModel});

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
      body: Column(
        children: [
          // CourseHeaderBuilder(
          //   courseItemModel: widget.courseItemModel
          // ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              color: Theme.of(context).colorScheme.surfaceDim,
              child: StreamValueBuilder<CourseItemModel>(
                streamValue: _controller.currentCourseItemStreamValue,
                builder: (context, courseItem) {
                  return TabBar(
                    controller: _controller.tabController,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Theme.of(context).colorScheme.onPrimary,
                    tabs: [
                      if (courseItem.childrens.isNotEmpty)
                        Tab(
                          text: courseItem.childrensSummary.label.valueFormated,
                        ),
                      if (courseItem.files.isNotEmpty) Tab(text: 'Arquivos'),
                      // Tab(text: 'Anotações'),
                    ],
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: StreamValueBuilder<CourseItemModel>(
                streamValue: _controller.currentCourseItemStreamValue,
                builder: (context, courseItem) {
                  return TabBarView(
                    controller: _controller.tabController,
                    children: [
                      if (courseItem.childrens.isNotEmpty) ChildrensList(),
                      if (courseItem.files.isNotEmpty) FilesList(),
                      // Tab 3: Anotações (Placeholder)
                      // const Center(child: Text('Nenhuma anotação encontrada.')),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _initializeController() {
    print(GetIt.I.currentScopeName);
    final bool isRegistered = GetIt.I.isRegistered<CourseScreenController>(
      instance: GetIt.I.get<CourseScreenController>(),
    );

    if (!isRegistered) {
      _controller = GetIt.I.registerSingleton<CourseScreenController>(
        CourseScreenController(courseItemModel: widget.courseItemModel),
      );
    } else {
      _controller = GetIt.I.get<CourseScreenController>();
    }

    _controller.init(vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    GetIt.I.unregister<CourseScreenController>();
    bool _hasScopeForThisItem = GetIt.I.hasScope(
      widget.courseItemModel.id.toString(),
    );
    if (_hasScopeForThisItem) {
      GetIt.I.popScope();
    }
  }
}
