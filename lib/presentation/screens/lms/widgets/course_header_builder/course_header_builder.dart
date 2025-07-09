import 'package:flutter/material.dart';
import 'package:unifast_portal/domain/courses/course_content_model.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/presentation/screens/lms/widgets/course_header_builder/course_header_banner.dart';
import 'package:unifast_portal/presentation/screens/lms/widgets/course_header_builder/course_header_html.dart';
import 'package:unifast_portal/presentation/screens/lms/widgets/course_header_builder/course_header_video.dart';

class CourseHeaderBuilder extends StatefulWidget {
  final CourseItemModel courseItemModel;

  const CourseHeaderBuilder({super.key, required this.courseItemModel});

  @override
  State<CourseHeaderBuilder> createState() => _CourseHeaderBuilderState();
}

class _CourseHeaderBuilderState extends State<CourseHeaderBuilder> {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final CourseContentModel? _content = widget.courseItemModel.content;

        if (_content?.video != null) {
          return CourseHeaderVideo(courseItemModel: widget.courseItemModel);
        }

        if (_content?.html != null) {
          return CourseHeaderHtml();
        }

        return CourseHeaderBanner(courseItemModel: widget.courseItemModel);
      },
    );
  }
}
