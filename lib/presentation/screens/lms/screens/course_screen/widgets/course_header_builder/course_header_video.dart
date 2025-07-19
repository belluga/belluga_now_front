import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/content_video_player.dart';

class CourseHeaderVideo extends StatefulWidget {
  final CourseItemModel courseItemModel;

  const CourseHeaderVideo({super.key, required this.courseItemModel});

  @override
  State<CourseHeaderVideo> createState() => _CourseHeaderVideoState();
}

class _CourseHeaderVideoState extends State<CourseHeaderVideo> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            ContentVideoPlayer(courseItemModel: widget.courseItemModel),
          ],
        ),
      ),
    );
  }
}
