import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:unifast_portal/presentation/common/widgets/main_logo.dart';
import 'package:unifast_portal/presentation/common/widgets/profile_action_button/profile_action_button.dart';
import 'package:unifast_portal/presentation/screens/events/widgets/next_events_dashboard.dart';
import 'package:unifast_portal/presentation/screens/dashboard/widgets/external_courses_dashboard/external_courses_dashboard.dart';
import 'package:unifast_portal/presentation/screens/dashboard/widgets/my_courses_dashboard/my_courses_dashboard.dart';
import 'package:unifast_portal/presentation/screens/lms/widgets/course_tracks_dashboard.dart';

@RoutePage()
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
          CourseTracksDashboard(),
        ],
      ),
    );
  }
}
