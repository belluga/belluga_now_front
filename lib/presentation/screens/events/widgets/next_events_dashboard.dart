import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/common/widgets/calendar_box.dart';
import 'package:belluga_now/presentation/common/widgets/dashboard_items_summary.dart';

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
      // itemHeight: 90,
      showAllLabel: "Ver todos",
      itemsBuilder: _itemsBuilder,
    );
  }

  Widget? _itemsBuilder(BuildContext context, int index) {
    if (index >= 25) {
      return null;
    }

    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceDim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            CalendarBox(day: 17, month: "janeiro"),
            SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Webinar", style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    "Descrição do evento ${index + 1}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Nome do Curso/Expert",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
