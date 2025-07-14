import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_base_model.dart';
import 'package:unifast_portal/presentation/common/widgets/dashboard_title_row.dart';
import 'package:unifast_portal/presentation/widgets/fast_track_card.dart';

class CourseTracksSliver extends StatelessWidget {
  final String? showAllLabel;
  final void Function()? onShowAllPressed;

  final List<CourseBaseModel> fastTracks;

  const CourseTracksSliver({
    super.key,
    required this.fastTracks,
    this.showAllLabel,
    this.onShowAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: DashboardTitleRow(
            title: "Trilhas Unifast",
            showAllLabel: showAllLabel,
            onShowAllPressed: onShowAllPressed,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 0.9,
              crossAxisCount: 2,
            ),
            itemBuilder: (BuildContext context, int index) {
              if (index >= fastTracks.length) {
                return null;
              }

              final _fastTrack = fastTracks[index];

              return FastTrackCard(courseModel: _fastTrack);
            },
          ),
        ),
      ],
    );
  }
}
