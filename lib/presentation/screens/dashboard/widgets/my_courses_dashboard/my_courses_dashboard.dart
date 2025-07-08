import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.gr.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/dashboard_items_summary.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/dashboard/controllers/my_courses_dashboard_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/dashboard/view_models/courses_summary.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/dashboard/widgets/my_courses_dashboard/my_course_card.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:get_it/get_it.dart';

class MyCoursesDashboard extends StatefulWidget {
  const MyCoursesDashboard({super.key});

  @override
  State<MyCoursesDashboard> createState() => _MyCoursesDashboardState();
}

class _MyCoursesDashboardState extends State<MyCoursesDashboard> {
  late MyCoursesDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton<MyCoursesDashboardController>(
      MyCoursesDashboardController(),
    );
    _controller.init();
  }

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

    return MyCourseCard(course: _course);
  }
}
