import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:unifast_portal/presentation/common/widgets/dashboard_title_row.dart';
import 'package:unifast_portal/presentation/screens/dashboard/controllers/fast_tracks_dashboard_controller.dart';
import 'package:unifast_portal/presentation/screens/dashboard/view_models/courses_summary.dart';
import 'package:unifast_portal/presentation/screens/dashboard/widgets/fast_track_dashboard.dart/fast_track_card.dart';

class CourseTracksDashboard extends StatefulWidget {
  const CourseTracksDashboard({super.key});

  @override
  State<CourseTracksDashboard> createState() => _CourseTracksDashboardState();
}

class _CourseTracksDashboardState extends State<CourseTracksDashboard> {
  late FastTracksDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton(FastTracksDashboardController());
    _controller.init();
  }

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
            sliver: StreamValueBuilder<CoursesSummary>(
              streamValue: _controller.myCoursesSummaryStreamValue,
              onNullWidget: SliverToBoxAdapter(
                child: const Center(child: CircularProgressIndicator()),
              ),
              builder: (context, coursesSummary) {
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: 0.9,
                    crossAxisCount: 3,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    if (index >= coursesSummary.items.length) {
                      return null;
                    }

                    final _fastTrack = coursesSummary.items[index];

                    return FastTrackCard(courseModel: _fastTrack);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
