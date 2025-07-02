import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/dashboard_items_summary.dart';

class NextEventsDashboard extends StatefulWidget {
  const NextEventsDashboard({super.key});

  @override
  State<NextEventsDashboard> createState() => _NextEventsDashboardState();
}

class _NextEventsDashboardState extends State<NextEventsDashboard> {
  @override
  Widget build(BuildContext context) {
    return DashboardItemsSummary(
      title: "Próximos Eventos",
      itemsPerRow: 1.2,
      itemHeight: 90,
      showAllLabel: "Ver todos",
    );
  }
}
