import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/dashboard_title_row.dart';

class CourseTracksDashboard extends StatefulWidget {
  const CourseTracksDashboard({super.key});

  @override
  State<CourseTracksDashboard> createState() => _CourseTracksDashboardState();
}

class _CourseTracksDashboardState extends State<CourseTracksDashboard> {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: DashboardTitleRow(
              title: "Trilhas Unifast",
              showAllLabel: "Ver todas",
              onShowAllPressed: () {},
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 0.9,
                crossAxisCount: 3,
              ),
              itemBuilder: _itemsBuilder,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _itemsBuilder(BuildContext context, int index) {
    if (index >= 25) {
      return null;
    }

    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceDim,
      child: SizedBox(
        height: 200,
        child: Center(child: Text("Item ${index + 1}")),
      ),
    );
  }
}
