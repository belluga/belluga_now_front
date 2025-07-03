import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/assets_constants.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/dashboard_items_summary.dart';

class ExternalCoursesDashboard extends StatefulWidget {
  const ExternalCoursesDashboard({super.key});

  @override
  State<ExternalCoursesDashboard> createState() =>
      _ExternalCoursesDashboardState();
}

class _ExternalCoursesDashboardState extends State<ExternalCoursesDashboard> {
  @override
  Widget build(BuildContext context) {
    return DashboardItemsSummary(
      title: "Cursos Externos",
      itemsPerRow: 1.1,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
              image: DecorationImage(
                image: Image.asset(AssetsConstants.login.headerArt).image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsetsGeometry.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Nome do Curso",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    "Nome do Expert",
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.link),
            ),
          ),
        ],
      ),
    );
  }
}
