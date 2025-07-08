import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/controllers/course_screen_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/course_header_builder/course_header_banner.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/course_header_builder/course_header_html.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/course_header_builder/course_header_video.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/main.dart';

class CourseHeaderBuilder extends StatefulWidget {
  const CourseHeaderBuilder({super.key});

  @override
  State<CourseHeaderBuilder> createState() => _CourseHeaderBuilderState();
}

class _CourseHeaderBuilderState extends State<CourseHeaderBuilder> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: _controller.currentCourseItemStreamValue,
      builder: (context, courseItem) {
        if (courseItem.hasVideoContent) {
          return CourseHeaderVideo();
        }

        if (courseItem.hasHtmlContent) {
          return CourseHeaderHtml();
        }

        return CourseHeaderBanner();
      },
    );
  }
}
