import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/video_player.dart';

class CourseHeaderVideo extends StatelessWidget {
  const CourseHeaderVideo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(children: [VideoPlayer()]),
      ),
    );
  }
}
