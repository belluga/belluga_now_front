import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/dashboard_items_summary.dart';

class ExternalCoursesDashboard extends StatefulWidget {
  const ExternalCoursesDashboard({super.key});

  @override
  State<ExternalCoursesDashboard> createState() => _ExternalCoursesDashboardState();
}

class _ExternalCoursesDashboardState extends State<ExternalCoursesDashboard> {
  @override
  Widget build(BuildContext context) {
    return DashboardItemsSummary(
      title: "Cursos Externos",
      itemsPerRow: 1.1,
      showAllLabel: "Ver todos",
    );
  }
}
