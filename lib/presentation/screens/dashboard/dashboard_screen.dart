import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/main_logo.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/profile_action_button/profile_action_button.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/events/widgets/next_events_dashboard.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/external_courses/widgets/external_courses_dashboard.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/current_courses_dashboard.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/course_tracks_dashboard.dart';

@RoutePage()
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 2), () {
      _showSnackBar();
    });
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

  void _showSnackBar() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        padding: EdgeInsets.all(16),
        actions: [
          Icon(Icons.upload, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ],
        leading: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Documentos Pendentes",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              "Clique aqui e envie seus documentos de matrícula!",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),

        // duration: Duration(seconds: 2),
      ),
    );
  }
}
