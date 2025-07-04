import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/dashboard_items_summary.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/dashboard/controllers/my_courses_dashboard_controller.dart';
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
    GetIt.I.registerSingleton<MyCoursesDashboardController>(
      MyCoursesDashboardController(),
    );
    _controller = GetIt.I.get<MyCoursesDashboardController>();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: _controller.myCoursesSummaryStreamValue,
      onNullWidget: SizedBox.shrink(),
      builder: (context, asyncSnapshot) {
        return DashboardItemsSummary(
          title: "Estou Cursando",
          itemHeight: 150,
          itemsPerRow: 1.2,
          showAllLabel: "Ver todos",
          itemsBuilder: _itemsBuilder,
        );
      },
    );
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
