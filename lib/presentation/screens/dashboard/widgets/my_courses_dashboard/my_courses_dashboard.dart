import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:unifast_portal/application/router/app_router.gr.dart';
import 'package:unifast_portal/presentation/common/widgets/dashboard_items_summary.dart';
import 'package:unifast_portal/presentation/screens/dashboard/controllers/my_courses_dashboard_controller.dart';
import 'package:unifast_portal/presentation/screens/dashboard/view_models/courses_summary.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:get_it/get_it.dart';
import 'package:unifast_portal/presentation/screens/lms/widgets/course_row_card.dart';

class MyCoursesDashboard extends StatefulWidget {
  const MyCoursesDashboard({super.key});

  @override
  State<MyCoursesDashboard> createState() => _MyCoursesDashboardState();
}

class _MyCoursesDashboardState extends State<MyCoursesDashboard> {
  final _controller = GetIt.I.get<MyCoursesDashboardController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<CoursesSummary>(
      streamValue: _controller.myCoursesSummaryStreamValue,
      onNullWidget: SizedBox.shrink(),
      builder: (context, myCourseSuummary) {
        final _showInScreen = myCourseSuummary.total == 1 ? 1.1 : 1.3;

        return DashboardItemsSummary(
          title: "Meus Cursos",
          itemHeight: 150,
          itemsPerRow: _showInScreen,
          showAllLabel: "Ver todos",
          onShowAllPressed: _navigateToAllCourses,
          itemsBuilder: _itemsBuilder,
        );
      },
    );
  }

  void _navigateToAllCourses() {
    context.router.push(CoursesListRoute());
  }

  Widget? _itemsBuilder(BuildContext context, int index) {
    final _myCoursesSummary = _controller.myCoursesSummaryStreamValue.value!;

    if (index >= _myCoursesSummary.items.length) {
      return null;
    }

    final _course = _myCoursesSummary.items[index];

    return CourseRowCard(
      onNavigateToCourse: () {
        context.router.push(CourseRoute(courseItemId: _course.id.value));
      },
      course: _course,
    );
  }
}
