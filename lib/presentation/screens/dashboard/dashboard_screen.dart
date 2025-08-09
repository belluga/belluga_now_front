import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/courses/course_base_model.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/common/widgets/profile_action_button/profile_action_button.dart';
import 'package:belluga_now/presentation/screens/dashboard/controllers/my_courses_dashboard_controller.dart';
import 'package:belluga_now/presentation/screens/events/widgets/next_events_dashboard.dart';
import 'package:belluga_now/presentation/screens/dashboard/widgets/external_courses_dashboard/external_courses_dashboard.dart';
import 'package:belluga_now/presentation/screens/dashboard/widgets/my_courses_dashboard/my_courses_dashboard.dart';
import 'package:belluga_now/presentation/widgets/course_tracks_sliver.dart';

@RoutePage()
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late MyCoursesDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton<MyCoursesDashboardController>(
      MyCoursesDashboardController(),
    );
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MainLogo(),
        automaticallyImplyLeading: false,
        actions: [ProfileActionButton()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Comunidades',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: NextEventsDashboard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: MyCoursesDashboard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ExternalCoursesDashboard(),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 16),
            sliver: StreamValueBuilder<List<CourseBaseModel>>(
              onNullWidget: SliverToBoxAdapter(child: SizedBox.shrink()),
              streamValue: _controller.fastTracksItemsStreamValue,
              builder: (context, fastTracks) {
                return CourseTracksSliver(
                  showAllLabel: "Ver Todas",
                  onShowAllPressed: () =>
                      context.router.push(FastTrackListRoute()),
                  fastTracks: fastTracks,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
