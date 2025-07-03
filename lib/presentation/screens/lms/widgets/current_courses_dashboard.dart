import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/assets_constants.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/dashboard_items_summary.dart';

class CurrentCoursesDashboard extends StatefulWidget {
  const CurrentCoursesDashboard({super.key});

  @override
  State<CurrentCoursesDashboard> createState() =>
      _CurrentCoursesDashboardState();
}

class _CurrentCoursesDashboardState extends State<CurrentCoursesDashboard> {
  @override
  Widget build(BuildContext context) {
    return DashboardItemsSummary(
      title: "Estou Cursando",
      itemHeight: 150,
      itemsPerRow: 1.2,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimaryContainer,
                            padding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color:
                                    Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Continuar",
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
