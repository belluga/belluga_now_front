import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/dashboard_items_summary.dart';

class CurrentCoursesDashboard extends StatefulWidget {
  const CurrentCoursesDashboard({super.key});

  @override
  State<CurrentCoursesDashboard> createState() => _CurrentCoursesDashboardState();
}

class _CurrentCoursesDashboardState extends State<CurrentCoursesDashboard> {
  @override
  Widget build(BuildContext context) {
    return DashboardItemsSummary(
      title: "Estou Cursando",
      itemHeight: 120,
      showAllLabel: "Ver todos",
    );
  }
}
