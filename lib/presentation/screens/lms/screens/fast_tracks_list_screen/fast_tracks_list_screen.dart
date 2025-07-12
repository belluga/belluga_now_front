import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:unifast_portal/domain/courses/course_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/fast_tracks_list_screen/controllers/fast_tracks_list_screen_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/fast_tracks_list_screen/widgets/fast_tracks_categories_list.dart';
import 'package:get_it/get_it.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/fast_tracks_list_screen/widgets/fast_tracks_last_row.dart';
import 'package:unifast_portal/presentation/widgets/course_tracks_sliver.dart';

@RoutePage()
class FastTrackListScreen extends StatefulWidget {
  const FastTrackListScreen({super.key});

  @override
  State<FastTrackListScreen> createState() => _FastTrackListScreenState();
}

class _FastTrackListScreenState extends State<FastTrackListScreen> {
  late FastTracksListScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton(FastTracksListScreenController());
    _controller.getFastTracksCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Fast Tracks",
          maxLines: 2,
          style: TextTheme.of(context).titleMedium,
        ),
        automaticallyImplyLeading: true,
      ),
      body: CustomScrollView(
        slivers: [
          FastTracksCategoriesList(),
          FastTracksLastRow(),
          SliverPadding(
            padding: EdgeInsets.only(top: 16),
            sliver: StreamValueBuilder<List<CourseModel>>(
              onNullWidget: SliverToBoxAdapter(child: SizedBox.shrink()),
              streamValue: _controller.lastCreatedFastTracksStreamValue,
              builder: (context, fastTracks) {
                return CourseTracksSliver(fastTracks: fastTracks);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    GetIt.I.unregister<FastTracksListScreenController>();
  }
}
