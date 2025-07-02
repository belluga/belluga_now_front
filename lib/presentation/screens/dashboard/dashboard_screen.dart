import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/main_logo.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/profile_action_button/profile_action_button.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/documents/widgets/pending_documents_dashboard.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/events/widgets/next_events_dashboard.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/external_courses/widgets/external_courses_dashboard.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/current_courses_dashboard.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/course_tracks_dashboard.dart';

@RoutePage()
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
          PinnedHeaderSliver(child: PendingDocumentsDashboard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: NextEventsDashboard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: CurrentCoursesDashboard(),
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
      // body: Column(
      //   mainAxisSize: MainAxisSize.min,
      //   crossAxisAlignment: CrossAxisAlignment.stretch,
      //   children: [
      //     Expanded(
      //       child: SingleChildScrollView(
      //         child: Column(
      //           spacing: 16,
      //           mainAxisSize: MainAxisSize.min,
      //           crossAxisAlignment: CrossAxisAlignment.stretch,
      //           children: [
      //             PendingDocumentsDashboard(),
      //             NextEventsDashboard(),
      //             CurrentCoursesDashboard(),
      //             ExternalCoursesDashboard(),
      //             Expanded(child: CourseTracksDashboard()),
      //           ],
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}
