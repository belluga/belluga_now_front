import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_model.dart';
import 'package:unifast_portal/presentation/common/widgets/dashboard_items_summary.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:get_it/get_it.dart';
import 'package:unifast_portal/presentation/widgets/fast_track_card.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/fast_tracks_list_screen/controllers/fast_tracks_list_screen_controller.dart';

class FastTracksLastRow extends StatefulWidget {
  const FastTracksLastRow({super.key});

  @override
  State<FastTracksLastRow> createState() => _FastTracksLastRowState();
}

class _FastTracksLastRowState extends State<FastTracksLastRow> {
  final _controller = GetIt.I.get<FastTracksListScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.getlastCreatedFastTracks();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: StreamValueBuilder<List<CourseModel>>(
        streamValue: _controller.lastCreatedFastTracksStreamValue,
        onNullWidget: SizedBox.shrink(),
        builder: (context, myCourseSuummary) {
          return DashboardItemsSummary(
            title: "Novidades",
            itemHeight: 150,
            itemsPerRow: 2.3,
            itemsBuilder: _itemsBuilder,
          );
        },
      ),
    );
  }

  Widget? _itemsBuilder(BuildContext context, int index) {
    final _fastTracks = _controller.lastCreatedFastTracksStreamValue.value!;

    if(index >= _fastTracks.length) {
      return null;
    }

    final _course = _fastTracks[index];

    return FastTrackCard( courseModel: _course);
  }
}
